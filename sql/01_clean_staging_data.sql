/*
Project: COVID-19 Global Data Analysis
Script: 01_clean_staging_data.sql

Purpose:
Clean imported COVID-19 records and create a staging
dataset suitable for downstream analytical processing.

Source:
staging.CovidRaw

Output:
staging.CovidClean

Methodology:
- Group records by ISO code, location, and date.
- Merge complementary duplicate records using MAX().
- Preserve NULL values when measurements are unavailable.
- Retain the original imported data without modification.

Notes:
- Duplicate groups were checked for conflicting
  non-NULL numeric values before this transformation.
- Assumes duplicate records do not contain conflicting
  non-NULL continent values.
- Existing cleaned staging data is replaced on execution.
*/

USE CovidPortfolioProject;
GO

DROP TABLE IF EXISTS staging.CovidClean;
GO

SELECT cr.iso_code
,cr.location
,cr.[date]
,MAX(cr.continent) AS continent
,MAX(cr.population) AS population
,MAX(cr.total_cases) AS total_cases
,MAX(cr.new_cases) AS new_cases
,MAX(cr.total_deaths) AS total_deaths
,MAX(cr.new_deaths) AS new_deaths
,MAX(cr.new_vaccinations) AS new_vaccinations
,MAX(cr.total_vaccinations) AS total_vaccinations
INTO staging.CovidClean
FROM staging.CovidRaw cr
GROUP BY
cr.iso_code,
cr.location,
cr.[date];
GO