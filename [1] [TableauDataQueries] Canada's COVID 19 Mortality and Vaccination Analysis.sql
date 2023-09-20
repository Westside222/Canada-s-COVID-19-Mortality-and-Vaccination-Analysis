--The following parts will be visualized in Tableau

--1.

Select Location, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where location = 'Canada'
Group by Location 
order by 1,2

--2. 

Select Location, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where location IN ('Canada', 'United States', 'United Kingdom', 'Germany', 'France', 'Italy', 'Japan')
Group by Location 
order by DeathPercentage desc

-- 3.

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc


--4. 

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
SELECT
    Location,
    Population,
    MAX(RollingPeopleVaccinated) AS RollingPeopleVaccinated, -- Use MAX to get the last RollingPeopleVaccinated value for each country
    (MAX(RollingPeopleVaccinated) / Population) * 100 AS TotalVaccinatedPercentage
FROM PopvsVac
GROUP BY Location, Population
order by TotalVaccinatedPercentage desc

--5.

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
where location IN ('Canada', 'United States', 'United Kingdom', 'Germany', 'France', 'Italy', 'Japan')
Group by Location, Population, date
order by PercentPopulationInfected desc

-- Tableau Dashboard: https://public.tableau.com/app/profile/jianwei.luo/viz/COVIDStatsCanadaWorld/Dashboard1?publish=yes