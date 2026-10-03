"""
Run and validate the COVID-19 data pipeline.

The initial implementation runs read-only SQL assertions
without modifying the existing database.
"""

from pathlib import Path
from time import perf_counter

from db_connection import get_connection
from sql_runner import execute_sql_file


ROOT = Path(__file__).resolve().parents[1]

VALIDATION_SCRIPTS = [
    "09_assert_data_quality.sql",
    "10_assert_dashboard_views.sql",
]


def run_stage(name, action):
    """Execute a pipeline stage and report its duration."""

    print(f"\nSTART: {name}")
    start = perf_counter()

    try:
        action()
    except Exception:
        elapsed = perf_counter() - start
        print(f"FAIL: {name} ({elapsed:.2f} seconds)")
        raise

    elapsed = perf_counter() - start
    print(f"PASS: {name} ({elapsed:.2f} seconds)")


def main():
    print("Starting COVID-19 pipeline validation...")

    connection = get_connection()

    try:
        for filename in VALIDATION_SCRIPTS:
            run_stage(
                filename,
                lambda filename=filename: execute_sql_file(
                    connection,
                    ROOT / "sql" / filename
                )
            )

    finally:
        connection.close()

    print("\nAll pipeline validation stages passed.")


if __name__ == "__main__":
    main()