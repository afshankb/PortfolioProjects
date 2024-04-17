/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

--Filtering by Continent:
--Selects all data from the CovidDeaths table, filtering out entries where the continent information is missing. Results are sorted by the third and fourth columns.

Select *
From [PortfolioProject]..CovidDeaths$
Where continent is not null 
Order by 3,4

-- Select Data that we are going to be starting with

--Initial Data Selection:
--Retrieves specific columns (Location, date, total_cases, new_cases, total_deaths, population) from the CovidDeaths table, focusing on entries where the continent information is available. Results are sorted by location and date.

Select Location, date, total_cases, new_cases, total_deaths, population
From [PortfolioProject]..CovidDeaths$
Where continent is not null 
order by 1,2

--Total Cases vs Total Deaths in India:
--Compares total cases and total deaths in locations containing the term "India." It calculates the percentage of deaths relative to total cases.

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From [PortfolioProject]..CovidDeaths$
Where location like '%India%'
and continent is not null 
order by 1,2

--Total Cases vs Population:
--Percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From [PortfolioProject]..CovidDeaths$
--Where location like '%India%'
order by 1,2

--Countries with Highest Infection Rates:
--Identifies countries with the highest infection rates relative to their populations.

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From [PortfolioProject]..CovidDeaths$
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

--Countries with Highest Death Count per Population
--Lists countries with the highest total death counts, considering their populations.

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [PortfolioProject]..CovidDeaths$
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc

--Breakdown by Continent:

-- Explores continents with the highest total death counts per population.

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [PortfolioProject]..CovidDeaths$
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc

--Global Covid-19 Statistics:
--Provides global Covid-19 statistics, including total cases, total deaths, and the percentage of deaths relative to new cases.

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From [PortfolioProject]..CovidDeaths$
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Total Population vs Vaccinations
-- Examines the relationship between total population and new vaccinations, calculating the rolling sum of vaccinated individuals over time for each location. 
-- It shows the percentage of the population that has received at least one Covid vaccine.

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [PortfolioProject]..CovidDeaths$ dea
Join [PortfolioProject]..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

--Using Common Table Expression (CTE) for Vaccination Calculation:
--Employs a Common Table Expression (CTE) to calculate the percentage of the population vaccinated based on the rolling sum of vaccinations.

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3 
)  

Select * , (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using  Temp Table for Vaccination Calculation:
-- Demonstrates the use of a temporary table to calculate the percentage of the population vaccinated, similar to the CTE approach.

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

--Creating View for Storing Vaccination Data:
--Creates a view named PercentPopulationVaccinated to store vaccination data for future visualizations.

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

Select *
From PercentPopulationVaccinated
