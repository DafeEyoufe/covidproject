-- FIRST TO CHECK IF WE GRABBED THE RIGHT SET OF DATA

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Looking at Total Cases against Total Deaths
--Shows likelihood of dying if you contract Covid in Nigeria by 30th April 2021. 
SELECT location, date, total_cases, total_deaths,(total_deaths/total_cases) * 100 as Death_Rate  
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Nigeria%'
ORDER BY 1,2

--Looking at Total Cases against Population
--Shows percentage of population contracted Covid 
SELECT location, date, population, total_cases, (total_cases/population) * 100 as Population_percentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Nigeria%'
ORDER BY 1,2

--To check countries with highest infection rate compared to population.
SELECT location, population, date, MAX(total_cases) as Highest_Infection_Count, MAX((total_cases/population)) * 100 as Population_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY  location, date, population
ORDER BY Population_percentage DESC
 

--To check countries with highest death count compared to population.
SELECT location, population, MAX(CAST(total_deaths AS int)) as Total_Death_Count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY LOCATION, population
ORDER BY Total_Death_Count DESC 


--To check continents total death count.
SELECT location, SUM(CAST(new_deaths AS int)) as Total_Death_Count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL 
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location 
ORDER BY Total_Death_Count DESC

--To check countries with the highest infections in Africa
SELECT location, population, MAX(CAST(total_cases as int)) as Total_Cases
FROM PortfolioProject..CovidDeaths
WHERE continent like '%Africa%'
GROUP BY location, population 
ORDER BY Total_Cases DESC


--Global Numbers

--To show the total death percentage against cases.
SELECT  SUM(NEW_CASES) AS Total_Cases, SUM(CAST(new_deaths as int)) as Total_Deaths, SUM(CAST(new_deaths as int))/SUM(NEW_CASES)*100 AS Death_Percentage  
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


--To show the aggregate daily vaccination count.
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
, SUM(CONVERT(INT, VAC.new_vaccinations)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS Daily_Aggregate
FROM PortfolioProject..CovidDeaths DEA
JOIN PortfolioProject..CovidVaccinations VAC
    ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL
ORDER BY 2,3


--To be able to query the Daily_Aggregate we use either a CTE or a temp table

--Using CTE
WITH PopVsVac (continent, location, date, population, new_vaccinations, Daily_Aggregate)
AS
(
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
, SUM(CONVERT(INT, VAC.new_vaccinations)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS Daily_Aggregate
FROM PortfolioProject..CovidDeaths DEA
JOIN PortfolioProject..CovidVaccinations VAC
    ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL
)

SELECT *, (Daily_Aggregate/population)*100 AS Daily_Aggregate_Percentage
FROM PopVsVac


--Using Temp Tables

DROP TABLE IF EXISTS #PercentageVaccinated
CREATE TABLE #PercentageVaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Daily_Aggregate numeric
)

INSERT INTO #PercentageVaccinated
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
, SUM(CONVERT(INT, VAC.new_vaccinations)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS Daily_Aggregate
FROM PortfolioProject..CovidDeaths DEA
JOIN PortfolioProject..CovidVaccinations VAC
    ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL

SELECT *, (Daily_Aggregate/population)*100 AS Daily_Aggregate_Percentage
FROM #PercentageVaccinated


--Now to create views for visualizations

CREATE VIEW Daily_Aggregate AS
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
, SUM(CONVERT(INT, VAC.new_vaccinations)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS Daily_Aggregate
FROM PortfolioProject..CovidDeaths DEA
JOIN PortfolioProject..CovidVaccinations VAC
    ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL



--1

SELECT  SUM(NEW_CASES) AS Total_Cases, SUM(CAST(new_deaths as int)) as Total_Deaths, SUM(CAST(new_deaths as int))/SUM(NEW_CASES)*100 AS Death_Percentage  
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

--2

SELECT location, SUM(CAST(new_deaths AS int)) as Total_Death_Count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL 
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location 
ORDER BY Total_Death_Count DESC

--3

SELECT location, population, MAX(total_cases) as Highest_Infection_Count, MAX((total_cases/population)) * 100 as Population_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Population_percentage DESC

--4
SELECT location, population, date, MAX(total_cases) as Highest_Infection_Count, MAX((total_cases/population)) * 100 as Population_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY  location, date, population
ORDER BY Population_percentage DESC