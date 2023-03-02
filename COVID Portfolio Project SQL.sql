SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--Select data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

--Looking at Total Cases vs Total Deaths
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Location LIKE '%state%s'
ORDER BY 1, 2

--Looking at total cases vs Population
SELECT Location, date, population, total_cases, (total_cases/population)*100 AS PercentageofPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 1, 2

--Looking at countries with highest infection rate compared to population
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)*100) as PercentagePopulationInfected
FROM PortfolioProject..CovidDeaths
Group by location, population
Order by PercentagePopulationInfected DESC

--Looking at countries with highest death count per population
SELECT location, MAX(cast (total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
Group by location
Order by TotalDeathCount DESC

--Total death count by continent
SELECT continent, MAX(cast (total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
Group by continent
Order by TotalDeathCount DESC

--Global Numbers
SELECT date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2



--Looking at total population vs new vaccinations
--JOIN
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	Order by 2, 3

--Next, we want to take the above query and now start adding up the new vaccines in a new column
--PARTITION BY
--CAST
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,  SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.location
ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	Order by 2, 3

--CTE, find how many people in each country are vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,  SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.location
ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	Order by 2, 3

--CTE
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,  SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.location
ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--Order by 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

--TEMP TABLE
DROP TABLE if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,  SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.location
ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--Order by 2, 3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

--CREATE A VIEW
--for example, looking at Continent and TotalDeathCount 
USE PortfolioProject
GO
Create View PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,  
	SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.location
	ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--Order by 2, 3


--Create a VIEW To Look at % of Population Deaths Vs People Vaccinated
USE PortfolioProject
GO
CREATE VIEW PercentageDeathsVsVaccinated as
SELECT dea.location, dea.date, dea.population, dea.total_deaths, vac.total_vaccinations, SUM(Cast(dea.total_deaths as bigint)) OVER (Partition by dea.location
	ORDER BY dea.location, dea.date) AS DeathPercentage, SUM(Cast(vac.total_vaccinations as int)) OVER (Partition by dea.location
	ORDER BY dea.location, dea.date) AS VaccinatedPercentage
--(dea.total_deaths/dea.population)*100 AS DeathPercentage, 
--(vac.total_vaccinations/dea.population)*100 AS VaccinatedPercentage
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	--WHERE dea.continent IS NOT NULL


--VIEW of Rolling Deaths per Population
USE PortfolioProject
GO
CREATE VIEW RollingDeathsPerPopulation AS
SELECT location, date, population, total_deaths, SUM(Cast(total_deaths as int)) OVER (PARTITION BY location ORDER BY location, date) as RollingDeaths
FROM PortfolioProject..CovidDeaths
--Order by 2,3

--Create a VIEW To Look at Total Deaths and Diabetes Prevelance, Cardiovasc Death Rate, and Extreme Poverty
USE PortfolioProject
GO
CREATE VIEW DeathsAndHealthFactors3 AS
SELECT dea.location, dea.population, dea.total_deaths, vac.cardiovasc_death_rate, vac.diabetes_prevalence, vac.extreme_poverty
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location

SELECT *
FROM DeathsAndHealthFactors3

