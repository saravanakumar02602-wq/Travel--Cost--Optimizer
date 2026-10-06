from pathlib import Path
import math
import pandas as pd
from transport_engine import CITY_COUNTRIES, resolve_city_name


# ============================================================
# TRAVEL COST OPTIMIZER
# COST ENGINE
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data" / "processed"


# ------------------------------------------------------------
# LOAD DATASETS
# ------------------------------------------------------------

flights = pd.read_csv(
    DATA_DIR / "flights.csv",
    low_memory=False
)

hotels = pd.read_csv(
    DATA_DIR / "hotels.csv",
    low_memory=False
)

tourism = pd.read_csv(
    DATA_DIR / "tourism.csv",
    low_memory=False
)

food = pd.read_csv(
    DATA_DIR / "food.csv",
    low_memory=False
)

fuel = pd.read_csv(
    DATA_DIR / "fuel_prices.csv",
    low_memory=False
)


# ------------------------------------------------------------
# HAVERSINE DISTANCE
# ------------------------------------------------------------

def haversine_distance(lat1, lon1, lat2, lon2):
    """
    Calculate distance between two geographic coordinates.
    Returns distance in kilometres.
    """

    earth_radius = 6371.0

    lat1 = math.radians(lat1)
    lon1 = math.radians(lon1)

    lat2 = math.radians(lat2)
    lon2 = math.radians(lon2)

    dlat = lat2 - lat1
    dlon = lon2 - lon1

    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(lat1)
        * math.cos(lat2)
        * math.sin(dlon / 2) ** 2
    )

    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return earth_radius * c


# ------------------------------------------------------------
# DESTINATION SEARCH
# ------------------------------------------------------------

def find_destination(destination):
    """
    Find a tourism destination or build a city-level dataset fallback.
    """

    canonical_city = resolve_city_name(destination)
    destination = (canonical_city or destination).strip().lower()
    is_international = (
        canonical_city is not None
        and CITY_COUNTRIES[canonical_city] != "India"
    )

    matches = tourism.iloc[0:0] if is_international else tourism[
        tourism["destination"]
        .astype(str)
        .str.lower()
        .str.contains(destination, na=False, regex=False)
    ]

    if matches.empty:
        hotel_matches = hotels.iloc[0:0] if is_international else hotels[
            hotels["city"]
            .astype(str)
            .str.strip()
            .str.contains(destination, case=False, na=False, regex=False)
        ]
        hotel_prices = pd.to_numeric(
            hotel_matches["price"],
            errors="coerce"
        ).dropna()
        if hotel_prices.empty:
            hotel_prices = pd.to_numeric(
                hotels["price"],
                errors="coerce"
            ).dropna()

        food_matches = food.iloc[0:0] if is_international else food[
            food["city"]
            .astype(str)
            .str.strip()
            .str.contains(destination, case=False, na=False, regex=False)
        ]
        food_prices = pd.to_numeric(
            food_matches["prices"],
            errors="coerce"
        ).dropna()
        if food_prices.empty:
            food_prices = pd.to_numeric(
                food["prices"],
                errors="coerce"
            ).dropna()

        def tourism_median(column, fallback):
            values = pd.to_numeric(
                tourism[column],
                errors="coerce"
            ).dropna()
            return float(values.median()) if not values.empty else fallback

        if hotel_prices.empty or food_prices.empty:
            return None

        accommodation = float(hotel_prices.mean())
        daily_food = max(float(food_prices.median()) * 3, 300)
        daily_activities = tourism_median("mid_activities_min", 250)
        daily_transport = tourism_median("mid_transport_min", 200)

        level_factors = {
            "budget": (0.75, 0.85, 0.70, 0.85),
            "mid": (1.00, 1.00, 1.00, 1.00),
            "luxury": (1.80, 1.50, 1.60, 1.30)
        }
        fallback_row = {
            "destination": destination,
            "_hotel_source": (
                "india_dataset_benchmark"
                if is_international
                else "hotel_dataset_city_mean"
            ),
            "_food_source": (
                "india_dataset_benchmark"
                if is_international
                else "food_dataset_city_median_times_three"
            ),
            "_activity_source": (
                "india_dataset_benchmark"
                if is_international
                else "tourism_dataset_median"
            ),
            "_local_transport_source": (
                "india_dataset_benchmark"
                if is_international
                else "tourism_dataset_median"
            )
        }
        for level, factors in level_factors.items():
            hotel_factor, food_factor, activity_factor, transport_factor = factors
            fallback_row[f"{level}_accommodation_min"] = accommodation * hotel_factor
            fallback_row[f"{level}_food_min"] = daily_food * food_factor
            fallback_row[f"{level}_activities_min"] = daily_activities * activity_factor
            fallback_row[f"{level}_transport_min"] = daily_transport * transport_factor

        return pd.Series(fallback_row)

    return matches.iloc[0]


# ------------------------------------------------------------
# FLIGHT COST
# ------------------------------------------------------------

def calculate_flight_cost(
    origin,
    destination,
    travelers=1
):
    """
    Estimate flight cost using the flight dataset.
    """

    origin = origin.strip().lower()
    destination = destination.strip().lower()

    matches = flights[
        (flights["source"].astype(str).str.lower() == origin)
        &
        (flights["destination"].astype(str).str.lower() == destination)
    ]

    if matches.empty:
        return None

    average_price = matches["price"].mean()

    return {
        "mode": "Flight",
        "average_price_per_person": round(average_price, 2),
        "travelers": travelers,
        "total_cost": round(
            average_price * travelers,
            2
        ),
        "available_records": len(matches)
    }


# ------------------------------------------------------------
# HOTEL COST
# ------------------------------------------------------------

def calculate_hotel_cost(
    destination,
    days,
    travelers=1,
    accommodation_level="mid"
):
    """
    Calculate accommodation cost.

    Uses hotel dataset when the destination city
    is available.

    Otherwise uses tourism dataset ranges.
    """

    destination_row = find_destination(destination)

    if destination_row is None:
        return None

    destination_name = str(
        destination_row["destination"]
    )

    # --------------------------------------------------------
    # Try detailed hotel dataset
    # --------------------------------------------------------

    hotel_matches = hotels[
        hotels["city"]
        .astype(str)
        .str.lower()
        .str.contains(
            destination.lower(),
            na=False
        )
    ]

    if not hotel_matches.empty:

        average_hotel_price = hotel_matches[
            "price"
        ].mean()

        # Assume room for two people.
        rooms = math.ceil(
            travelers / 2
        )

        total = (
            average_hotel_price
            * rooms
            * days
        )

        return {
            "source": "hotel_dataset",
            "destination": destination_name,
            "rooms": rooms,
            "daily_room_cost": round(
                average_hotel_price,
                2
            ),
            "total_cost": round(
                total,
                2
            )
        }

    # --------------------------------------------------------
    # Tourism fallback
    # --------------------------------------------------------

    level = accommodation_level.lower()

    column = f"{level}_accommodation_min"

    if column not in tourism.columns:
        column = "mid_accommodation_min"

    daily_cost = float(
        destination_row[column]
    )

    total = daily_cost * days

    return {
        "source": "tourism_dataset",
        "destination": destination_name,
        "daily_room_cost": round(
            daily_cost,
            2
        ),
        "total_cost": round(
            total,
            2
        )
    }


# ------------------------------------------------------------
# FOOD COST
# ------------------------------------------------------------

def calculate_food_cost(
    destination,
    days,
    travelers=1
):
    """
    Estimate daily food cost using tourism
    dataset ranges.
    """

    destination_row = find_destination(destination)

    if destination_row is None:
        return None

    daily_food = float(
        destination_row["mid_food_min"]
    )

    total = (
        daily_food
        * days
        * travelers
    )

    return {
        "daily_food_per_person": round(
            daily_food,
            2
        ),
        "travelers": travelers,
        "days": days,
        "total_cost": round(
            total,
            2
        )
    }


# ------------------------------------------------------------
# LOCAL TRANSPORT COST
# ------------------------------------------------------------

def calculate_local_transport_cost(
    destination,
    days,
    travelers=1
):
    """
    Estimate local transportation cost.
    """

    destination_row = find_destination(destination)

    if destination_row is None:
        return None

    daily_transport = float(
        destination_row["mid_transport_min"]
    )

    total = (
        daily_transport
        * days
    )

    return {
        "daily_transport": round(
            daily_transport,
            2
        ),
        "days": days,
        "total_cost": round(
            total,
            2
        )
    }


# ------------------------------------------------------------
# ACTIVITY COST
# ------------------------------------------------------------

def calculate_activity_cost(
    destination,
    days,
    travelers=1
):
    """
    Estimate activity cost.
    """

    destination_row = find_destination(destination)

    if destination_row is None:
        return None

    daily_activity = float(
        destination_row["mid_activities_min"]
    )

    total = (
        daily_activity
        * days
        * travelers
    )

    return {
        "daily_activity_per_person": round(
            daily_activity,
            2
        ),
        "travelers": travelers,
        "days": days,
        "total_cost": round(
            total,
            2
        )
    }


# ------------------------------------------------------------
# COMPLETE TRIP COST
# ------------------------------------------------------------

def calculate_trip_cost(
    origin,
    destination,
    days,
    travelers=1
):
    """
    Calculate complete estimated trip cost.
    """

    flight = calculate_flight_cost(
        origin,
        destination,
        travelers
    )

    hotel = calculate_hotel_cost(
        destination,
        days,
        travelers
    )

    food_cost = calculate_food_cost(
        destination,
        days,
        travelers
    )

    local_transport = calculate_local_transport_cost(
        destination,
        days,
        travelers
    )

    activities = calculate_activity_cost(
        destination,
        days,
        travelers
    )

    flight_total = (
        flight["total_cost"]
        if flight else 0
    )

    hotel_total = (
        hotel["total_cost"]
        if hotel else 0
    )

    food_total = (
        food_cost["total_cost"]
        if food_cost else 0
    )

    transport_total = (
        local_transport["total_cost"]
        if local_transport else 0
    )

    activity_total = (
        activities["total_cost"]
        if activities else 0
    )

    subtotal = (
        flight_total
        + hotel_total
        + food_total
        + transport_total
        + activity_total
    )

    # 10% contingency / unexpected expense
    contingency = subtotal * 0.10

    total = subtotal + contingency

    return {
        "origin": origin,
        "destination": destination,
        "days": days,
        "travelers": travelers,
        "flight": flight,
        "hotel": hotel,
        "food": food_cost,
        "local_transport": local_transport,
        "activities": activities,
        "subtotal": round(subtotal, 2),
        "contingency": round(contingency, 2),
        "total_cost": round(total, 2),
        "cost_per_person": round(
            total / travelers,
            2
        )
    }


# ------------------------------------------------------------
# TEST
# ------------------------------------------------------------

if __name__ == "__main__":

    print("=" * 70)
    print("TRAVEL COST OPTIMIZER - COST ENGINE TEST")
    print("=" * 70)

    result = calculate_trip_cost(
        origin="Chennai",
        destination="Goa",
        days=5,
        travelers=2
    )

    print("\nTRIP COST RESULT")
    print("-" * 70)

    for key, value in result.items():
        print(f"{key:<20}: {value}")

    print("\n" + "=" * 70)
    print("COST ENGINE TEST COMPLETED")
    print("=" * 70)