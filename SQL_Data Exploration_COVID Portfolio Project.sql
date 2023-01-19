/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/




-- View all columns and tables of the data

SELECT *
FROM PortfolioProject..CovidDeath
WHERE continent is not null
Order by 3,4

SELECT *
FROM PortfolioProject..CovidVaccination
WHERE continent is not null
Order by 3,4




-- Select data to be starting with
-- from CovidDeath
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeath
WHERE continent is not null
Order by 1,2




-- Total Cases VS Total Deaths
-- Shows likelihood of dying if contracted covid in Malaysia

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeath
WHERE location = 'Malaysia'
Order by 1,2

-- in percentage

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeath
WHERE location = 'Malaysia'
and continent is not null
Order by 1,2




-- Total Cases VS Population
-- Shows percentage of population infected with Covid in Malaysia

SELECT Location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeath
WHERE location = 'Malaysia'
and continent is not null
Order by 1,2




-- Countries with highest infection rate compared to population

SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeath
--WHERE location = 'Malaysia'
Group by location, population
Order by PercentPopulationInfected desc




-- Countries with highest count of deaths per population

SELECT Location, MAX(cast(Total_Deaths as int))/*need to convert or cast total_deaths column to int*/ as TotalDeathCount
FROM PortfolioProject..CovidDeath
WHERE continent is not null /*to avoid continent to be counted too*/
Group by location
Order by TotalDeathCount desc




-- Continents with highest count of deaths per population

/*SELECT continent, MAX(cast(Total_Deaths as int))/*need to convert or cast total_deaths column to int*/ as TotalDeathCount
FROM PortfolioProject..CovidDeath
WHERE continent is not null 
Group by continent
Order by TotalDeathCount desc*/

SELECT location, MAX(cast(Total_Deaths as int))/*need to convert or cast total_deaths column to int*/ as TotalDeathCount
FROM PortfolioProject..CovidDeath
WHERE continent is null /*to avoid continent to be counted too*/
Group by location
Order by TotalDeathCount desc




-- Death percentage of global numbers
-- ordered by date for all countries
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeath
where continent is not null 
Group By date
order by 1,2

-- death percentage for all countries
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeath
where continent is not null 
--Group By date
order by 1,2




-- Total Population vs Vaccinations
-- Total amount of people in the world that have been vaccinated

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProject..CovidDeath dea
Join PortfolioProject..CovidVaccination vac /* joined on location and date*/
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- roling count or add up count
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) /*(CONVERT(int, vac.new_vaccinations))*/ OVER (Partition by dea.location Order by dea.location, dea.date) /*breaking it up by location; count will start over when new location*/ as RollingPeopleVaccinated
From PortfolioProject..CovidDeath dea
Join PortfolioProject..CovidVaccination vac /* joined on location and date*/
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Use CTE to perform calculation on Partition By in previous query (to find percentage)

With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) /*(CONVERT(int, vac.new_vaccinations))*/ OVER (Partition by dea.location Order by dea.location, dea.date) /*breaking it up by location; count will start over when new location*/ as RollingPeopleVaccinated
From PortfolioProject..CovidDeath dea
Join PortfolioProject..CovidVaccination vac /* joined on location and date*/
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac




-- Using Temp Table to perform calculation on Partition By in previous query (to find percentage)

DROP TABLE if exists #PercentPopulationVaccinated /*add this for future alterations in the table; dont have to delete the temp table rapidly*/

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)


INSERT INTO #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeath dea
Join PortfolioProject..CovidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating view to store date for later vizualizations

CREATE VIEW ContinentDeathCountperPopulation as
SELECT continent, MAX(cast(Total_Deaths as int))/*need to convert or cast total_deaths column to int*/ as TotalDeathCount
FROM PortfolioProject..CovidDeath
WHERE continent is not null 
Group by continent
--Order by TotalDeathCount desc


