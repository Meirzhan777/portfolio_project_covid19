--TABLE CREATION FOR DATA IMPORT
CREATE TABLE covid_deaths(
iso_code VARCHAR,
continent VARCHAR,
location VARCHAR,
date DATE,
population DECIMAL,
total_cases DECIMAL,
new_cases DECIMAL,
new_cases_smoothed DECIMAL,
total_deaths DECIMAL,
new_deaths DECIMAL,
new_deaths_smoothed DECIMAL,
total_cases_per_million DECIMAL,
new_cases_per_million DECIMAL,
new_cases_smoothed_per_million DECIMAL,
total_deaths_per_million DECIMAL,
new_deaths_per_million DECIMAL,
new_deaths_smoothed_per_million DECIMAL,
reproduction_rate DECIMAL,
icu_patients DECIMAL,
icu_patients_per_million DECIMAL,
hosp_patients DECIMAL,
hosp_patients_per_million DECIMAL,
weekly_icu_admissions DECIMAL,
weekly_icu_admissions_per_million DECIMAL,
weekly_hosp_admissions DECIMAL,
weekly_hosp_admissions_per_million DECIMAL
);

CREATE TABLE covid_vaccinations(
iso_code VARCHAR,
continent VARCHAR,
location VARCHAR,
date DATE,
new_tests DECIMAL,
total_tests_per_thousand DECIMAL,
new_tests_per_thousand DECIMAL,
new_tests_smoothed DECIMAL,
new_tests_smoothed_per_thousand DECIMAL,
positive_rate DECIMAL,
tests_per_case DECIMAL,
tests_units  VARCHAR,
total_vaccinations DECIMAL,
people_vaccinated DECIMAL,
people_fully_vaccinated DECIMAL,
total_boosters DECIMAL,
new_vaccinations DECIMAL,
new_vaccinations_smoothed DECIMAL,
total_vaccinations_per_hundred DECIMAL,
people_vaccinated_per_hundred DECIMAL,
people_fully_vaccinated_per_hundred DECIMAL,
total_boosters_per_hundred DECIMAL,
new_vaccinations_smoothed_per_million DECIMAL,
new_people_vaccinated_smoothed DECIMAL,
new_people_vaccinated_smoothed_per_hundred DECIMAL,
stringency_index DECIMAL,
population_density DECIMAL,
median_age DECIMAL,
aged_65_older DECIMAL,
aged_70_older DECIMAL,
gdp_per_capita DECIMAL,
extreme_poverty DECIMAL,
cardiovasc_death_rate DECIMAL,
diabetes_prevalence DECIMAL,
female_smokers DECIMAL,
male_smokers DECIMAL,
handwashing_facilities DECIMAL,
hospital_beds_per_thousand DECIMAL,
life_expectancy DECIMAL,
human_development_index DECIMAL,
excess_mortality_cumulative_absolute DECIMAL,
excess_mortality_cumulative DECIMAL,
excess_mortality DECIMAL,
excess_mortality_cumulative_per_million DECIMAL
);

--LOOKING AT TOTAL DEATHS VS TOTAL CASES RATIO
--SHOW PROBABILITY OF DYING FROM DISEASE IN KAZAKHSTAN
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_percentage
FROM covid_deaths
WHERE location = 'Kazakhstan'
ORDER BY 2;

--LOOKING AT TOTAL CASES VS POPULATION RATIO
--SHOW PERCENTAGE OF POPULATION THAT GOT COVID-19
SELECT location, date, total_cases, population, (total_cases/population) * 100 AS infected_percentage
FROM covid_deaths
WHERE location = 'Kazakhstan'
ORDER BY 2;

--LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO ITS POPULATION
SELECT location, population, MAX(total_cases) AS highest_cases_count, MAX(total_cases/population) * 100 AS percent_population_infected
FROM covid_deaths
WHERE continent IS NOT NULL AND total_cases IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_infected DESC;

--LOOKING AT TOP COUNTRIES WITH TOTAL DEATHS NUMBER
SELECT location, MAX(total_deaths) AS Total_Deaths_Count
FROM covid_deaths
WHERE total_deaths IS NOT NULL AND continent IS NOT NULL
GROUP BY location
ORDER BY Total_Deaths_Count DESC;

--LOOKING AT TOTAL DEATHS NUMBER BY CONTINENTS
SELECT location, MAX(total_deaths) AS Total_Deaths_Count
FROM covid_deaths
WHERE location IN (SELECT DISTINCT continent FROM covid_deaths WHERE continent IS NOT NULL)
--Subquery in WHERE is used to filter out values that are not continents, like 'European Union', 'High Income' etc.
GROUP BY location
ORDER BY Total_Deaths_Count DESC;

--LOOKING AT DEATH PERCENTAGES GLOBALLY BY DATE
SELECT date, SUM(new_cases) AS total_case_number, SUM(new_deaths) AS total_deaths_number, 
(SUM(total_deaths)/SUM(total_cases)) * 100 AS global_death_percentage
FROM covid_deaths
WHERE new_cases IS NOT NULL
GROUP BY date
ORDER BY date;
--We can see that since numbers are recorded weekly in dataset, the dates that we have are 7 days apart from each other



--LOOKING AT TOTAL POPULATION VS VACCINATION
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_people_vaccination
FROM covid_deaths cd
JOIN covid_vaccinations cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2,3;

--NOW LOOKING AT PERCENTAGE OF VACCINATED FROM POPULATION (USING CTE)
WITH rolling_cte (continent, location, date, population, new_vaccinations, rolling_people_vaccinated) AS (
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_people_vaccinated
FROM covid_deaths cd
JOIN covid_vaccinations cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population) * 100 AS percent_vaccinated
FROM rolling_cte;

--NOW LOOKING AT PERCENTAGE OF VACCINATED FROM POPULATION (USING TEMP TABLE)
DROP TABLE IF EXISTS temp_table_rolling;
CREATE TEMPORARY TABLE temp_table_rolling (
continent VARCHAR(225),
location VARCHAR(225),
date DATE,
population DECIMAL,
new_vaccination DECIMAL,
rolling_people_vaccinated DECIMAL	
);

INSERT INTO temp_table_rolling 
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_people_vaccinated
FROM covid_deaths cd
JOIN covid_vaccinations cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;

SELECT *, (rolling_people_vaccinated/population) * 100 AS percent_vaccinated
FROM temp_table_rolling;

--Creating VIEWs to store data for later visualizations

--Total deaths number by continent
CREATE VIEW deaths_cont AS
SELECT location, MAX(total_deaths) AS Total_Deaths_Count
FROM covid_deaths
WHERE location IN (SELECT DISTINCT continent FROM covid_deaths WHERE continent IS NOT NULL)
--Subquery in WHERE is used to filter out values that are not continents, like 'European Union', 'High Income' etc.
GROUP BY location
ORDER BY Total_Deaths_Count DESC;

SELECT * FROM deaths_cont;

