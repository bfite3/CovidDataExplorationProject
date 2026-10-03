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