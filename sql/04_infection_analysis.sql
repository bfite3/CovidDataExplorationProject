/*
Project: COVID-19 Global Data Analysis
Script: 04_infection_analysis.sql

Purpose:
Analyze reported COVID-19 cases relative to population
across countries and reporting dates.

Source:
dbo.CovidDeaths

Analysis:
- Calculate cumulative reported cases as a percentage
  of population for each available reporting date.
- Identify each country's latest reported cumulative
  case observation.
- Compare country-level case totals relative
  to population.

Methodology:
- Exclude aggregate locations without a continent.
- Use NULLIF() to prevent division by zero.
- Use ROW_NUMBER() to identify the latest available
  cumulative case observation for each country.

Notes:
- Cumulative reported cases may include reinfections.
- Case counts relative to population do not represent
  the percentage of unique individuals infected.
- Countries may have different final reporting dates.
- Missing measurements are not treated as zero.
*/


USE CovidPortfolioProject;
GO

/*
Query 1: Reported Cases Relative to Population

Calculate cumulative reported COVID-19 cases as a percentage
of each country's population across all reporting dates.
*/

SELECT cd.iso_code
,cd.location
,cd.[date]
,cd.population
,cd.total_cases
,CAST(
    (cd.total_cases / NULLIF(cd.population, 0)) * 100
    AS DECIMAL(12, 4)
) AS reported_cases_pct_population
FROM dbo.CovidDeaths cd
WHERE cd.continent IS NOT NULL
AND cd.population > 0
ORDER BY cd.location
,cd.[date]
;


/*
Query 2: Latest Reported Case Metrics by Country

Identify each country's latest available cumulative case
observation and compare reported cases relative to population.
*/

WITH cteLatestCountryCases AS (
    SELECT cd.iso_code
    ,cd.location
    ,cd.[date]
    ,cd.population
    ,cd.total_cases
    ,ROW_NUMBER() OVER (
        PARTITION BY cd.iso_code
        ORDER BY cd.[date] DESC
    ) AS row_num
    FROM dbo.CovidDeaths cd
    WHERE cd.continent IS NOT NULL
    AND cd.population > 0
    AND cd.total_cases IS NOT NULL
)

SELECT cte_lc.iso_code
,cte_lc.location
,cte_lc.[date] AS latest_reporting_date
,cte_lc.population
,cte_lc.total_cases
,CAST(
    (cte_lc.total_cases / NULLIF(cte_lc.population, 0)) * 100
    AS DECIMAL(12, 4)
) AS reported_cases_pct_population
FROM cteLatestCountryCases cte_lc
WHERE cte_lc.row_num = 1
ORDER BY reported_cases_pct_population DESC
;