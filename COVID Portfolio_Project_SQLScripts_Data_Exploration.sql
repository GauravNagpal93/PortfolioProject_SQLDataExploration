--SELECT *
--FROM [Portfolio Project]..Covid_Deaths
--ORDER BY 3,4


----Data that we are going to be using

SELECT Location, date, total_cases,new_cases,total_deaths,population
FROM [Portfolio Project]..Covid_Deaths
WHERE continent is not null 
ORDER BY 1,2

-- Looking at Total_Cases vs Total_Deaths
-- Shows the likelihood of dying if you contact covid in your country
SELECT Location, date, total_cases, CAST(total_deaths as int) as total_deaths, (CAST(total_deaths as int)/total_cases)*100 AS DeathPercent
FROM [Portfolio Project]..Covid_Deaths
WHERE location LIKE '%Canada%'
AND total_cases IS NOT NULL
ORDER BY 1,2

-- Looking at Total_Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT Location, date, population, total_cases, (total_cases/population)*100 AS PopulationInfectedPercent
FROM [Portfolio Project]..Covid_Deaths
WHERE location LIKE '%Canada%'
AND total_cases IS NOT NULL
ORDER BY 1,2

-- Looking at countries with Highest Infection Rate compared to Population
SELECT Location, MAX(total_cases) AS HighestInfectionCount, population, MAX((total_cases/population))*100 AS PopulationInfectedPercent
FROM [Portfolio Project]..Covid_Deaths
--WHERE location LIKE '%Canada%'
GROUP BY location, population
ORDER BY PopulationInfectedPercent desc

-- Showing the countries with Highest Death Count per Population
SELECT Location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM [Portfolio Project]..Covid_Deaths
--WHERE location LIKE '%Canada%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc

-- LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM [Portfolio Project]..Covid_Deaths
--WHERE location LIKE '%Canada%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc

-- GLOBAL NUMBERS
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercent
FROM [Portfolio Project]..Covid_Deaths
--WHERE location LIKE '%Canada%'
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1,2

-- Looking at Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project]..Covid_Deaths dea
JOIN [Portfolio Project]..Covid_Vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3

-- Using CTE to perform Calculation on Partition By in previous query
WITH PopvcVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project]..Covid_Deaths dea
JOIN [Portfolio Project]..Covid_Vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *, (RollingPeopleVaccinated/Population)/100
FROM PopvcVac

-- TEMP TABLE

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project]..Covid_Deaths dea
JOIN [Portfolio Project]..Covid_Vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
SELECT *, (RollingPeopleVaccinated/Population)/100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project]..Covid_Deaths dea
JOIN [Portfolio Project]..Covid_Vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 