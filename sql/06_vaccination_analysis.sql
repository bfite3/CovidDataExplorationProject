/*
Project: COVID-19 Global Data Analysis
Script: 06_vaccination_analysis.sql

Purpose:
Analyze reported COVID-19 vaccination activity
and cumulative vaccine doses across countries.

Sources:
- dbo.CovidDeaths
- dbo.CovidVaccinations

Analysis:
- Examine daily reported vaccination doses.
- Calculate running totals using window functions.
- Compare calculated totals with reported cumulative data.

Notes:
- Vaccination counts represent doses, not unique people.
- Missing observations are not treated as zero.
- Reporting frequency varies by location.
*/

USE CovidPortfolioProject;
GO

/*
Query 1: Daily Vaccinations and Running Total

Join vaccination data with country information and
calculate cumulative reported doses using SUM() OVER().
*/

SELECT cd.iso_code
,cd.location
,cd.[date]
,cd.population
,cv.new_vaccinations
,SUM(cv.new_vaccinations) OVER (
    PARTITION BY cd.iso_code
    ORDER BY cd.[date]
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS calculated_cumulative_doses
FROM dbo.CovidDeaths cd
INNER JOIN dbo.CovidVaccinations cv
ON cd.iso_code = cv.iso_code
AND cd.location = cv.location
AND cd.[date] = cv.[date]
WHERE cd.continent IS NOT NULL
ORDER BY cd.location
,cd.[date]
;


/*
Query 2: Calculated vs. Reported Vaccination Totals

Compare the running sum of reported daily doses
with the source's reported cumulative dose totals.
*/

WITH cteVaccinationTotals AS (
    SELECT cd.iso_code
    ,cd.location
    ,cd.[date]
    ,cv.new_vaccinations
    ,cv.total_vaccinations
    ,SUM(cv.new_vaccinations) OVER (
        PARTITION BY cd.iso_code
        ORDER BY cd.[date]
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS calculated_cumulative_doses
    FROM dbo.CovidDeaths cd
    INNER JOIN dbo.CovidVaccinations cv
        ON cd.iso_code = cv.iso_code
        AND cd.location = cv.location
        AND cd.[date] = cv.[date]
    WHERE cd.continent IS NOT NULL
)

SELECT cte_vt.iso_code
,cte_vt.location
,cte_vt.[date]
,cte_vt.new_vaccinations
,cte_vt.total_vaccinations
,cte_vt.calculated_cumulative_doses
,cte_vt.calculated_cumulative_doses - cte_vt.total_vaccinations AS dose_difference
FROM cteVaccinationTotals cte_vt
WHERE cte_vt.total_vaccinations IS NOT NULL
AND cte_vt.location = 'United States'
ORDER BY cte_vt.location
,cte_vt.[date]
;


/*
Validation: United States Vaccination Reporting

Inspect source vaccination values to identify gaps
and understand differences between daily and
cumulative reporting.
*/

SELECT TOP (30) cv.iso_code
,cv.location
,cv.[date]
,cv.new_vaccinations
,cv.total_vaccinations
FROM dbo.CovidVaccinations cv
WHERE cv.location = 'United States'
AND (
    cv.new_vaccinations IS NOT NULL
    OR cv.total_vaccinations IS NOT NULL
)
ORDER BY cv.[date] DESC
;


/*
Validation: Vaccination Reporting Completeness

Identify countries with missing daily vaccination
observations despite having cumulative vaccination data.
*/

SELECT cv.iso_code
,cv.location
,COUNT(*) AS total_records
,COUNT(cv.new_vaccinations) AS reported_daily_records
,COUNT(cv.total_vaccinations) AS reported_cumulative_records
,SUM(
    CASE
        WHEN cv.new_vaccinations IS NULL
        AND cv.total_vaccinations IS NOT NULL
        THEN 1
        ELSE 0
    END
) AS missing_daily_with_cumulative
FROM dbo.CovidVaccinations cv
INNER JOIN dbo.CovidDeaths cd
ON cv.iso_code = cd.iso_code
AND cv.location = cd.location
AND cv.[date] = cd.[date]
WHERE cd.continent IS NOT NULL
GROUP BY cv.iso_code
,cv.location
HAVING COUNT(cv.total_vaccinations) > 0
ORDER BY missing_daily_with_cumulative DESC
;


/*
Query 3: Vaccination Reporting Completeness

Summarize daily vaccination reporting coverage
among observations with reported cumulative totals.
*/

WITH cteVaccinationCompleteness AS (
    SELECT cv.iso_code
    ,cv.location
    ,COUNT(cv.total_vaccinations) AS cumulative_observations
    ,SUM(
        CASE
            WHEN cv.total_vaccinations IS NOT NULL
            AND cv.new_vaccinations IS NULL
            THEN 1
            ELSE 0
        END
    ) AS missing_daily_observations
    FROM dbo.CovidVaccinations cv
    INNER JOIN dbo.CovidDeaths cd
    ON cv.iso_code = cd.iso_code
    AND cv.location = cd.location
    AND cv.[date] = cd.[date]
    WHERE cd.continent IS NOT NULL
    GROUP BY cv.iso_code
    ,cv.location
)

SELECT COUNT(*) AS countries_with_cumulative_data
,SUM(cte_vc.cumulative_observations) AS cumulative_observations
,SUM(cte_vc.missing_daily_observations) AS missing_daily_observations
,CAST(
    SUM(cte_vc.missing_daily_observations) * 100.0
    / NULLIF(SUM(cte_vc.cumulative_observations), 0)
    AS DECIMAL(12, 2)
) AS missing_daily_pct
FROM cteVaccinationCompleteness cte_vc
WHERE cte_vc.cumulative_observations > 0
;