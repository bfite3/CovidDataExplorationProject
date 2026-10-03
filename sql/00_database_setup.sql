/*
Project: COVID-19 Global Data Analysis
Script: 00_database_setup.sql

Purpose:
Initialize the SQL Server database and staging schema
required for the COVID-19 data pipeline.

Outputs:
- CovidPortfolioProject database
- staging schema

Execution Order:
1. Run this script to initialize the database.
2. Execute the Python ingestion script to load raw data
   into staging.CovidRaw.
3. Run 01_clean_staging_data.sql to clean the source data.
4. Run 02_create_analytical_tables.sql to create the
   analytical tables.

Notes:
- Designed for Microsoft SQL Server.
- Uses a separate staging schema to distinguish
  imported source data from analytical tables.
- Database initialization is required only once,
  unless the database is recreated.
*/


IF DB_ID('CovidPortfolioProject') IS NULL
BEGIN
    CREATE DATABASE CovidPortfolioProject;
END;
GO

USE CovidPortfolioProject;
GO

SELECT DB_NAME() AS CurrentDatabase;

USE CovidPortfolioProject;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'staging'
)
BEGIN
    EXEC('CREATE SCHEMA staging');
END;
GO