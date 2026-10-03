/*
Project: COVID-19 Global Data Analysis
Script: 05_mortality_analysis.sql

Purpose:
Analyze reported COVID-19 mortality metrics across
countries and reporting dates.

Source:
dbo.CovidDeaths

Analysis:
- Calculate the reported case fatality ratio over time.
- Calculate cumulative reported deaths relative to population.
- Compare countries using their latest available observations.

Notes:
- Excludes aggregate locations without a continent.
- Missing measurements are not treated as zero.
- Reported case fatality ratios are not infection fatality rates.
*/

USE CovidPortfolioProject;
GO

/*
Query 1: Case Fatality Ratio Over Time

Calculate cumulative reported deaths as a percentage
of cumulative reported cases for each country and date.
*/

SELECT cd.iso_code
,cd.location
,cd.[date]
,cd.total_cases
,cd.total_deaths
,CAST(
    (cd.total_deaths / NULLIF(cd.total_cases, 0)) * 100
    AS DECIMAL(12, 4)
) AS reported_case_fatality_pct
FROM dbo.CovidDeaths cd
WHERE cd.continent IS NOT NULL
AND cd.total_cases > 0
ORDER BY cd.location
,cd.[date]
;



/*
Query 2: Reported Deaths Relative to Population

Calculate cumulative reported COVID-19 deaths as a
percentage of each country's population over time.
*/

SELECT cd.iso_code
,cd.location
,cd.[date]
,cd.population
,cd.total_deaths
,CAST(
    (cd.total_deaths / NULLIF(cd.population, 0)) * 100
    AS DECIMAL(12, 4)
) AS reported_deaths_pct_population
FROM dbo.CovidDeaths cd
WHERE cd.continent IS NOT NULL
AND cd.population > 0
ORDER BY cd.location
,cd.[date]
;


/*
Query 3: Latest Mortality Metrics by Country

Identify each country's latest observation containing
both cumulative cases and deaths, then calculate
case fatality and deaths relative to population.
*/

WITH cteLatestCountryMortality AS (
    SELECT cd.iso_code
    ,cd.location
    ,cd.[date]
    ,cd.population
    ,cd.total_cases
    ,cd.total_deaths
    ,ROW_NUMBER() OVER (
        PARTITION BY cd.iso_code
        ORDER BY cd.[date] DESC
    ) AS row_num
    FROM dbo.CovidDeaths cd
    WHERE cd.continent IS NOT NULL
    AND cd.population > 0
    AND cd.total_cases > 0
    AND cd.total_deaths IS NOT NULL
)

SELECT cte_lm.iso_code
,cte_lm.location
,cte_lm.[date] AS latest_reporting_date
,cte_lm.population
,cte_lm.total_cases
,cte_lm.total_deaths
,CAST(
    (cte_lm.total_deaths / NULLIF(cte_lm.total_cases, 0)) * 100
    AS DECIMAL(12, 4)
) AS reported_case_fatality_pct
,CAST(
    (cte_lm.total_deaths / NULLIF(cte_lm.population, 0)) * 100
    AS DECIMAL(12, 4)
) AS reported_deaths_pct_population
FROM cteLatestCountryMortality cte_lm
WHERE cte_lm.row_num = 1
ORDER BY reported_deaths_pct_population DESC
;


/*
Validation: United States Mortality Metrics

Inspect the underlying values for a single country
to independently verify the calculated percentages.
*/

SELECT TOP (1) cd.location
,cd.[date]
,cd.population
,cd.total_cases
,cd.total_deaths
,CAST(
    (cd.total_deaths / NULLIF(cd.total_cases, 0)) * 100
    AS DECIMAL(12, 4)
) AS reported_case_fatality_pct
,CAST(
    (cd.total_deaths / NULLIF(cd.population, 0)) * 100
    AS DECIMAL(12, 4)
) AS reported_deaths_pct_population
FROM dbo.CovidDeaths cd
WHERE cd.location = 'United States'
AND cd.population > 0
AND cd.total_cases > 0
AND cd.total_deaths IS NOT NULL
ORDER BY cd.[date] DESC
;