/*
Project: COVID-19 Global Data Analysis
Script: 07_create_dashboard_views.sql

Purpose:
Create reusable, Tableau-ready SQL views for
COVID-19 case, mortality, and vaccination analysis.

Sources:
- dbo.CovidDeaths
- dbo.CovidVaccinations

Outputs:
- dbo.vw_CovidCountryDaily
- dbo.vw_CovidCountryLatest
- dbo.vw_CovidVaccinationTrends

Notes:
- Excludes aggregate locations without a continent.
- Preserves missing measurements rather than replacing
  them with zero.
- Uses reported cumulative vaccination totals instead
  of calculated running totals for dashboard metrics.
*/

USE CovidPortfolioProject;
GO

/*
View 1: Country Vaccination Trends

Combine country population with reported vaccination
data and calculate doses administered per 100 residents.
*/

CREATE OR ALTER VIEW dbo.vw_CovidVaccinationTrends
AS

SELECT cd.iso_code
,cd.continent
,cd.location
,cd.[date]
,cd.population
,cv.new_vaccinations
,cv.total_vaccinations
,CAST(
    (cv.total_vaccinations / NULLIF(cd.population, 0)) * 100
    AS DECIMAL(18, 4)
) AS reported_doses_per_100
FROM dbo.CovidDeaths cd
INNER JOIN dbo.CovidVaccinations cv
ON cd.iso_code = cv.iso_code
AND cd.location = cv.location
AND cd.[date] = cv.[date]
WHERE cd.continent IS NOT NULL
AND cd.population > 0
;
GO

/*
View 2: Combined Country-Level Daily COVID Metrics

Provide historical case, mortality, and vaccination
metrics with each country's latest available case
and death reporting dates.
*/

CREATE OR ALTER VIEW dbo.vw_CovidCountryDaily
AS

WITH cteLatestDeathDate AS (
    SELECT cd.iso_code
    ,MAX(cd.[date]) AS latest_deaths_date
    FROM dbo.CovidDeaths cd
    WHERE cd.total_deaths IS NOT NULL
    GROUP BY cd.iso_code
)

SELECT cd.iso_code
,cd.continent
,cd.location
,cd.[date]
,cd.population
,cd.new_cases
,cd.total_cases
,cd.new_deaths
,cd.total_deaths
,cte_ld.latest_deaths_date
,cv.new_vaccinations
,cv.total_vaccinations
,CAST(
    (cd.total_cases / NULLIF(cd.population, 0)) * 100
    AS DECIMAL(18, 4)
) AS reported_cases_pct_population
,CAST(
    (cd.total_deaths / NULLIF(cd.total_cases, 0)) * 100
    AS DECIMAL(18, 4)
) AS reported_case_fatality_pct
,CAST(
    (cd.total_deaths / NULLIF(cd.population, 0)) * 100
    AS DECIMAL(18, 4)
) AS reported_deaths_pct_population
FROM dbo.CovidDeaths cd
LEFT JOIN dbo.CovidVaccinations cv
ON cd.iso_code = cv.iso_code
AND cd.location = cv.location
AND cd.[date] = cv.[date]
LEFT JOIN cteLatestDeathDate cte_ld
ON cd.iso_code = cte_ld.iso_code
WHERE cd.continent IS NOT NULL
AND cd.population > 0
;
GO

/*
View 3: Latest Country-Level COVID Metrics

Retrieve each country's latest available case and death
observations independently for country comparisons.
*/

CREATE OR ALTER VIEW dbo.vw_CovidCountryLatest
AS

WITH cteLatestCountryPopulation AS (
    SELECT cd.iso_code
    ,cd.continent
    ,cd.location
    ,cd.population
    ,ROW_NUMBER() OVER (
        PARTITION BY cd.iso_code
        ORDER BY cd.[date] DESC
    ) AS row_num
    FROM dbo.CovidDeaths cd
    WHERE cd.continent IS NOT NULL
    AND cd.population > 0
)
,cteLatestCountryCases AS (
    SELECT cd.iso_code
    ,cd.[date]
    ,cd.total_cases
    ,ROW_NUMBER() OVER (
        PARTITION BY cd.iso_code
        ORDER BY cd.[date] DESC
    ) AS row_num
    FROM dbo.CovidDeaths cd
    WHERE cd.continent IS NOT NULL
    AND cd.total_cases IS NOT NULL
)
,cteLatestCountryDeaths AS (
    SELECT cd.iso_code
    ,cd.[date]
    ,cd.total_deaths
    ,ROW_NUMBER() OVER (
        PARTITION BY cd.iso_code
        ORDER BY cd.[date] DESC
    ) AS row_num
    FROM dbo.CovidDeaths cd
    WHERE cd.continent IS NOT NULL
    AND cd.total_deaths IS NOT NULL
)

SELECT cte_lp.iso_code
,cte_lp.continent
,cte_lp.location
,cte_lp.population
,cte_lc.[date] AS latest_cases_date
,cte_lc.total_cases
,cte_ld.[date] AS latest_deaths_date
,cte_ld.total_deaths
,CAST(
    (cte_lc.total_cases / NULLIF(cte_lp.population, 0)) * 100
    AS DECIMAL(18, 4)
) AS reported_cases_pct_population
,CAST(
    (cte_ld.total_deaths / NULLIF(cte_lp.population, 0)) * 100
    AS DECIMAL(18, 4)
) AS reported_deaths_pct_population
FROM cteLatestCountryPopulation cte_lp
LEFT JOIN cteLatestCountryCases cte_lc
ON cte_lp.iso_code = cte_lc.iso_code
AND cte_lc.row_num = 1
LEFT JOIN cteLatestCountryDeaths cte_ld
ON cte_lp.iso_code = cte_ld.iso_code
AND cte_ld.row_num = 1
WHERE cte_lp.row_num = 1
;
GO
