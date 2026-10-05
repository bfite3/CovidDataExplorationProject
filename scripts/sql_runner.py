"""
Execute SQL Server scripts using pyodbc.

Supports SQL scripts containing standalone GO
batch separators.
"""

from pathlib import Path
import re

import pyodbc


def execute_sql_file(
    connection: pyodbc.Connection,
    file_path: str | Path,
) -> None:
    """
    Read a SQL file, split it into batches,
    and execute each batch sequentially.
    """

    file_path = Path(file_path)
    sql = file_path.read_text(encoding="utf-8-sig")

    # Split only when GO appears on its own line.
    batches = re.split(
        r"^\s*GO\s*(?:--[^\r\n]*)?$",
        sql,
        flags=re.IGNORECASE | re.MULTILINE,
    )

    cursor = connection.cursor()

    try:
        for batch_number, batch in enumerate(batches, start=1):
            if not batch.strip():
                continue

            print(
                f"Executing {file_path.name}, "
                f"batch {batch_number}..."
            )

            cursor.execute(batch)

            # Consume any results before executing
            # the next SQL batch.
            while cursor.nextset():
                pass

        connection.commit()

    except Exception:
        connection.rollback()
        raise

    finally:
        cursor.close()