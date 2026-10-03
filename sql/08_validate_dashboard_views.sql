/*
Project: COVID-19 Global Data Analysis
Script: 08_validate_dashboard_views.sql

Purpose:
Validate the accuracy and structural integrity
of Tableau-ready COVID-19 dashboard views.

Sources:
- dbo.vw_CovidCountryDaily
- dbo.vw_CovidCountryLatest
- dbo.vw_CovidVaccinationTrends

Validation:
- Compare historical view record counts.
- Verify country-level uniqueness.
- Inspect the latest available reporting dates.

Notes:
- This script is read-only.
- Execute after 07_create_dashboard_views.sql.
- Validation results support dashboard reliability.
*/

SELECT 'CountryDaily' AS view_name
,COUNT(*) AS total_records
FROM dbo.vw_CovidCountryDaily vcd

UNION ALL

SELECT 'CountryLatest'
,COUNT(*)
FROM dbo.vw_CovidCountryLatest vcl

UNION ALL

SELECT 'VaccinationTrends'
,COUNT(*)
FROM dbo.vw_CovidVaccinationTrends vvt
;


/*
Validation: Latest Country View Uniqueness

Verify that each ISO code appears only once.
*/

SELECT vcl.iso_code
,COUNT(*) AS record_count
FROM dbo.vw_CovidCountryLatest vcl
GROUP BY vcl.iso_code
HAVING COUNT(*) > 1
;


/*
Validation: Latest Country Reporting Dates

Inspect the latest available case and death
observations for selected countries.
*/

SELECT vcl.iso_code
,vcl.location
,vcl.latest_cases_date
,vcl.total_cases
,vcl.latest_deaths_date
,vcl.total_deaths
FROM dbo.vw_CovidCountryLatest vcl
WHERE vcl.location IN (
    'United States'
    ,'Afghanistan'
    ,'Sweden'
    ,'Denmark'
)
ORDER BY vcl.location
;