from pathlib import Path
import pandas as pd
import re
import ast

# ============================================================
# TRAVEL COST OPTIMIZER
# DATA CLEANING AND PREPROCESSING
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = BASE_DIR / "data" / "raw"
PROCESSED_DIR = BASE_DIR / "data" / "processed"

PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

print("=" * 70)
print("TRAVEL COST OPTIMIZER - DATA CLEANING")
print("=" * 70)


# ------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------

def clean_column_names(df):
    """Standardize column names."""
    df = df.copy()

    df.columns = (
        df.columns
        .str.strip()
        .str.lower()
        .str.replace(" ", "_", regex=False)
    )

    return df


def clean_numeric(series):
    """Convert values containing symbols/text into numeric values."""
    return pd.to_numeric(
        series.astype(str)
        .str.replace(",", "", regex=False)
        .str.replace("₹", "", regex=False)
        .str.replace("Rs.", "", regex=False)
        .str.replace("Rs", "", regex=False)
        .str.extract(r"([-+]?\d*\.?\d+)")[0],
        errors="coerce"
    )


def extract_range(value):
    """
    Convert values such as:
    [700,1400]
    [700, 1400]
    into minimum and maximum values.
    """
    if pd.isna(value):
        return pd.Series([None, None])

    text = str(value)

    numbers = re.findall(r"\d+(?:\.\d+)?", text)

    if len(numbers) >= 2:
        return pd.Series([
            float(numbers[0]),
            float(numbers[1])
        ])

    return pd.Series([None, None])


# ============================================================
# 1. FLIGHTS
# ============================================================

print("\n[1/5] Cleaning flights dataset...")

flight_file = RAW_DIR / "flights" / "flights.csv"

if flight_file.exists():

    flights = pd.read_csv(flight_file)
    flights = clean_column_names(flights)

    print(f"Original rows: {len(flights)}")

    # Remove completely empty rows
    flights = flights.dropna(how="all")

    # Remove duplicate records
    flights = flights.drop_duplicates()

    # Clean all object columns
    for column in flights.select_dtypes(include="object").columns:
        flights[column] = flights[column].astype(str).str.strip()

    # Convert obvious numeric columns
    for column in flights.columns:
        if any(word in column for word in
               ["price", "fare", "duration", "stops"]):

            flights[column] = clean_numeric(flights[column])

    # Try to detect date columns
    for column in flights.columns:
        if "date" in column or "departure" in column:
            converted = pd.to_datetime(
                flights[column],
                errors="coerce"
            )

            if converted.notna().sum() > 0:
                flights[column] = converted

    output = PROCESSED_DIR / "flights.csv"
    flights.to_csv(output, index=False)

    print(f"Cleaned rows : {len(flights)}")
    print(f"Saved        : {output}")

else:
    print("WARNING: flights.csv not found.")


# ============================================================
# 2. HOTELS
# ============================================================

print("\n[2/5] Cleaning hotel datasets...")

hotel_dir = RAW_DIR / "hotels"

hotel_files = [
    hotel_dir / "bangalore.csv",
    hotel_dir / "chennai.csv",
    hotel_dir / "delhi.csv",
    hotel_dir / "hyderabad.csv",
    hotel_dir / "kolkata.csv",
    hotel_dir / "mumbai.csv"
]

hotel_frames = []

for file in hotel_files:

    if not file.exists():
        print(f"WARNING: {file.name} not found.")
        continue

    print(f"Reading: {file.name}")

    df = pd.read_csv(file)
    df = clean_column_names(df)

    # Add city from filename
    city = file.stem.title()
    df["city"] = city

    # Remove empty rows
    df = df.dropna(how="all")

    # Remove duplicates
    df = df.drop_duplicates()

    # Clean text columns
    for column in df.select_dtypes(include="object").columns:
        df[column] = df[column].astype(str).str.strip()

    # Convert columns related to money/rating
    for column in df.columns:

        column_lower = column.lower()

        if any(word in column_lower for word in
               ["price", "tax", "rating", "review", "room"]):

            numeric_values = clean_numeric(df[column])

            # Only replace if numeric conversion produced useful data
            if numeric_values.notna().sum() > 0:
                df[column] = numeric_values

    hotel_frames.append(df)


if hotel_frames:

    hotels = pd.concat(
        hotel_frames,
        ignore_index=True
    )

    hotels = hotels.drop_duplicates()

    output = PROCESSED_DIR / "hotels.csv"

    hotels.to_csv(
        output,
        index=False
    )

    print(f"Total hotel rows: {len(hotels)}")
    print(f"Saved: {output}")

else:
    print("WARNING: No hotel datasets found.")


# ============================================================
# 3. TOURISM
# ============================================================

print("\n[3/5] Cleaning tourism dataset...")

tourism_file = RAW_DIR / "tourism" / "tourism.csv"

if tourism_file.exists():

    tourism = pd.read_csv(
        tourism_file,
        low_memory=False
    )

    tourism = clean_column_names(tourism)

    tourism = tourism.dropna(how="all")
    tourism = tourism.drop_duplicates()

    # --------------------------------------------------------
    # Rename important columns
    # --------------------------------------------------------

    rename_map = {
        "coordinates.latitude": "latitude",
        "coordinates.longitude": "longitude",
        "destination_name": "destination"
    }

    tourism = tourism.rename(
        columns=rename_map
    )

    # --------------------------------------------------------
    # Convert coordinates
    # --------------------------------------------------------

    for column in ["latitude", "longitude"]:

        if column in tourism.columns:
            tourism[column] = pd.to_numeric(
                tourism[column],
                errors="coerce"
            )

    # --------------------------------------------------------
    # Convert numeric columns
    # --------------------------------------------------------

    numeric_columns = [
        "id",
        "altitude_m",
        "popularity_score",
        "nearest_airport.distance_km",
        "nearest_railway_station.distance_km",
        "nearest_major_city.distance_km",
        "minimum_days",
        "ideal_days",
        "maximum_days",
        "safety_rating"
    ]

    for column in numeric_columns:

        if column in tourism.columns:
            tourism[column] = pd.to_numeric(
                tourism[column],
                errors="coerce"
            )

    # --------------------------------------------------------
    # Extract budget ranges
    # --------------------------------------------------------

    range_columns = {
        "budget_category.accommodation_range":
            ("budget_accommodation_min",
             "budget_accommodation_max"),

        "budget_category.food_range":
            ("budget_food_min",
             "budget_food_max"),

        "budget_category.activities_range":
            ("budget_activities_min",
             "budget_activities_max"),

        "budget_category.local_transport_range":
            ("budget_transport_min",
             "budget_transport_max"),

        "budget_category.total_daily_range":
            ("budget_daily_min",
             "budget_daily_max"),

        "mid_range_category.accommodation_range":
            ("mid_accommodation_min",
             "mid_accommodation_max"),

        "mid_range_category.food_range":
            ("mid_food_min",
             "mid_food_max"),

        "mid_range_category.activities_range":
            ("mid_activities_min",
             "mid_activities_max"),

        "mid_range_category.local_transport_range":
            ("mid_transport_min",
             "mid_transport_max"),

        "mid_range_category.total_daily_range":
            ("mid_daily_min",
             "mid_daily_max"),

        "luxury_category.accommodation_range":
            ("luxury_accommodation_min",
             "luxury_accommodation_max"),

        "luxury_category.food_range":
            ("luxury_food_min",
             "luxury_food_max"),

        "luxury_category.activities_range":
            ("luxury_activities_min",
             "luxury_activities_max"),

        "luxury_category.local_transport_range":
            ("luxury_transport_min",
             "luxury_transport_max"),

        "luxury_category.total_daily_range":
            ("luxury_daily_min",
             "luxury_daily_max")
    }

    for source_column, new_columns in range_columns.items():

        if source_column in tourism.columns:

            tourism[
                list(new_columns)
            ] = tourism[source_column].apply(
                extract_range
            )

    # --------------------------------------------------------
    # Clean text columns
    # --------------------------------------------------------

    for column in tourism.select_dtypes(include="object").columns:

        tourism[column] = (
            tourism[column]
            .astype(str)
            .replace("nan", "")
            .str.strip()
        )

    output = PROCESSED_DIR / "tourism.csv"

    tourism.to_csv(
        output,
        index=False
    )

    print(f"Tourism rows: {len(tourism)}")
    print(f"Tourism columns after cleaning: {len(tourism.columns)}")
    print(f"Saved: {output}")

else:
    print("WARNING: tourism.csv not found.")


# ============================================================
# 4. FOOD
# ============================================================

print("\n[4/5] Cleaning food dataset...")

food_file = (
    RAW_DIR /
    "food" /
    "enhanced_zomato_dataset_clean.csv"
)

if food_file.exists():

    food = pd.read_csv(
        food_file,
        low_memory=False
    )

    food = clean_column_names(food)

    print(f"Original food rows: {len(food)}")

    food = food.dropna(how="all")
    food = food.drop_duplicates()

    # Clean text columns
    for column in food.select_dtypes(include="object").columns:

        food[column] = (
            food[column]
            .astype(str)
            .replace("nan", "")
            .str.strip()
        )

    # Convert price/rating columns
    for column in food.columns:

        column_lower = column.lower()

        if any(word in column_lower for word in
               ["price", "cost", "rating"]):

            numeric_values = clean_numeric(
                food[column]
            )

            if numeric_values.notna().sum() > 0:
                food[column] = numeric_values

    output = PROCESSED_DIR / "food.csv"

    food.to_csv(
        output,
        index=False
    )

    print(f"Cleaned food rows: {len(food)}")
    print(f"Saved: {output}")

else:
    print("WARNING: food dataset not found.")


# ============================================================
# 5. FUEL
# ============================================================

print("\n[5/5] Cleaning fuel price dataset...")

fuel_file = (
    RAW_DIR /
    "fuel" /
    "india_fuel_prices_daily.csv"
)

if fuel_file.exists():

    fuel = pd.read_csv(
        fuel_file,
        low_memory=False
    )

    fuel = clean_column_names(fuel)

    fuel = fuel.dropna(how="all")
    fuel = fuel.drop_duplicates()

    # Clean text columns
    for column in fuel.select_dtypes(include="object").columns:
        fuel[column] = (
            fuel[column]
            .astype(str)
            .replace("nan", "")
            .str.strip()
        )

    # Detect date column
    for column in fuel.columns:

        if "date" in column.lower():

            converted = pd.to_datetime(
                fuel[column],
                errors="coerce"
            )

            if converted.notna().sum() > 0:
                fuel[column] = converted

    # Convert fuel prices
    for column in fuel.columns:

        column_lower = column.lower()

        if any(word in column_lower for word in
               ["petrol", "diesel", "price"]):

            numeric_values = clean_numeric(
                fuel[column]
            )

            if numeric_values.notna().sum() > 0:
                fuel[column] = numeric_values

    output = (
        PROCESSED_DIR /
        "fuel_prices.csv"
    )

    fuel.to_csv(
        output,
        index=False
    )

    print(f"Cleaned fuel rows: {len(fuel)}")
    print(f"Saved: {output}")

else:
    print("WARNING: fuel dataset not found.")


# ============================================================
# FINAL SUMMARY
# ============================================================

print("\n" + "=" * 70)
print("DATA CLEANING COMPLETED")
print("=" * 70)

print("\nProcessed files:")

for file in sorted(PROCESSED_DIR.glob("*.csv")):

    try:
        df = pd.read_csv(file)

        print(
            f"  {file.name:<25} "
            f"{len(df):>8} rows × {len(df.columns):>3} columns"
        )

    except Exception as e:
        print(f"  {file.name}: ERROR - {e}")

print("\nOutput directory:")
print(PROCESSED_DIR)

print("=" * 70)