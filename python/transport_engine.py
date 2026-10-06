from pathlib import Path
import math
import re
from pathlib import Path
import pandas as pd


BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data" / "processed"

FLIGHTS_FILE = DATA_DIR / "flights.csv"
FUEL_FILE = DATA_DIR / "fuel_prices.csv"


# ---------------------------------------------------------
# LOAD DATA
# ---------------------------------------------------------

def load_flights():
    return pd.read_csv(FLIGHTS_FILE)


def load_fuel():
    return pd.read_csv(FUEL_FILE)


def duration_hours(value):
    if pd.isna(value):
        return None

    try:
        hours = float(value)
        return hours if math.isfinite(hours) and hours > 0 else None
    except (TypeError, ValueError):
        pass

    text = str(value).strip().lower()
    hour_match = re.search(r"(\d+(?:\.\d+)?)\s*(?:h|hr|hrs|hour|hours)\b", text)
    minute_match = re.search(r"(\d+(?:\.\d+)?)\s*(?:m|min|mins|minute|minutes)\b", text)
    hours = float(hour_match.group(1)) if hour_match else 0.0
    minutes = float(minute_match.group(1)) if minute_match else 0.0
    total = hours + minutes / 60
    return total if total > 0 else None


# ---------------------------------------------------------
# CITY COORDINATES
# ---------------------------------------------------------

CITY_COORDINATES = {
    "Chennai": (13.0827, 80.2707),
    "Goa": (15.4909, 73.8278),
    "Mumbai": (19.0760, 72.8777),
    "Delhi": (28.6139, 77.2090),
    "Bangalore": (12.9716, 77.5946),
    "Hyderabad": (17.3850, 78.4867),
    "Kolkata": (22.5726, 88.3639),
    "Pune": (18.5204, 73.8567),
    "Ahmedabad": (23.0225, 72.5714),
    "Jaipur": (26.9124, 75.7873),
    "Kochi": (9.9312, 76.2673),
    "Coimbatore": (11.0168, 76.9558),
}

CITY_COUNTRIES = {city: "India" for city in CITY_COORDINATES}
INTERNATIONAL_CITIES = {
    "Dubai": (25.2048, 55.2708, "United Arab Emirates"),
    "Abu Dhabi": (24.4539, 54.3773, "United Arab Emirates"),
    "Doha": (25.2854, 51.5310, "Qatar"),
    "Riyadh": (24.7136, 46.6753, "Saudi Arabia"),
    "Jeddah": (21.4858, 39.1925, "Saudi Arabia"),
    "Muscat": (23.5880, 58.3829, "Oman"),
    "Kuwait City": (29.3759, 47.9774, "Kuwait"),
    "Manama": (26.2285, 50.5860, "Bahrain"),
    "Singapore": (1.3521, 103.8198, "Singapore"),
    "Kuala Lumpur": (3.1390, 101.6869, "Malaysia"),
    "Bangkok": (13.7563, 100.5018, "Thailand"),
    "Phuket": (7.8804, 98.3923, "Thailand"),
    "Bali": (-8.4095, 115.1889, "Indonesia"),
    "Jakarta": (-6.2088, 106.8456, "Indonesia"),
    "Manila": (14.5995, 120.9842, "Philippines"),
    "Ho Chi Minh City": (10.8231, 106.6297, "Vietnam"),
    "Hanoi": (21.0278, 105.8342, "Vietnam"),
    "Hong Kong": (22.3193, 114.1694, "Hong Kong"),
    "Tokyo": (35.6762, 139.6503, "Japan"),
    "Osaka": (34.6937, 135.5023, "Japan"),
    "Seoul": (37.5665, 126.9780, "South Korea"),
    "Taipei": (25.0330, 121.5654, "Taiwan"),
    "Beijing": (39.9042, 116.4074, "China"),
    "Shanghai": (31.2304, 121.4737, "China"),
    "Istanbul": (41.0082, 28.9784, "Turkey"),
    "London": (51.5072, -0.1276, "United Kingdom"),
    "Edinburgh": (55.9533, -3.1883, "United Kingdom"),
    "Paris": (48.8566, 2.3522, "France"),
    "Nice": (43.7102, 7.2620, "France"),
    "Amsterdam": (52.3676, 4.9041, "Netherlands"),
    "Brussels": (50.8503, 4.3517, "Belgium"),
    "Berlin": (52.5200, 13.4050, "Germany"),
    "Munich": (48.1351, 11.5820, "Germany"),
    "Rome": (41.9028, 12.4964, "Italy"),
    "Milan": (45.4642, 9.1900, "Italy"),
    "Barcelona": (41.3874, 2.1686, "Spain"),
    "Madrid": (40.4168, -3.7038, "Spain"),
    "Lisbon": (38.7223, -9.1393, "Portugal"),
    "Zurich": (47.3769, 8.5417, "Switzerland"),
    "Vienna": (48.2082, 16.3738, "Austria"),
    "Prague": (50.0755, 14.4378, "Czechia"),
    "Athens": (37.9838, 23.7275, "Greece"),
    "Cairo": (30.0444, 31.2357, "Egypt"),
    "Nairobi": (-1.2921, 36.8219, "Kenya"),
    "Cape Town": (-33.9249, 18.4241, "South Africa"),
    "Johannesburg": (-26.2041, 28.0473, "South Africa"),
    "New York": (40.7128, -74.0060, "United States"),
    "Los Angeles": (34.0522, -118.2437, "United States"),
    "San Francisco": (37.7749, -122.4194, "United States"),
    "Chicago": (41.8781, -87.6298, "United States"),
    "Miami": (25.7617, -80.1918, "United States"),
    "Washington, D.C.": (38.9072, -77.0369, "United States"),
    "Toronto": (43.6532, -79.3832, "Canada"),
    "Vancouver": (49.2827, -123.1207, "Canada"),
    "Mexico City": (19.4326, -99.1332, "Mexico"),
    "Cancun": (21.1619, -86.8515, "Mexico"),
    "Rio de Janeiro": (-22.9068, -43.1729, "Brazil"),
    "Sao Paulo": (-23.5505, -46.6333, "Brazil"),
    "Buenos Aires": (-34.6037, -58.3816, "Argentina"),
    "Sydney": (-33.8688, 151.2093, "Australia"),
    "Melbourne": (-37.8136, 144.9631, "Australia"),
    "Auckland": (-36.8509, 174.7645, "New Zealand"),
    "Colombo": (6.9271, 79.8612, "Sri Lanka"),
    "Kathmandu": (27.7172, 85.3240, "Nepal"),
    "Dhaka": (23.8103, 90.4125, "Bangladesh"),
    "Male": (4.1755, 73.5093, "Maldives"),
    "Thimphu": (27.4728, 89.6390, "Bhutan"),
}
for city, (latitude, longitude, country) in INTERNATIONAL_CITIES.items():
    CITY_COORDINATES[city] = (latitude, longitude)
    CITY_COUNTRIES[city] = country

CITY_ALIASES = {
    "bengaluru": "Bangalore",
    "bombay": "Mumbai",
    "new delhi": "Delhi",
    "nyc": "New York",
    "new york city": "New York",
    "abu dhabi, uae": "Abu Dhabi",
    "dubai, uae": "Dubai",
    "dubai, united arab emirates": "Dubai",
    "singapore city": "Singapore",
    "ho chi minh": "Ho Chi Minh City",
    "saigon": "Ho Chi Minh City",
    "bali, indonesia": "Bali",
    "male, maldives": "Male",
    "washington dc": "Washington, D.C.",
}


def resolve_city_name(value):
    normalized = " ".join(str(value).strip().casefold().split())
    base_name = normalized.split(",", 1)[0].strip()
    alias = CITY_ALIASES.get(normalized, CITY_ALIASES.get(base_name))
    if alias in CITY_COORDINATES:
        return alias

    for city in CITY_COORDINATES:
        city_normalized = city.casefold()
        if normalized == city_normalized or normalized.startswith(city_normalized + ","):
            return city
        if normalized.startswith(city_normalized + " "):
            suffix = normalized[len(city_normalized):].strip(" ,")
            if suffix in {
                CITY_COUNTRIES[city].casefold(),
                "usa",
                "us",
                "uk",
                "uae",
            }:
                return city

    return None


FUEL_FILE = Path(__file__).resolve().parent.parent / "data" / "processed" / "fuel_prices.csv"
FUEL_CITY_ALIASES = {
    "bangalore": "bengaluru",
}


# ---------------------------------------------------------
# HAVERSINE DISTANCE
# ---------------------------------------------------------

def haversine_distance(origin, destination):

    if origin not in CITY_COORDINATES:
        return None

    if destination not in CITY_COORDINATES:
        return None

    lat1, lon1 = CITY_COORDINATES[origin]
    lat2, lon2 = CITY_COORDINATES[destination]

    radius = 6371

    lat1 = math.radians(lat1)
    lat2 = math.radians(lat2)

    dlat = math.radians(
        CITY_COORDINATES[destination][0]
        - CITY_COORDINATES[origin][0]
    )

    dlon = math.radians(
        CITY_COORDINATES[destination][1]
        - CITY_COORDINATES[origin][1]
    )

    a = (
        math.sin(dlat / 2) ** 2
        +
        math.cos(lat1)
        * math.cos(lat2)
        * math.sin(dlon / 2) ** 2
    )

    c = 2 * math.atan2(
        math.sqrt(a),
        math.sqrt(1 - a)
    )

    return radius * c


# ---------------------------------------------------------
# FLIGHT OPTION
# ---------------------------------------------------------

def get_flight_cost(
    origin,
    destination,
    travelers
):

    flights = load_flights()

    source_col = None
    destination_col = None
    price_col = None
    duration_col = None

    for col in flights.columns:

        name = col.lower()

        if "source" in name:
            source_col = col

        if "destination" in name:
            destination_col = col

        if "price" in name:
            price_col = col
        if "duration" in name:
            duration_col = col

    if not source_col or not destination_col or not price_col:
        return None

    data = flights[
        flights[source_col]
        .astype(str)
        .str.lower()
        .str.strip()
        == origin.lower().strip()
    ]

    data = data[
        data[destination_col]
        .astype(str)
        .str.lower()
        .str.strip()
        == destination.lower().strip()
    ]

    prices = pd.to_numeric(data[price_col], errors="coerce").dropna()
    if prices.empty:
        distance = haversine_distance(origin, destination)
        if distance is None:
            return None

        price_per_person = max(3500.0, distance * 7.2)
        estimated_time_hours = max(1.5, distance / 720 + 1.5)
        fare_source = "distance-based flight estimate; no matching fare data"
    else:
        cheapest_price_index = prices.idxmin()
        price_per_person = float(prices.loc[cheapest_price_index])
        estimated_time_hours = None
        if duration_col:
            estimated_time_hours = duration_hours(
                data.loc[cheapest_price_index, duration_col]
            )
            if estimated_time_hours is None:
                durations = data[duration_col].map(duration_hours).dropna()
                if not durations.empty:
                    estimated_time_hours = float(durations.median())
            if estimated_time_hours is not None:
                estimated_time_hours = round(estimated_time_hours, 1)
        fare_source = "flight price dataset"

    return {
        "mode": "Flight",
        "cost": round(
            price_per_person * travelers,
            2
        ),
        "cost_per_person": round(
            price_per_person,
            2
        ),
        "distance_km": None,
        "estimated_time_hours": (
            round(estimated_time_hours, 1)
            if estimated_time_hours is not None
            else None
        ),
        "cost_source": fare_source
    }


# ---------------------------------------------------------
# TRAIN ESTIMATE
# ---------------------------------------------------------

def get_train_cost(
    distance_km,
    travelers
):

    if distance_km is None:
        return None

    # Approximate sleeper/general travel estimate
    rate_per_km = 0.75

    cost_per_person = distance_km * rate_per_km

    return {
        "mode": "Train",
        "cost": round(
            cost_per_person * travelers,
            2
        ),
        "cost_per_person": round(
            cost_per_person,
            2
        ),
        "distance_km": round(
            distance_km,
            2
        ),
        "estimated_time_hours": round(
            distance_km / 55,
            1
        )
    }


# ---------------------------------------------------------
# BUS ESTIMATE
# ---------------------------------------------------------

def get_bus_cost(
    distance_km,
    travelers
):

    if distance_km is None:
        return None

    rate_per_km = 1.25

    cost_per_person = distance_km * rate_per_km

    return {
        "mode": "Bus",
        "cost": round(
            cost_per_person * travelers,
            2
        ),
        "cost_per_person": round(
            cost_per_person,
            2
        ),
        "distance_km": round(
            distance_km,
            2
        ),
        "estimated_time_hours": round(
            distance_km / 45,
            1
        )
    }


# ---------------------------------------------------------
# CAR ESTIMATE
# ---------------------------------------------------------

def latest_petrol_price(cities):
    fuel = pd.read_csv(FUEL_FILE, low_memory=False)
    fuel["date"] = pd.to_datetime(fuel["date"], errors="coerce")
    fuel["petrol_price_inr_per_litre"] = pd.to_numeric(
        fuel["petrol_price_inr_per_litre"],
        errors="coerce"
    )
    fuel = fuel.dropna(subset=["date", "petrol_price_inr_per_litre"])
    if fuel.empty:
        raise ValueError("The fuel dataset contains no valid petrol price records.")

    wanted = {
        FUEL_CITY_ALIASES.get(str(city).strip().lower(), str(city).strip().lower())
        for city in cities
    }
    route_prices = []
    for city, records in fuel.groupby("city"):
        normalized_city = FUEL_CITY_ALIASES.get(str(city).strip().lower(), str(city).strip().lower())
        if normalized_city not in wanted:
            continue
        latest_date = records["date"].max()
        latest_prices = records.loc[
            records["date"] == latest_date,
            "petrol_price_inr_per_litre"
        ]
        route_prices.extend(latest_prices.tolist())

    if route_prices:
        return float(sum(route_prices) / len(route_prices)), "latest route-city fuel dataset records"

    latest_date = fuel["date"].max()
    latest_prices = fuel.loc[
        fuel["date"] == latest_date,
        "petrol_price_inr_per_litre"
    ]
    return float(latest_prices.median()), "latest national fuel dataset records"


def get_car_cost(
    distance_km,
    travelers,
    origin=None,
    destination=None
):

    if distance_km is None:
        return None

    # Average mileage
    mileage = 15

    route_cities = [city for city in (origin, destination) if city]
    fuel_price, fuel_price_source = latest_petrol_price(route_cities)

    fuel_required = distance_km / mileage

    fuel_cost = fuel_required * fuel_price

    # Approximate toll estimate
    toll_cost = distance_km * 0.75

    total_cost = (
        fuel_cost
        +
        toll_cost
    )

    cost_per_person = (
        total_cost / travelers
    )

    return {
        "mode": "Car",
        "cost": round(
            total_cost,
            2
        ),
        "cost_per_person": round(
            cost_per_person,
            2
        ),
        "distance_km": round(
            distance_km,
            2
        ),
        "estimated_time_hours": round(
            distance_km / 60,
            1
        ),
        "fuel_cost": round(
            fuel_cost,
            2
        ),
        "fuel_price_per_litre": round(fuel_price, 2),
        "fuel_price_source": fuel_price_source,
        "mileage_km_per_litre": mileage,
        "toll_cost": round(
            toll_cost,
            2
        )
    }


# ---------------------------------------------------------
# COMPLETE TRANSPORT COMPARISON
# ---------------------------------------------------------

def compare_transport(
    origin,
    destination,
    travelers
):

    distance = haversine_distance(
        origin,
        destination
    )

    options = []

    flight = get_flight_cost(
        origin,
        destination,
        travelers
    )

    if flight:
        options.append(flight)

    same_country = CITY_COUNTRIES.get(origin) == CITY_COUNTRIES.get(destination)
    if same_country:
        train = get_train_cost(distance, travelers)
        if train:
            options.append(train)

        bus = get_bus_cost(distance, travelers)
        if bus:
            options.append(bus)

        car = get_car_cost(
            distance,
            travelers,
            origin=origin,
            destination=destination
        )
        if car:
            options.append(car)

    return {
        "origin": origin,
        "destination": destination,
        "distance_km": round(distance, 2)
        if distance else None,
        "options": options
    }


# ---------------------------------------------------------
# TEST
# ---------------------------------------------------------

if __name__ == "__main__":

    result = compare_transport(
        "Chennai",
        "Goa",
        2
    )

    print("\n" + "=" * 60)
    print("TRAVELOPTIMA TRANSPORT COMPARISON")
    print("=" * 60)

    print(
        f"\nRoute: "
        f"{result['origin']} → "
        f"{result['destination']}"
    )

    print(
        f"Distance: "
        f"{result['distance_km']} km"
    )

    print("\nTransport Options:")

    for option in result["options"]:

        print(
            f"\n{option['mode']}"
        )

        print(
            f"  Total Cost: ₹"
            f"{option['cost']:,.2f}"
        )

        print(
            f"  Cost/Person: ₹"
            f"{option['cost_per_person']:,.2f}"
        )

        if option.get("estimated_time_hours"):
            print(
                f"  Estimated Time: "
                f"{option['estimated_time_hours']} hours"
            )

    print("\n" + "=" * 60)