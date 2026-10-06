import sys

from optimizer import get_destination_costs
from transport_engine import compare_transport


# ------------------------------------------------------------
# SCENARIO DEFINITIONS
# ------------------------------------------------------------

SCENARIOS = {
    "Budget": {
        "accommodation_level": "budget",
        "description": "Lower-cost travel plan"
    },

    "Balanced": {
        "accommodation_level": "mid",
        "description": "Balanced cost and comfort"
    },

    "Comfort": {
        "accommodation_level": "mid",
        "description": "Higher comfort with additional spending"
    },

    "Luxury": {
        "accommodation_level": "luxury",
        "description": "Premium travel experience"
    }
}


# ------------------------------------------------------------
# CALCULATE SCENARIO
# ------------------------------------------------------------

def calculate_scenario(
    origin,
    destination,
    days,
    travelers,
    budget,
    scenario_name,
    transport_mode=None,
    transport_cost=None
):

    if scenario_name not in SCENARIOS:
        raise ValueError(
            f"Unknown scenario: {scenario_name}"
        )

    scenario = SCENARIOS[scenario_name]
    level = scenario["accommodation_level"]
    costs = get_destination_costs(destination, days, travelers, level)
    if costs is None:
        raise ValueError(f"No cost estimate is available for {destination}.")

    hotel_cost = round(float(costs["hotel_cost"]), 2)
    food_cost = round(float(costs["food_cost"]), 2)
    activities = round(float(costs["activity_cost"]), 2)
    local_transport = round(float(costs["local_transport_cost"]), 2)

    # Comfort is modeled as an upgrade over the mid-range destination rates.
    if scenario_name == "Comfort":
        hotel_cost *= 1.25
        food_cost *= 1.15
        activities *= 1.20
        local_transport *= 1.10

    if transport_mode is not None or transport_cost is not None:
        if transport_mode is None or transport_cost is None:
            raise ValueError(
                "A reference transport mode and cost must be provided together."
            )
        selected_transport_mode = transport_mode
        selected_transport_cost = float(transport_cost)
    else:
        transport_options = compare_transport(origin, destination, travelers)["options"]
        if transport_options:
            selected_transport = min(
                transport_options,
                key=lambda option: float(option["cost"])
            )
            selected_transport_mode = selected_transport["mode"]
            selected_transport_cost = float(selected_transport["cost"])
        else:
            selected_transport_mode = None
            selected_transport_cost = 0.0

    # --------------------------------------------------------
    # Recalculate subtotal
    # --------------------------------------------------------

    subtotal = (
        selected_transport_cost
        + hotel_cost
        + food_cost
        + local_transport
        + activities
    )

    # --------------------------------------------------------
    # Contingency
    # --------------------------------------------------------

    subtotal = round(subtotal, 2)
    contingency = round(subtotal * 0.10, 2)

    total_cost = round(subtotal + contingency, 2)

    remaining_budget = round(budget - total_cost, 2)

    budget_status = (
        "Within Budget"
        if total_cost <= budget
        else "Over Budget"
    )

    return {
        "scenario": scenario_name,
        "description": scenario["description"],
        "transport_mode": selected_transport_mode,
        "transport_cost": round(selected_transport_cost, 2),
        "hotel_cost": round(hotel_cost, 2),
        "food_cost": round(food_cost, 2),
        "local_transport": round(local_transport, 2),
        "activities": round(activities, 2),
        "contingency": round(contingency, 2),
        "total_cost": round(total_cost, 2),
        "budget": round(budget, 2),
        "remaining_budget": round(remaining_budget, 2),
        "cost_per_person": round(
            round(total_cost / travelers, 2),
            2
        ),
        "budget_status": budget_status
    }


# ------------------------------------------------------------
# COMPARE ALL SCENARIOS
# ------------------------------------------------------------

def compare_scenarios(
    origin,
    destination,
    days,
    travelers,
    budget,
    transport_mode=None,
    transport_cost=None
):

    results = []

    for scenario_name in SCENARIOS:

        result = calculate_scenario(
            origin=origin,
            destination=destination,
            days=days,
            travelers=travelers,
            budget=budget,
            scenario_name=scenario_name,
            transport_mode=transport_mode,
            transport_cost=transport_cost
        )

        results.append(result)

    return results


# ------------------------------------------------------------
# TEST
# ------------------------------------------------------------

if __name__ == "__main__":

    print("=" * 70)
    print("TRAVEL COST OPTIMIZER - SCENARIO ENGINE")
    print("=" * 70)

    origin = "Chennai"
    destination = "Goa"
    days = 5
    travelers = 2
    budget = 50000

    print("\nUSER REQUIREMENTS")
    print("-" * 70)
    print(f"Origin       : {origin}")
    print(f"Destination  : {destination}")
    print(f"Days         : {days}")
    print(f"Travelers    : {travelers}")
    print(f"Budget       : ₹{budget:,.2f}")

    results = compare_scenarios(
        origin=origin,
        destination=destination,
        days=days,
        travelers=travelers,
        budget=budget
    )

    print("\n" + "=" * 70)
    print("TRAVEL SCENARIO COMPARISON")
    print("=" * 70)

    for result in results:

        print(f"\n{result['scenario'].upper()}")
        print("-" * 70)

        print(
            f"Transport Cost       : ₹{result['transport_cost']:,.2f}"
        )

        print(
            f"Hotel Cost           : ₹{result['hotel_cost']:,.2f}"
        )

        print(
            f"Food Cost            : ₹{result['food_cost']:,.2f}"
        )

        print(
            f"Local Transport      : ₹{result['local_transport']:,.2f}"
        )

        print(
            f"Activities           : ₹{result['activities']:,.2f}"
        )

        print(
            f"Contingency          : ₹{result['contingency']:,.2f}"
        )

        print("-" * 70)

        print(
            f"TOTAL COST           : ₹{result['total_cost']:,.2f}"
        )

        print(
            f"Cost Per Person      : ₹{result['cost_per_person']:,.2f}"
        )

        print(
            f"Remaining Budget     : ₹{result['remaining_budget']:,.2f}"
        )

        print(
            f"Budget Status        : {result['budget_status']}"
        )

    print("\n" + "=" * 70)
    print("SCENARIO ENGINE TEST COMPLETED")
    print("=" * 70)