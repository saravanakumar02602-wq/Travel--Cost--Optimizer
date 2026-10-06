import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import sqlite3
import uuid


BASE_DIR = Path(__file__).resolve().parent.parent
DATABASE_FILE = Path(
    os.environ.get(
        "TRAVEL_OPTIMIZER_DB",
        str(BASE_DIR / "database" / "travel_optimizer.db")
    )
)


def initialize_database():
    DATABASE_FILE.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(DATABASE_FILE) as connection:
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS trips (
                trip_id TEXT PRIMARY KEY,
                origin TEXT NOT NULL,
                destination TEXT NOT NULL,
                travelers INTEGER NOT NULL CHECK (travelers > 0),
                days INTEGER NOT NULL CHECK (days > 0),
                budget REAL NOT NULL CHECK (budget > 0),
                preference TEXT NOT NULL,
                selected_transport TEXT NOT NULL,
                total_cost REAL NOT NULL,
                cost_per_person REAL NOT NULL,
                optimization_score REAL NOT NULL,
                created_at TEXT NOT NULL
            )
            """
        )
        connection.execute(
            "CREATE INDEX IF NOT EXISTS idx_trips_created_at ON trips(created_at)"
        )


def save_trip(trip):
    required = (
        "origin",
        "destination",
        "travelers",
        "days",
        "budget",
        "preference",
        "transport_mode",
        "total",
        "cost_per_person",
        "optimization_score"
    )
    missing = [field for field in required if trip.get(field) is None]
    if missing:
        raise ValueError(f"Missing trip fields: {', '.join(missing)}")

    trip_id = str(uuid.uuid4())
    created_at = datetime.now(timezone.utc).isoformat()
    values = (
        trip_id,
        str(trip["origin"]),
        str(trip["destination"]),
        int(trip["travelers"]),
        int(trip["days"]),
        float(trip["budget"]),
        str(trip["preference"]),
        str(trip["transport_mode"]),
        float(trip["total"]),
        float(trip["cost_per_person"]),
        float(trip["optimization_score"]),
        created_at
    )

    initialize_database()
    with sqlite3.connect(DATABASE_FILE) as connection:
        connection.execute(
            """
            INSERT INTO trips (
                trip_id, origin, destination, travelers, days, budget,
                preference, selected_transport, total_cost, cost_per_person,
                optimization_score, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            values
        )

    return {"trip_id": trip_id, "created_at": created_at}


def list_trips(limit=100):
    initialize_database()
    with sqlite3.connect(DATABASE_FILE) as connection:
        connection.row_factory = sqlite3.Row
        rows = connection.execute(
            """
            SELECT trip_id, origin, destination, travelers, days, budget,
                   preference, selected_transport, total_cost,
                   cost_per_person, optimization_score, created_at
            FROM trips
            ORDER BY created_at DESC
            LIMIT ?
            """,
            (max(1, min(int(limit), 500)),)
        ).fetchall()
    return [dict(row) for row in rows]


def main():
    parser = argparse.ArgumentParser(description="Save or list optimized trips.")
    parser.add_argument("action", choices=("initialize", "list", "save"))
    parser.add_argument("--origin")
    parser.add_argument("--destination")
    parser.add_argument("--travelers", type=int)
    parser.add_argument("--days", type=int)
    parser.add_argument("--budget", type=float)
    parser.add_argument("--preference")
    parser.add_argument("--transport-mode")
    parser.add_argument("--total", type=float)
    parser.add_argument("--cost-per-person", type=float)
    parser.add_argument("--optimization-score", type=float)
    parser.add_argument("--limit", type=int, default=100)
    args = parser.parse_args()

    try:
        if args.action == "initialize":
            initialize_database()
            result = {"status": "success"}
        elif args.action == "list":
            result = {"status": "success", "trips": list_trips(args.limit)}
        else:
            result = {
                "status": "success",
                **save_trip({
                    "origin": args.origin,
                    "destination": args.destination,
                    "travelers": args.travelers,
                    "days": args.days,
                    "budget": args.budget,
                    "preference": args.preference,
                    "transport_mode": args.transport_mode,
                    "total": args.total,
                    "cost_per_person": args.cost_per_person,
                    "optimization_score": args.optimization_score
                })
            }
        print(json.dumps(result))
    except (OSError, sqlite3.Error, TypeError, ValueError) as error:
        print(json.dumps({"status": "error", "message": str(error)}))


if __name__ == "__main__":
    main()
