/*
Canada's COVID-19 Mortality and Vaccination Analysis 2023

Jianwei Luo

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


--Check all the data

Select *
From PortfolioProject..CovidDeaths
Order by 3,4;

-- Check the data types of all columns in the 'CovidDeaths' table

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths';


--Optimizing Data Selection: All the data we need

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2;

-- Check the data types of all columns we need in the 'CovidDeaths' table

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths'
AND COLUMN_NAME IN ('Location', 'Date', 'Total_Cases', 'New_Cases', 'Total_Deaths', 'Population');

--Since Total_Deaths, Total_Cases are nvarchar, we need to change them into some types that we can caculate


--Add New Numeric Columns: because death and cases number cant be FLOAT so I will use INT
ALTER TABLE CovidDeaths
ADD New_Total_Deaths INT,
    New_Total_Cases INT; 
-- Update the New Columns
UPDATE CovidDeaths
SET New_Total_Deaths = CASE WHEN ISNUMERIC(Total_Deaths) = 1 THEN CAST(Total_Deaths AS INT) ELSE NULL END,
    New_Total_Cases = CASE WHEN ISNUMERIC(Total_Cases) = 1 THEN CAST(Total_Cases AS INT) ELSE NULL END;
--Drop Original Columns
ALTER TABLE CovidDeaths
DROP COLUMN Total_Deaths,
             Total_Cases;
--Change the name to replease the old ones
EXEC sp_rename 'CovidDeaths.New_Total_Deaths', 'Total_Deaths', 'COLUMN';
EXEC sp_rename 'CovidDeaths.New_Total_Cases', 'Total_Cases', 'COLUMN';

--Re-check the data type of the columns we need

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths'
AND COLUMN_NAME IN ('Location', 'Date', 'Total_Cases', 'Total_Deaths');


--Optimizing Data Selection: Total Death Percentage for the world

Select Location, date, Total_Cases, Total_Deaths, (Total_Deaths*100.0/Total_Cases) as DeathPercentage
From PortfolioProject..CovidDeaths
order by 1,2;

--Optimizing Data Selection: Total Death Percentage for Canada

Select Location, date, Total_Cases, Total_Deaths, (Total_Deaths*100.0/Total_Cases) as DeathPercentage
From PortfolioProject..CovidDeaths
Where location = 'Canada'
order by 1,2;

--Optimizing Data Selection: Total Cases vs Population for Canada (Percentage of population got covid)

Select Location, date, Population, Total_Cases, (Total_Cases*100.0/Population) as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where location = 'Canada'
order by 1,2;

-- Countries with Highest Infection Rate compared to Population Rank

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((Total_Cases*100.0/Population)) as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc

-- Countries with Highest Infection Rate compared to Population Rank among G7

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((Total_Cases*100.0/Population)) as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where Location IN ('Canada', 'United States', 'United Kingdom', 'Germany', 'France', 'Italy', 'Japan')
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population Rank

Select Location, MAX(Total_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths 
Where continent is not null
Group by Location
order by TotalDeathCount desc

-- Countries with Highest Death Count per Population Rank among G7

Select Location, MAX(Total_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths 
Where Location IN ('Canada', 'United States', 'United Kingdom', 'Germany', 'France', 'Italy', 'Japan')
Group by Location
order by TotalDeathCount desc


-- Contintents with the highest death count per population Rank

Select continent, MAX(Total_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc

--World total death percentage 

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2

--Canada and G7 total death percentage 
Select Location, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where location = 'Canada'
Group by Location 
order by 1,2


Select Location, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where location IN ('Canada', 'United States', 'United Kingdom', 'Germany', 'France', 'Italy', 'Japan')
Group by Location 
order by DeathPercentage desc

--Looks like so far Canada has the highest DeathPercentage amonag G7

-- Total Population vs Vaccinations of worlds
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to find the total vaccinated percentage for each country

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


-- Using CTE to find the total vaccinated percentage for G7

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
where location IN ('Canada', 'United States', 'United Kingdom', 'Germany', 'France', 'Italy', 'Japan')
GROUP BY Location, Population
order by TotalVaccinatedPercentage desc

--Canada has the second highest vaccinated percentage


--We can also creat a Temp Table to perform this

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
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select Location,
    Population,
    MAX(RollingPeopleVaccinated) AS RollingPeopleVaccinated, -- Use MAX to get the last RollingPeopleVaccinated value for each country
    (MAX(RollingPeopleVaccinated) / Population) * 100 AS TotalVaccinatedPercentage
FROM #PercentPopulationVaccinated
where location IN ('Canada', 'United States', 'United Kingdom', 'Germany', 'France', 'Italy', 'Japan')
GROUP BY Location, Population
order by TotalVaccinatedPercentage desc


-- Creating View to store data for later visualizations

Drop View if EXISTS DeathPercentage_amonag_G7
--DeathPercentage_amonag_G7
Create View DeathPercentage_amonag_G7 as

Select Location, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where location IN ('Canada', 'United States', 'United Kingdom', 'Germany', 'France', 'Italy', 'Japan')
Group by Location 

Select*
From DeathPercentage_amonag_G7


--TotalVaccinatedPercentage_amonag_G7
Drop View if EXISTS TotalVaccinatedPercentage_amonag_G7
CREATE VIEW TotalVaccinatedPercentage_amonag_G7 AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT
    Location,
    Population,
    MAX(RollingPeopleVaccinated) AS RollingPeopleVaccinated,
    (MAX(RollingPeopleVaccinated) / Population) * 100 AS TotalVaccinatedPercentage
FROM TotalVaccinatedPercentage_amonag_G7
WHERE location IN ('Canada', 'United States', 'United Kingdom', 'Germany', 'France', 'Italy', 'Japan')
GROUP BY Location, Population
ORDER BY TotalVaccinatedPercentage DESC;
