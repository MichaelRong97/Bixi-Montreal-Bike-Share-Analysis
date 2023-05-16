/*****************
BIXI DATA ANALYSIS

Author: Michael Rong
Company: BrainStation
Date: Feb 01, 2023
******************/

/***********************************
 Sampling the Tables
***********************************/
-- Making sure that the proper schema is being used at the start
USE bixi;

-- Checking the structure of the tables
SELECT * FROM trips
limit 5;

SELECT * FROM stations
limit 5;

/***********************************
 Section 1 - Usage Overview
***********************************/

-- Let's take a look at the total number of trips for the year 2016.

SELECT COUNT(*) AS total_num_trips
FROM trips
WHERE YEAR (start_date) = 2016;

-- The total number of trips for the year of 2017.

SELECT COUNT(*) AS total_num_trips
FROM trips
WHERE YEAR (start_date) = 2017;

-- Let's see the amount of trips broken down by month.

SELECT MONTH(start_date) AS month_,
COUNT(*) AS num_trips
FROM trips
WHERE YEAR(start_date) = 2016
GROUP BY MONTH(start_date)
ORDER BY MONTH(start_date);

-- The total number of trips for the year of 2017 broken down by month.

SELECT MONTH(start_date) AS month_,
COUNT(*) AS num_trips
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY MONTH(start_date)
ORDER BY MONTH(start_date);

-- The average number of trips a day for each month spanning 2016 and 2017.

SELECT YEAR(start_date) as year_,
MONTH(start_date) AS month_,
ROUND(COUNT(*)/COUNT(DISTINCT DAY(start_date)), 0) AS avg_daily_trips
FROM trips
GROUP BY YEAR(start_date), MONTH(start_date)
ORDER BY YEAR(start_date), MONTH(start_date);

/***********************************
Section 2 - Membership vs Non-Members
***********************************/

-- The total number of trips in the year 2017 broken down by membership status (member/non-member).

SELECT COUNT(*) AS num_trips,
is_member
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY is_member;

-- The percentage of total trips by members for the year 2017 broken down by month.

SELECT MONTH(start_date) AS month_,
AVG(is_member) AS pct_member_trips
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY MONTH(start_date)
ORDER BY MONTH(start_date) DESC;


/***********************************
 Section 3 - Peak Season/Promotions
***********************************/

-- At which time(s) of the year is the demand for Bixi bikes at its peak?

select month(start_date) AS month_,
	SUM(IF(YEAR(start_date) = 2016, 1, 0)) AS trips_2016,
	SUM(IF(YEAR(start_date) = 2017, 1, 0)) AS trips_2017
FROM trips
GROUP BY MONTH(start_date);


/***********************************
 Section 4 - Station Usage
***********************************/

-- What are the names of the 5 most popular starting stations?
SELECT num_trips, name FROM
(SELECT COUNT(*) AS num_trips, start_station_code
FROM trips
GROUP BY start_station_code
ORDER BY num_trips DESC
LIMIT 5) AS total_trips
JOIN stations
	ON stations.code = total_trips.start_station_code;
    
-- How is the number of starts and ends distributed for the station Mackay / de Maisonneuve throughout the day?

SELECT COUNT(*) AS num_trips,
CASE
WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
ELSE "night"
END AS "time_of_day"
FROM trips
WHERE end_station_code =
	(SELECT *
    FROM stations
    WHERE name = 'Mackay / de Maisonneuve');


/***********************************
 Section 5 - Round-Trips
***********************************/
-- Create a step by step process to get to a list of stations with 500+ trips starting from the station & 10% round trips

-- First, write a query that counts the number of starting trips per station.

SELECT start_station_code,
COUNT(*) AS num_trips
FROM trips
GROUP BY start_station_code
ORDER BY num_trips DESC;

-- Second, write a query that counts, for each station, the number of round trips.

SELECT start_station_code,
COUNT(*) AS num_trips
FROM trips
WHERE start_station_code = end_station_code
GROUP BY start_station_code
ORDER BY num_trips DESC;

-- Combining the above queries and calculate the fraction of round trips to the total number of starting trips for each station.

SELECT stations.name,
SUM(IF(start_station_code = end_station_code, 1, 0))/COUNT(*) AS pct_num_round_trips
FROM trips
JOIN stations
	ON stations.code = trips.start_station_code
GROUP BY stations.name
ORDER BY pct_num_round_trips DESC;

-- Filter down to stations with at least 500 trips originating from them and having at least 10% of their trips as round trips.

SELECT stations.name,
SUM(IF(start_station_code = end_station_code, 1, 0))/COUNT(*) AS pct_num_round_trips
FROM trips
JOIN stations
	ON stations.code = trips.start_station_code
GROUP BY stations.name
HAVING pct_num_round_trips >= 0.1 AND COUNT(id) >= 500 
ORDER BY pct_num_round_trips DESC;
