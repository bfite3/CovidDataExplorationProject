"""
Provide reusable SQL Server connections for
the COVID-19 data pipeline.
"""

import os

import pyodbc


def get_connection(
    database: str = "CovidPortfolioProject",
    autocommit: bool = False,
) -> pyodbc.Connection:
    """
    Create a SQL Server connection using
    environment-based configuration.
    """

    server = os.environ.get("COVID_SQL_SERVER")

    if not server:
        raise ValueError(
            "COVID_SQL_SERVER environment variable is not configured."
        )

    preferred_drivers = [
        "ODBC Driver 18 for SQL Server",
        "ODBC Driver 17 for SQL Server",
    ]

    installed_drivers = pyodbc.drivers()

    driver = next(
        (name for name in preferred_drivers if name in installed_drivers),
        None
    )

    if not driver:
        raise RuntimeError(
            "Microsoft ODBC Driver 17 or 18 for SQL Server is required."
        )

    connection_string = (
        f"DRIVER={{{driver}}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        "Trusted_Connection=yes;"
        "TrustServerCertificate=yes;"
    )

    return pyodbc.connect(
        connection_string,
        autocommit=autocommit
    )