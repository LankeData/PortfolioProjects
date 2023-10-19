
/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM covid_smrt
WHERE continent is not null 
ORDER BY 3,4

-- Select Data that we are going to be starting with

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM covid_smrt
WHERE continent is not null 
ORDER BY 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT Location, date, total_cases,total_deaths, (total_deaths/CONVERT(float, total_cases)) *100 AS DeathPercentage
FROM covid_smrt
WHERE location = 'Serbia'
AND continent IS NOT NULL 
ORDER BY 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT Location, date, Population, total_cases,  (total_cases/population)*100 AS PercentPopulationInfected
FROM covid_smrt
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(CONVERT( int, total_cases)) AS HighestInfectionCount,  Max((total_cases/population))*100 AS PercentPopulationInfected
FROM covid_smrt
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC


-- Countries with Highest Death Count

SELECT Location, MAX(CAST(Total_deaths as int)) AS TotalDeathCount
FROM covid_smrt
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT continent, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM covid_smrt
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC



-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 AS DeathPercentage
FROM covid_smrt
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine


--USING CTE
WITH VakPerPop (continent, location, date, population, new_vaccinations, VaccinationsCountingPerDate)
AS
(
SELECT smr.continent, smr.location, smr.date, smr.population, vak.new_vaccinations,
SUM(CONVERT(float, vak.new_vaccinations)) OVER (PARTITION BY smr.location ORDER BY smr.location, smr.date) AS VaccinationsCountingPerDate 
FROM covid_smrt smr
JOIN covid_vakcinacija vak
ON smr.location = vak.location AND smr.date = vak.date
WHERE smr.continent IS NOT NULL AND smr.location = 'Serbia'
)
SELECT *, (VaccinationsCountingPerDate/population) * 100 AS PercentagePeopleVacc
FROM VakPerPop

-- USING TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
PercentagePeopleVacc numeric
)

Insert into #PercentPopulationVaccinated
SELECT smr.continent, smr.location, smr.date, smr.population, vak.new_vaccinations,
SUM(CONVERT(float, vak.new_vaccinations)) OVER (PARTITION BY smr.location ORDER BY smr.location, smr.date) AS VaccinationsCountingPerDate 
FROM covid_smrt smr
JOIN covid_vakcinacija vak
ON smr.location = vak.location AND smr.date = vak.date
WHERE smr.continent IS NOT NULL AND smr.location = 'Serbia'

Select *, (PercentagePeopleVacc/Population)*100
From #PercentPopulationVaccinated

--Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT smr.continent, smr.location, smr.date, smr.population, vak.new_vaccinations,
SUM(CONVERT(float, vak.new_vaccinations)) OVER (PARTITION BY smr.location ORDER BY smr.location, smr.date) AS VaccinationsCountingPerDate 
FROM covid_smrt smr
JOIN covid_vakcinacija vak
ON smr.location = vak.location AND smr.date = vak.date
WHERE smr.continent IS NOT NULL 
