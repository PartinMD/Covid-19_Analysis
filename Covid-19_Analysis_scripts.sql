-- Overview of data (Date of data 04/07/2022)

Select Location, date, total_cases, new_cases, total_deaths, population
From [Covid-19_Data]..CovidDeaths
Where continent is not null
order by 1,2

-- Total Cases vs Total Deaths

-- Reflects likley-hood of death if Covid-19 was contracted
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From [Covid-19_Data]..CovidDeaths
--Where location like '%states%'
order by 1,2

-- Total Cases vs Population

-- Reflects percentage of population that contracted Covid-19
Select Location, date, total_cases, Population, (total_cases/Population)*100 as CovidPercentage
From [Covid-19_Data]..CovidDeaths
--Where location like '%states%'
order by 1,2


-- Highest Infection Rate

Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/Population))*100 as PercentPopulationInfected
From [Covid-19_Data]..CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

-- Highest Death Count per Population

Select Location, MAX(cast(total_deaths as BIGINT)) as TotalDeathCount
From [Covid-19_Data]..CovidDeaths
--Where location like '%states%'
Where continent is not null
Group by Location
order by TotalDeathCount desc

-- Death Count per Continent

-- More accurate
Select Location, MAX(cast(total_deaths as BIGINT)) as TotalDeathCount
From [Covid-19_Data]..CovidDeaths
--Where location like '%states%'
Where continent is null
Group by Location
order by TotalDeathCount desc


-- Less accurate (Some countries excluded from Continent Totals)
Select continent, MAX(cast(total_deaths as BIGINT)) as TotalDeathCount
From [Covid-19_Data]..CovidDeaths
--Where location like '%states%'
Where continent is not null
Group by continent
order by TotalDeathCount desc


-- Global Numbers

-- Deaths and Cases by Date

Select date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as bigint)) as TotalDeaths, SUM(cast(new_deaths as bigint))/SUM(new_cases)*100 as DeathPercentage
From [Covid-19_Data]..CovidDeaths
--Where location like '%states%'
where continent is not null
Group by date
order by 1,2

-- Joining CovidDeaths.dba to CovidVaccintations.dba

-- Total Population vs Total Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as TotalVaccinationCount
From [Covid-19_Data]..CovidDeaths dea
Join [Covid-19_Data]..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3

-- Using a CTE

With PopvsVac (continent, location, date, population, new_vaccinations, TotalVaccinationCount)
as
(Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as TotalVaccinationCount
From [Covid-19_Data]..CovidDeaths dea
Join [Covid-19_Data]..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--order by 2,3
)
Select *, (TotalVaccinationCount/Population)*100 as TotalVaccinationPercentage
From PopvsVac

-- Using a temp table

DROP Table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
TotalVaccinationCount numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as TotalVaccinationCount
From [Covid-19_Data]..CovidDeaths dea
Join [Covid-19_Data]..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--order by 2,3

Select *, (TotalVaccinationCount/Population)*100 as TotalVaccinationPercentage
From #PercentPopulationVaccinated

-- Creating views for storing data

-- Total Population vs Total Vaccinations (view)

CREATE VIEW PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as TotalVaccinationCount
From [Covid-19_Data]..CovidDeaths dea
Join [Covid-19_Data]..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--order by 2,3

-- Total Cases vs Total Deaths (view)

CREATE VIEW PercentageTotalDeaths as
-- Reflects likley-hood of death if Covid-19 was contracted
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From [Covid-19_Data]..CovidDeaths
--Where location like '%states%'
--order by 1,2

-- Highest Infection Rate (view)

CREATE VIEW PercentagePopulationInfected as
Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/Population))*100 as PercentPopulationInfected
From [Covid-19_Data]..CovidDeaths
--Where location like '%states%'
Group by Location, Population
--order by PercentPopulationInfected desc

-- Death Count per Continent (views)

CREATE VIEW ContinentalDeathCountV1 as
Select continent, MAX(cast(total_deaths as BIGINT)) as TotalDeathCount
From [Covid-19_Data]..CovidDeaths
--Where location like '%states%'
Where continent is not null
Group by continent
--order by TotalDeathCount desc

CREATE VIEW ContinentalDeathCountV2 as
Select continent, MAX(cast(total_deaths as BIGINT)) as TotalDeathCount
From [Covid-19_Data]..CovidDeaths
--Where location like '%states%'
Where continent is not null
Group by continent
--order by TotalDeathCount desc
