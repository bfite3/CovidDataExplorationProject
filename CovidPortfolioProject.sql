USE CovidPorfolioProject
go

--SELECT * FROM CovidVaccinations cv

SELECT cd.location, cd.date, cd.total_cases, cd.new_cases, cd.total_deaths, cd.population
FROM CovidDeaths cd
WHERE cd.continent IS NOT NULL
ORDER BY cd.location, cd.date


--Looking at Total Cases vs Total Deaths
--Likelihood of dying of covid in certain country
SELECT cd.location, cd.date, cd.total_cases, cd.total_deaths, (cd.total_deaths/cd.total_cases) * 100 AS death_percentage
FROM CovidDeaths cd
WHERE cd.location = 'United States'
AND cd.continent IS NOT NULL
ORDER BY cd.location, cd.date


--Looking at Total Cases vs Population
--Shows percentage of population that contracted covid in certain country
SELECT cd.location, cd.date, cd.population, cd.total_cases, (cd.total_cases/cd.population) * 100 AS population_infected_percentage
FROM CovidDeaths cd
WHERE cd.location = 'United States'
AND cd.continent IS NOT NULL
ORDER BY cd.location, cd.date


--Countries with Highest Infection Rate compared to Population

SELECT cd.location, MAX(cd.total_cases) AS infection_count, cd.population, MAX((cd.total_cases/cd.population) * 100) AS sick_percentage
FROM CovidDeaths cd
WHERE cd.continent IS NOT NULL
GROUP BY cd.location, cd.population
ORDER BY sick_percentage DESC


--Countries with Highest Death Count per Population

SELECT cd.location, MAX(CONVERT(INT, cd.total_deaths)) AS total_death_count
FROM CovidDeaths cd
WHERE cd.continent IS NOT NULL
GROUP BY cd.location
ORDER BY total_death_count DESC


--Death count per continent
SELECT cd.location, MAX(CONVERT(INT, cd.total_deaths)) AS total_death_count
FROM CovidDeaths cd
WHERE cd.continent IS NULL
AND cd.location <> 'World'
GROUP BY cd.location
ORDER BY total_death_count DESC


--Global Numbers

--New daily cases vs new daily deaths
SELECT cd.date, SUM(cd.new_cases) AS sum_new_cases, SUM(CONVERT(INT, cd.new_deaths)) AS sum_new_deaths, (SUM(CONVERT(INT, cd.new_deaths))/SUM(cd.new_cases)) *100 AS global_daily_death_percentage
FROM CovidDeaths cd
WHERE cd.continent IS NOT NULL
GROUP BY cd.date
ORDER BY cd.date, sum_new_cases



--Global death rate by date
SELECT cd.location, cd.date, cd.total_deaths, cd.total_cases, (cd.total_deaths / cd.total_cases) *100 AS global_death_percentage
FROM CovidDeaths cd
WHERE cd.location = 'World'


--Global death percentage as of last recorded date
SELECT TOP 1 cd.location, cd.date, cd.total_deaths, cd.total_cases, (cd.total_deaths / cd.total_cases) *100 AS global_death_percentage
FROM CovidDeaths cd
WHERE cd.location = 'World'
ORDER BY cd.date DESC


--New Vaccinations vs Total Vaccinations
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
,SUM(CONVERT(INT, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_total_vaccinations
FROM CovidDeaths cd
INNER JOIN CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY cd.location, cd.date


--Rolling vaccination percentage by population per country per date
WITH cte (continent, location, date, population, new_vaccinations, rolling_total_vaccinations)
AS (
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
,SUM(CONVERT(INT, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_total_vaccinations
FROM CovidDeaths cd
INNER JOIN CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL) 

SELECT *, (rolling_total_vaccinations/population) *100 AS rolling_vaccination_percentage
FROM cte


DROP TABLE IF EXISTS #tbl_tmp_rolling_vac
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
,SUM(CONVERT(INT, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_total_vaccinations
INTO #tbl_tmp_rolling_vac
FROM CovidDeaths cd
INNER JOIN CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL


--Create view for later visualization
CREATE VIEW total_death_per_continent AS
SELECT cd.location, MAX(CONVERT(INT, cd.total_deaths)) AS total_death_count
FROM CovidDeaths cd
WHERE cd.continent IS NULL
AND cd.location <> 'World'
GROUP BY cd.location
