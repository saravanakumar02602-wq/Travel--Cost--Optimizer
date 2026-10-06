import argparse
import json

from optimizer import get_destination_costs, optimize_trip
from scenario_engine import compare_scenarios
from transport_engine import (
    CITY_COORDINATES,
    CITY_COUNTRIES,
    compare_transport,
    resolve_city_name,
)


class JsonArgumentParser(argparse.ArgumentParser):
    def error(self, message):
        raise ValueError(message)


def main():
    parser = JsonArgumentParser(description="Optimize a trip and compare scenarios.")
    parser.add_argument("--origin", required=True)
    parser.add_argument("--destination", required=True)
    parser.add_argument("--days", required=True, type=int)
    parser.add_argument("--travelers", required=True, type=int)
    parser.add_argument("--budget", required=True, type=float)
    parser.add_argument("--preference", default="balanced")
    parser.add_argument(
        "--accommodation",
        choices=("automatic", "budget", "mid", "luxury"),
        default="automatic"
    )

    try:
        args = parser.parse_args()

        if args.days < 1:
            raise ValueError("Days must be at least 1.")
        if args.travelers < 1:
            raise ValueError("Travelers must be at least 1.")
        if args.budget <= 0:
            raise ValueError("Budget must be greater than 0.")
        if args.origin.strip().lower() == args.destination.strip().lower():
            raise ValueError("Origin and destination must be different cities.")

        origin = resolve_city_name(args.origin)
        destination = resolve_city_name(args.destination)

        if origin is None:
            raise ValueError(
                f"Unsupported origin city: {args.origin}. "
                "Try a supported city such as Chennai, Dubai, Singapore, London, "
                "Tokyo, New York, Toronto, or Sydney."
            )
        if destination is None:
            raise ValueError(
                f"Unsupported destination city: {args.destination}. "
                "Try a supported city such as Chennai, Dubai, Singapore, London, "
                "Tokyo, New York, Toronto, or Sydney."
            )

        preference = args.preference.strip().lower()
        if preference not in {"budget", "balanced", "comfort", "luxury"}:
            raise ValueError(
                "Preference must be budget, balanced, comfort, or luxury."
            )

        accommodation_level = (
            None if args.accommodation == "automatic"
            else args.accommodation
        )

        transport_result = compare_transport(
            origin,
            destination,
            args.travelers
        )
        route_coordinates = {
            "origin": {
                "latitude": CITY_COORDINATES[origin][0],
                "longitude": CITY_COORDINATES[origin][1]
            },
            "destination": {
                "latitude": CITY_COORDINATES[destination][0],
                "longitude": CITY_COORDINATES[destination][1]
            }
        }
        transport_options = []
        for option in transport_result["options"]:
            distance = option.get("distance_km")
            transport_options.append({
                "mode": option.get("mode", "Unknown"),
                "cost": float(option.get("cost", 0) or 0),
                "distance_km": (
                    float(distance)
                    if distance is not None
                    else transport_result.get("distance_km")
                ),
                "time_hours": option.get("estimated_time_hours"),
                "fuel_price_per_litre": option.get("fuel_price_per_litre"),
                "fuel_price_source": option.get("fuel_price_source"),
                "cost_source": option.get("cost_source"),
                "mileage_km_per_litre": option.get("mileage_km_per_litre"),
                "toll_cost": option.get("toll_cost")
            })

        international_estimate_note = None
        if (
            CITY_COUNTRIES[origin] != "India"
            or CITY_COUNTRIES[destination] != "India"
        ):
            international_estimate_note = (
                "International trip estimate in INR: transport fares without a "
                "matching route record use distance-based estimates. Hotel, "
                "food, activities, and local transport use Indian dataset "
                "benchmarks because destination-country price data is not "
                "included; treat these as rough planning estimates, not local quotes."
            )

        result = optimize_trip(
            origin=origin,
            destination=destination,
            days=args.days,
            travelers=args.travelers,
            budget=args.budget,
            preference=preference,
            accommodation_level=accommodation_level
        )

        if isinstance(result, list) and result:
            result = result[0]

        if not result:
            estimate_level = accommodation_level or "budget"
            estimate_costs = get_destination_costs(
                destination,
                args.days,
                args.travelers,
                estimate_level
            )
            if estimate_costs is None:
                raise ValueError(
                    f"No destination cost estimate is available for {destination}."
                )

            non_transport_cost = sum(
                float(estimate_costs[field] or 0)
                for field in (
                    "hotel_cost",
                    "food_cost",
                    "activity_cost",
                    "local_transport_cost"
                )
            )
            for option in transport_options:
                subtotal = round(float(option["cost"]) + non_transport_cost, 2)
                estimated_total = round(subtotal + round(subtotal * 0.10, 2), 2)
                option["estimated_total"] = estimated_total
                option["within_budget"] = estimated_total <= args.budget

            minimum_required_budget = min(
                option["estimated_total"]
                for option in transport_options
            )
            reference_option = min(
                transport_options,
                key=lambda option: option["cost"]
            )
            scenarios = compare_scenarios(
                origin=origin,
                destination=destination,
                days=args.days,
                travelers=args.travelers,
                budget=args.budget,
                transport_mode=reference_option["mode"],
                transport_cost=reference_option["cost"]
            )
            print(json.dumps({
                "status": "no_feasible_plan",
                "message": "No feasible travel plan found within the selected budget.",
                "origin": origin,
                "destination": destination,
                "origin_country": CITY_COUNTRIES[origin],
                "destination_country": CITY_COUNTRIES[destination],
                "days": args.days,
                "travelers": args.travelers,
                "budget": args.budget,
                "preference": preference,
                "cost_estimate_note": international_estimate_note,
                "minimum_required_budget": round(minimum_required_budget, 2),
                "distance_km": transport_result.get("distance_km"),
                "route_coordinates": route_coordinates,
                "transport_options": transport_options,
                "scenarios": scenarios
            }))
            return

        if result.get("status") != "success":
            print(json.dumps(result))
            return

        for option in transport_options:
            transport_cost = option["cost"]
            subtotal = transport_cost + sum(
                float(result.get(field, 0) or 0)
                for field in (
                    "hotel_cost",
                    "food_cost",
                    "activity_cost",
                    "local_transport_cost"
                )
            )
            subtotal = round(subtotal, 2)
            estimated_total = round(subtotal + round(subtotal * 0.10, 2), 2)
            option["estimated_total"] = estimated_total
            option["within_budget"] = estimated_total <= args.budget

        scenarios = compare_scenarios(
            origin=origin,
            destination=destination,
            days=args.days,
            travelers=args.travelers,
            budget=args.budget,
            transport_mode=result.get("transport_mode"),
            transport_cost=result.get("transport_cost", 0)
        )

        output = {
            "status": "success",

            "origin": origin,
            "destination": destination,
            "origin_country": CITY_COUNTRIES[origin],
            "destination_country": CITY_COUNTRIES[destination],
            "days": args.days,
            "travelers": args.travelers,
            "budget": args.budget,
            "preference": preference,
            "route_coordinates": route_coordinates,
            "cost_estimate_note": international_estimate_note,

            "transport_mode":
                result.get("transport_mode"),

            "transport_cost":
                result.get("transport_cost", 0),

            "distance_km":
                result.get("distance_km", 0),

            "travel_time_hours":
                result.get("travel_time_hours", 0),

            "cost_score":
                result.get("cost_score", 0),

            "time_score":
                result.get("time_score", 0),

            "comfort_score":
                result.get("comfort_score", 0),

            "transport_score":
                result.get("transport_score", 0),

            "hotel":
                result.get("hotel_cost", 0),

            "food":
                result.get("food_cost", 0),

            "activities":
                result.get("activity_cost", 0),

            "local_transport":
                result.get("local_transport_cost", 0),

            "contingency":
                result.get("contingency", 0),

            "total":
                result.get("total_cost", 0),

            "cost_per_person":
                result.get("cost_per_person", 0),

            "remaining_budget":
                result.get("remaining_budget", 0),

            "budget_status":
                result.get("budget_status"),

            "optimization_score":
                result.get("score", 0),

            "accommodation_level":
                result.get("accommodation_level"),

            "food_level":
                result.get("food_level"),

            "activity_level":
                result.get("activity_level"),

            "local_transport_level":
                result.get("local_transport_level"),

            "cost_sources":
                result.get("cost_sources", {}),

            "message":
                result.get("message"),

            "transport_options":
                transport_options,

            "scenarios":
                scenarios
        }

        print(json.dumps(output))

    except (ValueError, OSError, KeyError, TypeError) as e:

        print(json.dumps({
            "status": "error",
            "message": str(e)
        }))


if __name__ == "__main__":
    main()
