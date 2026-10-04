
from pathlib import Path
import pandas as pd
from db_connection import get_connection

# Configuration
ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = ROOT / "data" / "owid-covid-data.csv"


CHUNK_SIZE = 1000

# Only import columns needed for our initial analysis.
TEXT_COLUMNS = ["iso_code", "continent", "location"]
DATE_COLUMN = "date"
NUMERIC_COLUMNS = [
    "population",
    "total_cases",
    "new_cases",
    "total_deaths",
    "new_deaths",
    "new_vaccinations",
    "total_vaccinations",
]

COLUMNS = TEXT_COLUMNS + [DATE_COLUMN] + NUMERIC_COLUMNS

def main():
    connection = get_connection()
    cursor = connection.cursor()

    # Rebuild the staging table.
    # WARNING: This removes any existing staging.CovidRaw data.
    cursor.execute("""
    IF OBJECT_ID('staging.CovidRaw', 'U') IS NOT NULL
        DROP TABLE staging.CovidRaw;
    
    CREATE TABLE staging.CovidRaw (
        iso_code NVARCHAR(20) NULL,
        continent NVARCHAR(100) NULL,
        location NVARCHAR(200) NOT NULL,
        [date] DATE NOT NULL,
        population FLOAT NULL,
        total_cases FLOAT NULL,
        new_cases FLOAT NULL,
        total_deaths FLOAT NULL,
        new_deaths FLOAT NULL,
        new_vaccinations FLOAT NULL,
        total_vaccinations FLOAT NULL
    );
    """)
    connection.commit()

    column_names = ", ".join(
        f"[{column}]" for column in COLUMNS
    )
    placeholders = ", ".join("?" for _ in COLUMNS)

    insert_sql = (
        f"INSERT INTO staging.CovidRaw ({column_names}) "
        f"VALUES ({placeholders})"
    )

    cursor.fast_executemany = True
    total_rows = 0

    try:
        reader = pd.read_csv(
            CSV_PATH,
            usecols=COLUMNS,
            dtype=str,
            chunksize=CHUNK_SIZE,
            keep_default_na=True,
            low_memory=False,
        )

        for chunk in reader:
            # Validate dates.
            chunk[DATE_COLUMN] = pd.to_datetime(
                chunk[DATE_COLUMN],
                errors="raise"
            ).dt.date

            # Validate numeric fields without silently
            # converting unexpected text into NULL.
            for column in NUMERIC_COLUMNS:
                original = chunk[column]
                converted = pd.to_numeric(
                    original, errors="coerce"
                )

                invalid = (
                    original.notna() & converted.isna()
                )

                if invalid.any():
                    raise ValueError(
                        f"Invalid numeric data in {column}: "
                        f"{original[invalid].head().tolist()}"
                    )

                chunk[column] = converted

            if chunk["location"].isna().any():
                raise ValueError("Missing location detected.")

            if chunk["date"].isna().any():
                raise ValueError("Missing date detected.")

            # Convert pandas missing values into SQL NULL.
            chunk = chunk.astype(object).where(
                pd.notna(chunk), None
            )

            # Match the INSERT statement's column order.
            rows = list(
                chunk[COLUMNS].itertuples(
                    index=False, name=None
                )
            )

            cursor.executemany(insert_sql, rows)
            connection.commit()

            total_rows += len(rows)
            print(f"Imported {total_rows:,} rows")

        cursor.execute("""
            SELECT
                COUNT(*) AS total_rows,
                MIN([date]) AS earliest_date,
                MAX([date]) AS latest_date
            FROM staging.CovidRaw;
        """)

        print("\nImport complete.")
        print("SQL Server validation:", cursor.fetchone())

    finally:
        cursor.close()
        connection.close()
