"""
Test SQL execution using the shared
database connection utility.
"""

from pathlib import Path

from db_connection import get_connection
from sql_runner import execute_sql_file


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    with get_connection() as connection:
        execute_sql_file(
            connection,
            ROOT / "sql" / "11_test_connection.sql"
        )

    print("SQL execution test completed successfully.")


if __name__ == "__main__":
    main()