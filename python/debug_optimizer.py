from pathlib import Path
import pandas as pd
import math

from transport_engine import compare_transport


# ==========================================================
# PATHS
# ==========================================================

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data" / "processed"

TOURISM_FILE = DATA_DIR / "tourism.csv"


# ==========================================================
# LOAD TOURISM
# ==========================================================

df = pd.read_csv(TOURISM_FILE)

print("=" * 70)
print("TRAVEL COST OPTIMIZER - DEBUG")
print("=" * 70)

print("\nTourism dataset:")
print("Rows   :", len(df))
print("Columns:", len(df.columns))


# ==========================================================
# FIND GOA
# ==========================================================

destination = "goa"

print("\n" + "=" * 70)
print("SEARCHING FOR DESTINATION: GOA")
print("=" * 70)

found = False

for column in [
    "destination",
    "name",
    "city",
    "place"
]:

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

        found = True

        print(
            f"\nFOUND GOA IN COLUMN: {column}"
        )

        row = df[mask].iloc[0]

        print(
            "\nDestination value:",
            row[column]
        )

        print(
            "\nImportant cost columns:"
        )

        for col in df.columns:

            if any(
                word in col.lower()
                for word in [
                    "accommodation",
                    "food",
                    "activities",
                    "transport"
                ]
            ):

                print(
                    f"  {col}: {row[col]}"
                )

        break


if not found:

    print(
        "\nERROR: Goa was NOT found "
        "in destination/name/city/place columns."
    )


# ==========================================================
# TRANSPORT
# ==========================================================

print("\n" + "=" * 70)
print("TRANSPORT OPTIONS")
print("=" * 70)

try:

    transport = compare_transport(
        "Chennai",
        "Goa",
        2
    )

    print("\nRaw transport result:")
    print(transport)

except Exception as e:

    print(
        "\nTRANSPORT ERROR:",
        e
    )
    transport = {}


# ==========================================================
# NORMALIZE TRANSPORT
# ==========================================================

if isinstance(
    transport,
    dict
):

    transport_list = []

    for mode, option in transport.items():

        if isinstance(
            option,
            dict
        ):

            item = option.copy()

            item["mode"] = mode

            transport_list.append(
                item
            )

else:

    transport_list = transport


print("\nNormalized transport:")

for option in transport_list:

    print(
        "\nMode:",
        option.get("mode")
    )

    print(
        "Cost:",
        option.get("cost")
    )

    print(
        "Distance:",
        option.get("distance_km")
    )

    print(
        "Time:",
        option.get("time_hours")
    )


# ==========================================================
# CALCULATE DESTINATION COSTS
# ==========================================================

print("\n" + "=" * 70)
print("DESTINATION COST CALCULATION")
print("=" * 70)

if found:

    travelers = 2
    days = 5
    budget = 25000

    for level in [
        "budget",
        "mid",
        "luxury"
    ]:

        print(
            f"\n--- {level.upper()} ---"
        )

        try:

            accommodation = float(
                row[
                    f"{level}_accommodation_min"
                ]
            )

            food = float(
                row[
                    f"{level}_food_min"
                ]
            )

            activities = float(
                row[
                    f"{level}_activities_min"
                ]
            )

            transport_cost = float(
                row[
                    f"{level}_transport_min"
                ]
            )

            rooms = math.ceil(
                travelers / 2
            )

            hotel = (
                accommodation
                * days
                * rooms
            )

            food_total = (
                food
                * days
                * travelers
            )

            activity_total = (
                activities
                * days
                * travelers
            )

            local_transport = (
                transport_cost
                * days
                * travelers
            )

            print(
                "Accommodation/day:",
                accommodation
            )

            print(
                "Food/person/day:",
                food
            )

            print(
                "Activities/person/day:",
                activities
            )

            print(
                "Transport/person/day:",
                transport_cost
            )

            print(
                "Hotel total:",
                hotel
            )

            print(
                "Food total:",
                food_total
            )

            print(
                "Activities total:",
                activity_total
            )

            print(
                "Local transport total:",
                local_transport
            )

            print(
                "Destination subtotal:",
                hotel
                + food_total
                + activity_total
                + local_transport
            )

        except Exception as e:

            print(
                "ERROR:",
                e
            )


# ==========================================================
# TEST COMPLETE PLAN
# ==========================================================

print("\n" + "=" * 70)
print("COMPLETE PLAN TEST")
print("=" * 70)

if found and transport_list:

    for option in transport_list:

        try:

            mode = option.get(
                "mode"
            )

            transport_cost = float(
                option.get(
                    "cost",
                    0
                )
            )

            print(
                f"\nTransport: {mode}"
            )

            print(
                f"Transport cost: ₹{transport_cost:,.2f}"
            )

            level = "budget"

            accommodation = float(
                row[
                    f"{level}_accommodation_min"
                ]
            )

            food = float(
                row[
                    f"{level}_food_min"
                ]
            )

            activities = float(
                row[
                    f"{level}_activities_min"
                ]
            )

            local = float(
                row[
                    f"{level}_transport_min"
                ]
            )

            hotel = (
                accommodation
                * 5
                * 1
            )

            food_total = (
                food
                * 5
                * 2
            )

            activity_total = (
                activities
                * 5
                * 2
            )

            local_total = (
                local
                * 5
                * 2
            )

            subtotal = (
                transport_cost
                + hotel
                + food_total
                + activity_total
                + local_total
            )

            contingency = (
                subtotal * 0.10
            )

            total = (
                subtotal
                + contingency
            )

            print(
                f"Hotel: ₹{hotel:,.2f}"
            )

            print(
                f"Food: ₹{food_total:,.2f}"
            )

            print(
                f"Activities: ₹{activity_total:,.2f}"
            )

            print(
                f"Local transport: ₹{local_total:,.2f}"
            )

            print(
                f"Subtotal: ₹{subtotal:,.2f}"
            )

            print(
                f"Contingency: ₹{contingency:,.2f}"
            )

            print(
                f"TOTAL: ₹{total:,.2f}"
            )

            print(
                f"BUDGET: ₹{budget:,.2f}"
            )

            if total <= budget:

                print(
                    "RESULT: ✓ WITHIN BUDGET"
                )

            else:

                print(
                    "RESULT: ✗ OVER BUDGET"
                )

        except Exception as e:

            print(
                "PLAN ERROR:",
                e
            )


print("\n" + "=" * 70)
print("DEBUG COMPLETED")
print("=" * 70)