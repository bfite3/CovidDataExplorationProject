"""
Run the COVID-19 data pipeline.

Modes:
- validate: Run automated SQL assertions only.
- full: Download source data, rebuild analytical data,
  create dashboard views, and run all assertions.
"""

import argparse
from collections.abc import Callable, Sequence
from pathlib import Path
from time import perf_counter

import pyodbc

from db_connection import get_connection
from download_covid import main as download_covid
from import_covid import main as import_covid
from sql_runner import execute_sql_file


ROOT = Path(__file__).resolve().parents[1]

VALIDATION_SCRIPTS = [
    "09_assert_data_quality.sql",
    "10_assert_dashboard_views.sql",
]

TRANSFORMATION_SCRIPTS = [
    "01_clean_staging_data.sql",
    "02_create_analytical_tables.sql",
]

DASHBOARD_SCRIPTS = [
    "07_create_dashboard_views.sql",
]


def parse_arguments() -> argparse.Namespace:
    """Parse pipeline execution options."""

    parser = argparse.ArgumentParser(
        description="Execute the COVID-19 data pipeline."
    )

    parser.add_argument(
        "--mode",
        choices=["validate", "full"],
        default="validate",
        help="Pipeline mode (default: validate).",
    )

    parser.add_argument(
        "--confirm-rebuild",
        action="store_true",
        help=(
            "Required with --mode full. "
            "Confirms that existing pipeline tables may be replaced."
        ),
    )

    return parser.parse_args()


def run_stage(
    name: str,
    action: Callable[[], None],
) -> None:
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


def run_sql_scripts(
    connection: pyodbc.Connection,
    filenames: Sequence[str],
) -> None:
    """Execute SQL files sequentially using one connection."""

    for filename in filenames:
        run_stage(
            filename,
            lambda filename=filename: execute_sql_file(
                connection,
                ROOT / "sql" / filename,
            ),
        )


def run_validation() -> None:
    """Run read-only pipeline validation."""

    print("Starting COVID-19 pipeline validation...")

    connection = get_connection()

    try:
        run_sql_scripts(
            connection,
            VALIDATION_SCRIPTS,
        )

    finally:
        connection.close()

    print("\nAll pipeline validation stages passed.")


def initialize_database() -> None:
    """
    Initialize the project database and staging schema.

    Connect to master because CovidPortfolioProject
    may not exist yet.
    """

    connection = get_connection(
        database="master",
        autocommit=True,
    )

    try:
        execute_sql_file(
            connection,
            ROOT / "sql" / "00_database_setup.sql",
        )

    finally:
        connection.close()


def run_full_pipeline() -> None:
    """Execute the complete rebuild and validation pipeline."""

    print("Starting full COVID-19 pipeline...")

    pipeline_start = perf_counter()

    # 1. Download and validate source CSV.
    run_stage(
        "Download source dataset",
        download_covid,
    )

    # 2. Create the database/schema if needed.
    run_stage(
        "Initialize SQL Server database",
        initialize_database,
    )

    # 3. Load raw CSV records into staging.CovidRaw.
    run_stage(
        "Import source data",
        import_covid,
    )

    # 4. Clean staging data and create analytical tables.
    connection = get_connection()

    try:
        run_sql_scripts(
            connection,
            TRANSFORMATION_SCRIPTS,
        )

        # 5. Validate analytical data.
        run_stage(
            "09_assert_data_quality.sql",
            lambda: execute_sql_file(
                connection,
                ROOT / "sql" / "09_assert_data_quality.sql",
            ),
        )

        # 6. Create Tableau-ready views.
        run_sql_scripts(
            connection,
            DASHBOARD_SCRIPTS,
        )

        # 7. Validate Tableau-ready views.
        run_stage(
            "10_assert_dashboard_views.sql",
            lambda: execute_sql_file(
                connection,
                ROOT / "sql" / "10_assert_dashboard_views.sql",
            ),
        )

    finally:
        connection.close()

    elapsed = perf_counter() - pipeline_start

    print(
        "\nFull COVID-19 pipeline completed successfully."
    )
    print(
        f"Total execution time: {elapsed:.2f} seconds"
    )


def main() -> None:
    """Run the requested pipeline mode."""

    args = parse_arguments()

    if args.mode == "validate":
        run_validation()
        return

    if not args.confirm_rebuild:
        raise RuntimeError(
            "Full mode replaces existing pipeline data. "
            "Rerun with --confirm-rebuild to continue."
        )

    run_full_pipeline()


if __name__ == "__main__":
    main()