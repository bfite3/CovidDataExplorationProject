/*
Project: COVID-19 Global Data Analysis
Script: 02_create_analytical_tables.sql

Purpose:
Create separate analytical tables containing COVID-19
case, death, and vaccination data.

Source:
staging.CovidClean

Outputs:
- dbo.CovidDeaths
- dbo.CovidVaccinations

Notes:
- Requires the cleaned staging table to exist.
- Both analytical tables retain location and date
  identifiers to support subsequent joins.
- Existing analytical tables are dropped and recreated
  whenever this script runs.
- Execute after 01_clean_staging_data.sql.
*/

USE CovidPortfolioProject;
GO

DROP TABLE IF EXISTS dbo.CovidDeaths;
GO

SELECT cc.iso_code
,cc.continent
,cc.location
,cc.[date]
,cc.population
,cc.total_cases
,cc.new_cases
,cc.total_deaths
,cc.new_deaths
INTO dbo.CovidDeaths
FROM staging.CovidClean cc
;
GO

DROP TABLE IF EXISTS dbo.CovidVaccinations;
GO

SELECT cc.iso_code
,cc.location
,cc.[date]
,cc.new_vaccinations
,cc.total_vaccinations
INTO dbo.CovidVaccinations
FROM staging.CovidClean cc
;
GO