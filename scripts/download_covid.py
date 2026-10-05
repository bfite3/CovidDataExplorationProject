"""
Download the historical OWID COVID-19 dataset.

The file is saved to the project's data directory
for subsequent ingestion into SQL Server.
"""

from pathlib import Path
from urllib.request import urlopen
import csv
import shutil
import hashlib

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"

CSV_PATH = DATA_DIR / "owid-covid-data.csv"
TEMP_PATH = DATA_DIR / "owid-covid-data.csv.tmp"

SOURCE_URL = (
    "https://raw.githubusercontent.com/owid/covid-19-data/"
    "master/public/data/owid-covid-data.csv"
)

REQUIRED_COLUMNS = {
    "iso_code",
    "continent",
    "location",
    "date",
    "population",
    "total_cases",
    "new_cases",
    "total_deaths",
    "new_deaths",
    "new_vaccinations",
    "total_vaccinations",
}


def calculate_sha256(
    file_path: Path,
) -> str:
    sha256 = hashlib.sha256()

    with file_path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            sha256.update(chunk)

    return sha256.hexdigest()


def main() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    print("Downloading historical COVID-19 dataset...")

    try:
        with urlopen(SOURCE_URL, timeout=120) as response:
            with TEMP_PATH.open("wb") as output:
                shutil.copyfileobj(response, output)

        # Check that the downloaded file has the
        # columns required by the ingestion script.
        with TEMP_PATH.open(
            "r",
            encoding="utf-8-sig",
            newline=""
        ) as source:
            reader = csv.reader(source)
            columns = set(next(reader))

        missing = REQUIRED_COLUMNS - columns

        if missing:
            raise ValueError(
                f"Downloaded dataset is missing columns: {missing}"
            )

        # Replace the existing CSV only after
        # the new download passes validation.
        TEMP_PATH.replace(CSV_PATH)

        print(f"Download complete: {CSV_PATH}")
        print(f"File size: {CSV_PATH.stat().st_size:,} bytes")
        print(f"SHA-256: {calculate_sha256(CSV_PATH)}")

    finally:
        TEMP_PATH.unlink(missing_ok=True)


if __name__ == "__main__":
    main()