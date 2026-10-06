from pathlib import Path
import pandas as pd

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data" / "raw"

print("=" * 70)
print("TRAVEL COST OPTIMIZER - DATASET INSPECTION")
print("=" * 70)

csv_files = list(DATA_DIR.rglob("*.csv"))

if not csv_files:
    print("No CSV files found.")
    exit()

for file in csv_files:
    print("\n" + "=" * 70)
    print(f"FILE: {file.relative_to(BASE_DIR)}")
    print("=" * 70)

    try:
        df = pd.read_csv(file)

        print(f"Rows    : {df.shape[0]}")
        print(f"Columns : {df.shape[1]}")

        print("\nColumns:")
        for column in df.columns:
            print(f"  - {column}")

        print("\nData Types:")
        print(df.dtypes.to_string())

        print("\nMissing Values:")
        missing = df.isnull().sum()
        missing = missing[missing > 0]

        if len(missing) == 0:
            print("  No missing values")
        else:
            print(missing.to_string())

        print("\nDuplicate Rows:")
        print(f"  {df.duplicated().sum()}")

        print("\nFirst 3 Records:")
        print(df.head(3).to_string(index=False))

    except Exception as e:
        print(f"ERROR reading file: {e}")

print("\n" + "=" * 70)
print("DATASET INSPECTION COMPLETED")
print("=" * 70)