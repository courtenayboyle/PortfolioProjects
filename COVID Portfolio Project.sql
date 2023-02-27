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
--Shows the likelihood of dying if you contract COVID in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Location LIKE '%state%s'
ORDER BY 1, 2

--Looking at total cases vs Population
--Shows that percentage of population got COVID
SELECT Location, date, population, total_cases, (total_cases/population)*100 AS PercentageofPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 1, 2

--Looking at countries with highest infection rate compared to population
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentagePopulationInfected
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

--Global Numbers- will give us the total new cases for each day across the world; filtering by date. 
--Must use the cast command b/c in the table, the new_deaths is inputted as a varchar and we need it to be as an int to query properly
SELECT date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2
--if you remove the date and group by date, then the query will return OVERALL total cases, total deaths and the death percentage.


--Looking at total population vs new vaccinations; tables are JOINED. 
--must specify which table to pull [date] from b/c there are dates in both tables
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	Order by 2, 3

--Next, we want to take the above query and now start adding up the new vaccines in a new column
--must use partition by [location] b/c if we are doing it by continent the numbers would be totally off. Also, every time the vaccine count gets to a
--new number we want to count to start over- not just keep adding up.
--SUM(Cast(vac.new_vaccinations as int)) is the same code as: SUM(CONVERT(int, vac.new_vaccinations))
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,  SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.location
ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	Order by 2, 3

--Next, we want to take the max number of RollingPeopleVaccinated (from above), so the max number of people vaccinated per location, and we want to 
--divide that number by the total population to find out how many  in that country are vaccinated
--So to be able take the max ROllingPeopleVaccinated number, from the column we just created, we need to either create a temp table or a CTE to be able to 
--to the math and find out how many are vaccinated in each country

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,  SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.location
ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	Order by 2, 3

--Use CTE. Remember the number of CTE columns (top line) must have the same number of columns as the SELECT line

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

--if you want to change something in your TEMP TABLE, you can code (first line)
--DROP TABLE if exists #PercentPopulationVaccinated
--then when it runs it can replace the previous version and you can now run multiple times.



--CREATE A VIEW: to store data for later visualizations
--for example, look at Continent and TotalDeathCount (do it for multiple things)

USE PortfolioProject
GO
Create View PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,  SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.location
ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--Order by 2, 3

SELECT *
FROM PercentPopulationVaccinated