from pathlib import Path
import math
import pandas as pd

from transport_engine import compare_transport
from cost_engine import find_destination as find_city_destination


# ==========================================================
# PATHS
# ==========================================================

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data" / "processed"

TOURISM_FILE = DATA_DIR / "tourism.csv"


# ==========================================================
# LOAD DATA
# ==========================================================

def load_tourism():
    return pd.read_csv(TOURISM_FILE)


# ==========================================================
# FIND DESTINATION
# ==========================================================

def find_destination(destination):

    df = load_tourism()

    destination = str(destination).strip().lower()

    possible_columns = [
        "destination",
        "name",
        "city",
        "place"
    ]

    for column in possible_columns:

        if column not in df.columns:
            continue

        mask = (
            df[column]
            .astype(str)
            .str.lower()
            .str.contains(
                destination,
                na=False
            )
        )

        if mask.any():
            return df[mask].iloc[0]

    return find_city_destination(destination)


# ==========================================================
# SAFE NUMERIC VALUE
# ==========================================================

def get_value(row, column, default=0):

    try:

        value = row[column]

        if pd.isna(value):
            return float(default)

        return float(value)

    except Exception:

        return float(default)


# ==========================================================
# DESTINATION COST
# ==========================================================

def get_destination_costs(
    destination,
    days,
    travelers,
    level="mid"
):

    row = find_destination(destination)

    if row is None:
        return None

    accommodation = get_value(
        row,
        f"{level}_accommodation_min"
    )

    food = get_value(
        row,
        f"{level}_food_min"
    )

    activities = get_value(
        row,
        f"{level}_activities_min"
    )

    transport = get_value(
        row,
        f"{level}_transport_min"
    )

    # ------------------------------------------------------
    # Number of hotel rooms
    # ------------------------------------------------------

    rooms = math.ceil(
        travelers / 2
    )

    # ------------------------------------------------------
    # Hotel
    # ------------------------------------------------------

    hotel_cost = (
        accommodation
        * days
        * rooms
    )

    # ------------------------------------------------------
    # Food
    # ------------------------------------------------------

    food_cost = (
        food
        * days
        * travelers
    )

    # ------------------------------------------------------
    # Activities
    # ------------------------------------------------------

    activity_cost = (
        activities
        * days
        * travelers
    )

    # ------------------------------------------------------
    # Local transport
    # ------------------------------------------------------

    local_transport_cost = (
        transport
        * days
        * travelers
    )

    return {

        "hotel_cost":
            hotel_cost,

        "food_cost":
            food_cost,

        "activity_cost":
            activity_cost,

        "local_transport_cost":
            local_transport_cost,

        "hotel_source": row.get("_hotel_source", "tourism_dataset"),
        "food_source": row.get("_food_source", "tourism_dataset"),
        "activity_source": row.get("_activity_source", "tourism_dataset"),
        "local_transport_source": row.get("_local_transport_source", "tourism_dataset")
    }


# ==========================================================
# COMFORT SCORE
# ==========================================================

def calculate_comfort_score(mode):

    scores = {

        "Flight": 0.90,

        "Train": 0.75,

        "Bus": 0.55,

        "Car": 0.85
    }

    return scores.get(
        mode,
        0.50
    )


# ==========================================================
# TIME SCORE
# ==========================================================

def calculate_time_score(time_hours):

    if time_hours is None:
        return 0.50

    try:
        time_hours = float(time_hours)

    except Exception:
        return 0.50

    if time_hours <= 3:
        return 1.00

    if time_hours <= 6:
        return 0.90

    if time_hours <= 10:
        return 0.75

    if time_hours <= 15:
        return 0.60

    if time_hours <= 20:
        return 0.45

    return 0.30


# ==========================================================
# COST SCORE
# ==========================================================

def calculate_cost_score(
    transport_cost,
    all_transport_costs
):

    if not all_transport_costs:
        return 0.50

    minimum_cost = min(
        all_transport_costs
    )

    maximum_cost = max(
        all_transport_costs
    )

    if maximum_cost == minimum_cost:
        return 1.00

    score = (
        maximum_cost
        - transport_cost
    ) / (
        maximum_cost
        - minimum_cost
    )

    return max(
        0.0,
        min(1.0, score)
    )


# ==========================================================
# TRANSPORT SCORE
# ==========================================================

def calculate_transport_score(
    mode,
    transport_cost,
    time_hours,
    all_transport_costs,
    preference="balanced"
):

    cost_score = calculate_cost_score(
        transport_cost,
        all_transport_costs
    )

    time_score = calculate_time_score(
        time_hours
    )

    comfort_score = calculate_comfort_score(
        mode
    )

    weights = {

        "budget": {
            "cost": 0.70,
            "time": 0.20,
            "comfort": 0.10
        },

        "balanced": {
            "cost": 0.50,
            "time": 0.30,
            "comfort": 0.20
        },

        "comfort": {
            "cost": 0.30,
            "time": 0.40,
            "comfort": 0.30
        },

        "luxury": {
            "cost": 0.20,
            "time": 0.40,
            "comfort": 0.40
        }
    }

    selected = weights.get(
        str(preference).lower(),
        weights["balanced"]
    )

    final_score = (

        cost_score
        * selected["cost"]

        +

        time_score
        * selected["time"]

        +

        comfort_score
        * selected["comfort"]
    )

    return {

        "cost_score":
            round(cost_score, 4),

        "time_score":
            round(time_score, 4),

        "comfort_score":
            round(comfort_score, 4),

        "final_score":
            round(final_score, 4)
    }


# ==========================================================
# NORMALIZE TRANSPORT OPTIONS
# ==========================================================

def normalize_transport_options(transport_result):
    if not isinstance(transport_result, dict):
        return []

    options = transport_result.get("options", [])

    if not isinstance(options, list):
        return []

    normalized = []

    for option in options:
        if not isinstance(option, dict):
            continue

        item = option.copy()

        item["mode"] = item.get("mode", "Unknown")
        item["cost"] = float(item.get("cost", 0) or 0)

        item["distance_km"] = float(
            item.get("distance_km", 0)
            or transport_result.get("distance_km", 0)
            or 0
        )

        estimated_time = item.get("estimated_time_hours")
        item["time_hours"] = (
            float(estimated_time)
            if estimated_time is not None
            else None
        )

        normalized.append(item)

    return normalized


# ==========================================================
# OPTIMIZE TRIP
# ==========================================================

def optimize_trip(
    origin,
    destination,
    days,
    travelers,
    budget,
    preference="balanced",
    accommodation_level=None
):

    # ------------------------------------------------------
    # Transport
    # ------------------------------------------------------

    raw_transport_options = compare_transport(
        origin,
        destination,
        travelers
    )

    transport_options = normalize_transport_options(
        raw_transport_options
    )

    if not transport_options:
        return []

    # ------------------------------------------------------
    # Transport costs
    # ------------------------------------------------------

    all_transport_costs = []

    for option in transport_options:

        try:

            cost = float(
                option.get("cost", 0)
            )

            if cost > 0:
                all_transport_costs.append(cost)

        except Exception:
            continue

    if not all_transport_costs:
        return []

    # ------------------------------------------------------
    # Accommodation levels
    # ------------------------------------------------------

    valid_levels = ["budget", "mid", "luxury"]
    if accommodation_level is not None:
        accommodation_level = accommodation_level.lower()
        if accommodation_level not in valid_levels:
            raise ValueError(
                "Accommodation level must be budget, mid, or luxury."
            )
        levels = [accommodation_level]
    else:
        levels = valid_levels

    plans = []

    # ======================================================
    # TRANSPORT OPTIONS
    # ======================================================

    for transport in transport_options:

        mode = transport.get(
            "mode",
            "Unknown"
        )

        try:

            transport_cost = float(
                transport.get(
                    "cost",
                    0
                )
            )

        except Exception:

            continue

        try:

            distance_km = float(
                transport.get(
                    "distance_km",
                    0
                )
            )

        except Exception:

            distance_km = 0

        try:

            time_hours = float(
                transport.get(
                    "time_hours"
                )
            )

        except Exception:

            time_hours = None

        # --------------------------------------------------
        # Transport score
        # --------------------------------------------------

        transport_score = calculate_transport_score(

            mode,

            transport_cost,

            time_hours,

            all_transport_costs,

            preference
        )

        # ==================================================
        # DESTINATION LEVELS
        # ==================================================

        for level in levels:

            costs = get_destination_costs(

                destination,

                days,

                travelers,

                level
            )

            if costs is None:
                continue

            hotel_cost = round(float(costs["hotel_cost"]), 2)
            food_cost = round(float(costs["food_cost"]), 2)
            activity_cost = round(float(costs["activity_cost"]), 2)
            local_transport_cost = round(
                float(costs["local_transport_cost"]),
                2
            )

            # ------------------------------------------------
            # Subtotal
            # ------------------------------------------------

            subtotal = (

                transport_cost

                + hotel_cost

                + food_cost

                + activity_cost

                + local_transport_cost
            )

            # ------------------------------------------------
            # Contingency
            # ------------------------------------------------

            subtotal = round(subtotal, 2)
            contingency = round(subtotal * 0.10, 2)

            # ------------------------------------------------
            # Total
            # ------------------------------------------------

            total_cost = round(subtotal + contingency, 2)

            # ------------------------------------------------
            # Budget constraint
            # ------------------------------------------------

            if total_cost > budget:
                continue

            # ------------------------------------------------
            # Per person
            # ------------------------------------------------

            cost_per_person = round(total_cost / travelers, 2)

            # ------------------------------------------------
            # Remaining budget
            # ------------------------------------------------

            remaining_budget = round(budget - total_cost, 2)

            # ------------------------------------------------
            # Budget efficiency
            # ------------------------------------------------

            budget_efficiency = (

                remaining_budget
                / budget
            )

            budget_efficiency = max(
                0.0,
                min(
                    1.0,
                    budget_efficiency
                )
            )

            # ------------------------------------------------
            # Overall score
            # ------------------------------------------------

            overall_score = (

                transport_score[
                    "final_score"
                ]
                * 0.70

                +

                budget_efficiency
                * 0.30
            )

            plans.append({

                "transport_mode":
                    mode,

                "transport_cost":
                    round(
                        transport_cost,
                        2
                    ),

                "distance_km":
                    round(
                        distance_km,
                        2
                    ),

                "travel_time_hours":
                    (
                        round(
                            time_hours,
                            2
                        )
                        if time_hours
                        is not None
                        else None
                    ),

                "cost_score":
                    transport_score[
                        "cost_score"
                    ],

                "time_score":
                    transport_score[
                        "time_score"
                    ],

                "comfort_score":
                    transport_score[
                        "comfort_score"
                    ],

                "transport_score":
                    transport_score[
                        "final_score"
                    ],

                "hotel_cost":
                    round(
                        hotel_cost,
                        2
                    ),

                "food_cost":
                    round(
                        food_cost,
                        2
                    ),

                "activity_cost":
                    round(
                        activity_cost,
                        2
                    ),

                "local_transport_cost":
                    round(
                        local_transport_cost,
                        2
                    ),

                "cost_sources":
                    costs.get("cost_sources", {
                        "hotel": costs.get("hotel_source", "tourism_dataset"),
                        "food": costs.get("food_source", "tourism_dataset"),
                        "activities": costs.get("activity_source", "tourism_dataset"),
                        "local_transport": costs.get("local_transport_source", "tourism_dataset")
                    }),

                "contingency":
                    round(
                        contingency,
                        2
                    ),

                "total_cost":
                    round(
                        total_cost,
                        2
                    ),

                "cost_per_person":
                    round(
                        cost_per_person,
                        2
                    ),

                "budget":
                    round(
                        budget,
                        2
                    ),

                "remaining_budget":
                    round(
                        remaining_budget,
                        2
                    ),

                "budget_status":
                    "Within Budget",

                "accommodation_level":
                    level,

                "food_level":
                    level,

                "activity_level":
                    level,

                "local_transport_level":
                    level,

                "preference":
                    preference,

                "score":
                    round(
                        overall_score,
                        4
                    ),

                "status":
                    "success"
            })

    # ======================================================
    # SORT
    # ======================================================

    plans.sort(
        key=lambda x: x["score"],
        reverse=True
    )

    return plans


# ==========================================================
# BEST PLAN
# ==========================================================

def recommend_best_plan(
    origin,
    destination,
    days,
    travelers,
    budget,
    preference="balanced"
):

    plans = optimize_trip(

        origin,
        destination,
        days,
        travelers,
        budget,
        preference
    )

    if not plans:

        return {

            "status":
                "no_feasible_plan",

            "message":
                "No feasible travel plan was found within the selected budget."
        }

    best = plans[0]

    best["message"] = (

        f"A {best['transport_mode']} plan "
        f"was selected using multi-objective "
        f"optimization."
    )

    return best


# ==========================================================
# TEST
# ==========================================================

if __name__ == "__main__":

    print("=" * 70)

    print(
        "TRAVEL COST OPTIMIZER - "
        "MULTI-OBJECTIVE TEST"
    )

    print("=" * 70)

    result = recommend_best_plan(

        origin="Chennai",

        destination="Goa",

        days=5,

        travelers=2,

        budget=25000,

        preference="balanced"
    )

    print("\nBEST PLAN\n")

    for key, value in result.items():

        print(
            f"{key:25}: {value}"
        )

    print("\n" + "=" * 70)