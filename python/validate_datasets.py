from pathlib import Path
import pandas as pd

# ============================================================
# TRAVEL COST OPTIMIZER
# DATASET VALIDATION
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data" / "processed"

print("=" * 70)
print("TRAVEL COST OPTIMIZER - DATASET VALIDATION")
print("=" * 70)


def check_dataset(filename):
    file_path = DATA_DIR / filename

    print("\n" + "-" * 70)
    print(f"FILE: {filename}")
    print("-" * 70)

    if not file_path.exists():
        print("ERROR: File not found")
        return

    df = pd.read_csv(file_path, low_memory=False)

    print(f"Rows       : {df.shape[0]}")
    print(f"Columns    : {df.shape[1]}")

    # --------------------------------------------------------
    # Missing values
    # --------------------------------------------------------

    missing = df.isnull().sum()
    missing = missing[missing > 0]

    print("\nMissing Values:")

    if len(missing) == 0:
        print("  None")
    else:
        for column, count in missing.items():
            percentage = (count / len(df)) * 100
            print(
                f"  {column:<40} "
                f"{count:>8} ({percentage:.2f}%)"
            )

    # --------------------------------------------------------
    # Duplicate rows
    # --------------------------------------------------------

    duplicates = df.duplicated().sum()

    print("\nDuplicate Rows:")
    print(f"  {duplicates}")

    # --------------------------------------------------------
    # Numeric columns
    # --------------------------------------------------------

    numeric_columns = df.select_dtypes(
        include="number"
    ).columns

    print("\nNumeric Columns:")

    if len(numeric_columns) == 0:
        print("  None")
    else:
        for column in numeric_columns:
            print(f"  - {column}")

    # --------------------------------------------------------
    # Important statistics
    # --------------------------------------------------------

    print("\nNumeric Summary:")

    if len(numeric_columns) > 0:
        print(
            df[numeric_columns]
            .describe()
            .round(2)
            .to_string()
        )

    # --------------------------------------------------------
    # First 3 rows
    # --------------------------------------------------------

    print("\nFirst 3 Records:")
    print(
        df.head(3).to_string(index=False)
    )


# ============================================================
# VALIDATE ALL DATASETS
# ============================================================

datasets = [
    "flights.csv",
    "hotels.csv",
    "tourism.csv",
    "food.csv",
    "fuel_prices.csv"
]

for dataset in datasets:
    check_dataset(dataset)


# ============================================================
# FINAL
# ============================================================

print("\n" + "=" * 70)
print("DATASET VALIDATION COMPLETED")
print("=" * 70)