/*
Project: COVID-19 Global Data Analysis
Script: 03_validate_analytical_tables.sql

Purpose:
Validate the integrity of the cleaned COVID-19
analytical tables before performing exploratory analysis.

Sources:
- staging.CovidClean
- dbo.CovidDeaths
- dbo.CovidVaccinations

Validation:
- Compare record counts across analytical tables.
- Verify the uniqueness of location and date keys.
- Identify duplicate analytical records.
- Verify joins between deaths and vaccination data
  do not unexpectedly multiply or exclude records.

Notes:
- This script is read-only.
- Execute after rebuilding the analytical tables.
- Validation results establish confidence in the
  datasets used for subsequent analysis.
*/

USE CovidPortfolioProject;
GO

SELECT 'CovidClean' AS table_name
,COUNT(*) AS total_rows
,COUNT(DISTINCT CONCAT(cc.iso_code, '|', CONVERT(VARCHAR(10), cc.[date], 23))) AS unique_keys
FROM staging.CovidClean cc

UNION ALL

SELECT 'CovidDeaths'
,COUNT(*)
,COUNT(DISTINCT CONCAT(cd.iso_code, '|', CONVERT(VARCHAR(10), cd.[date], 23)))
FROM dbo.CovidDeaths cd

UNION ALL

SELECT 'CovidVaccinations'
,COUNT(*)
,COUNT(DISTINCT CONCAT(cv.iso_code, '|', CONVERT(VARCHAR(10), cv.[date], 23)))
FROM dbo.CovidVaccinations cv
;


SELECT cd.iso_code
,cd.location
,cd.[date]
,COUNT(*) AS record_count
FROM dbo.CovidDeaths cd
GROUP BY cd.iso_code
,cd.location
,cd.[date]
HAVING COUNT(*) > 1;


SELECT cv.iso_code
,cv.location
,cv.[date]
,COUNT(*) AS record_count
FROM dbo.CovidVaccinations cv
GROUP BY cv.iso_code
,cv.location
,cv.[date]
HAVING COUNT(*) > 1
;


SELECT COUNT(*) AS joined_rows
FROM dbo.CovidDeaths d
INNER JOIN dbo.CovidVaccinations v
ON d.iso_code = v.iso_code
AND d.location = v.location
AND d.[date] = v.[date];