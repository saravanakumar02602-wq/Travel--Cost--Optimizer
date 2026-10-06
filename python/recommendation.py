from pathlib import Path
import sys

# ============================================================
# TRAVEL COST OPTIMIZER
# RECOMMENDATION ENGINE
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

sys.path.insert(0, str(BASE_DIR / "python"))

from scenario_engine import compare_scenarios


# ------------------------------------------------------------
# RECOMMENDATION ENGINE
# ------------------------------------------------------------

def generate_recommendation(
    origin,
    destination,
    days,
    travelers,
    budget,
    preference="balanced"
):

    scenarios = compare_scenarios(
        origin=origin,
        destination=destination,
        days=days,
        travelers=travelers,
        budget=budget
    )

    if not scenarios:
        return None

    # --------------------------------------------------------
    # Keep only scenarios within budget
    # --------------------------------------------------------

    feasible = [
        scenario
        for scenario in scenarios
        if scenario["budget_status"] == "Within Budget"
    ]

    if not feasible:
        return {
            "status": "No feasible plan",
            "message": (
                "All available scenarios exceed the "
                "user's budget."
            ),
            "scenarios": scenarios
        }

    # --------------------------------------------------------
    # Preference-based recommendation
    # --------------------------------------------------------

    preference = preference.lower().strip()

    if preference == "budget":

        selected = min(
            feasible,
            key=lambda x: x["total_cost"]
        )

    elif preference == "comfort":

        selected = max(
            feasible,
            key=lambda x: x["total_cost"]
        )

    elif preference == "balanced":

        # Choose the plan closest to 80% of budget.
        target = budget * 0.80

        selected = min(
            feasible,
            key=lambda x: abs(
                x["total_cost"] - target
            )
        )

    else:

        selected = min(
            feasible,
            key=lambda x: x["total_cost"]
        )

    # --------------------------------------------------------
    # Savings
    # --------------------------------------------------------

    savings = budget - selected["total_cost"]

    budget_usage = (
        selected["total_cost"]
        / budget
    ) * 100

    # --------------------------------------------------------
    # Recommendation message
    # --------------------------------------------------------

    if preference == "budget":

        message = (
            "This plan focuses on minimizing total "
            "travel expenditure while remaining within budget."
        )

    elif preference == "comfort":

        message = (
            "This plan uses more of the available budget "
            "to provide a higher-comfort travel experience."
        )

    else:

        message = (
            "This plan provides a balance between "
            "overall trip cost and available budget."
        )

    return {
        "status": "Recommendation generated",
        "recommended_scenario": selected["scenario"],
        "total_cost": selected["total_cost"],
        "cost_per_person": selected["cost_per_person"],
        "budget": budget,
        "remaining_budget": round(savings, 2),
        "budget_usage_percent": round(
            budget_usage,
            2
        ),
        "budget_status": selected["budget_status"],
        "message": message,
        "all_scenarios": scenarios
    }


# ------------------------------------------------------------
# TEST
# ------------------------------------------------------------

if __name__ == "__main__":

    print("=" * 70)
    print("TRAVEL COST OPTIMIZER - RECOMMENDATION ENGINE")
    print("=" * 70)

    origin = "Chennai"
    destination = "Goa"
    days = 5
    travelers = 2
    budget = 50000
    preference = "balanced"

    print("\nUSER REQUIREMENTS")
    print("-" * 70)
    print(f"Origin       : {origin}")
    print(f"Destination  : {destination}")
    print(f"Days         : {days}")
    print(f"Travelers    : {travelers}")
    print(f"Budget       : ₹{budget:,.2f}")
    print(f"Preference   : {preference}")

    result = generate_recommendation(
        origin=origin,
        destination=destination,
        days=days,
        travelers=travelers,
        budget=budget,
        preference=preference
    )

    print("\n" + "=" * 70)
    print("PERSONALIZED TRAVEL RECOMMENDATION")
    print("=" * 70)

    if result is None:

        print("Unable to generate recommendation.")

    else:

        print(
            f"\nStatus                 : {result['status']}"
        )

        if "recommended_scenario" in result:

            print(
                f"Recommended Scenario  : "
                f"{result['recommended_scenario']}"
            )

            print(
                f"Total Trip Cost       : "
                f"₹{result['total_cost']:,.2f}"
            )

            print(
                f"Cost Per Person       : "
                f"₹{result['cost_per_person']:,.2f}"
            )

            print(
                f"Budget                : "
                f"₹{result['budget']:,.2f}"
            )

            print(
                f"Remaining Budget      : "
                f"₹{result['remaining_budget']:,.2f}"
            )

            print(
                f"Budget Usage          : "
                f"{result['budget_usage_percent']:.2f}%"
            )

            print(
                f"Budget Status         : "
                f"{result['budget_status']}"
            )

            print(
                f"\nRecommendation:"
            )

            print(
                result["message"]
            )

        else:

            print(
                f"\n{result['message']}"
            )

    print("\n" + "=" * 70)
    print("RECOMMENDATION ENGINE TEST COMPLETED")
    print("=" * 70)