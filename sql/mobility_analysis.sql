-- Create the trips table
CREATE TABLE trips (
    trip_id INTEGER PRIMARY KEY,
    mode VARCHAR(30) NOT NULL,
    distance_km NUMERIC(6,2) NOT NULL,
    travel_time_min INTEGER NOT NULL,
    cost_tzs INTEGER NOT NULL
);

-- Insert sample mobility data
INSERT INTO trips
    (trip_id, mode, distance_km, travel_time_min, cost_tzs)
VALUES
    (1, 'Daladala', 12.00, 55, 800),
    (2, 'BRT', 14.00, 40, 650),
    (3, 'Motorcycle', 10.00, 30, 5000),
    (4, 'Car', 11.00, 35, 7000),
    (5, 'Walking', 2.00, 25, 0);

-- Retrieve all records from trips table
SELECT *
FROM trips;

-- How many journey records?
SELECT COUNT(*) AS total_trips
FROM trips;

-- Inspect data structure
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'trips';

-- Examine transport modes
SELECT
    mode,
    COUNT(*) AS number_of_trips
FROM trips
GROUP BY mode
ORDER BY number_of_trips DESC;

-- Expanding the dataset
ALTER TABLE trips
ADD COLUMN trip_date DATE,
ADD COLUMN time_of_day VARCHAR(20),
ADD COLUMN traffic_condition VARCHAR(20);


WITH modes(mode, mode_order) AS (
    VALUES
        ('BRT', 1),
        ('Daladala', 2),
        ('Motorcycle', 3),
        ('Car', 4),
        ('Walking', 5)
),
generated AS (
    SELECT
        mode,
        mode_order,
        n,
        ROW_NUMBER() OVER (ORDER BY mode_order, n) AS row_num
    FROM modes
    CROSS JOIN generate_series(1, 39) AS n
),
conditions AS (
    SELECT
        *,
        CASE (n + mode_order) % 4
            WHEN 0 THEN 'Morning peak'
            WHEN 1 THEN 'Midday'
            WHEN 2 THEN 'Evening peak'
            ELSE 'Night'
        END AS time_of_day,
        CASE (n * 3 + mode_order) % 3
            WHEN 0 THEN 'Low'
            WHEN 1 THEN 'Moderate'
            ELSE 'Heavy'
        END AS traffic_condition,
        CASE mode
            WHEN 'BRT' THEN 8 + ((n * 7) % 15)
            WHEN 'Daladala' THEN 4 + ((n * 5) % 14)
            WHEN 'Motorcycle' THEN 2 + ((n * 3) % 13)
            WHEN 'Car' THEN 3 + ((n * 4) % 18)
            ELSE 1 + ((n * 2) % 6)
        END AS distance_km
    FROM generated
),
calculated AS (
    SELECT
        *,
        CASE mode
            WHEN 'BRT' THEN 21.0
            WHEN 'Daladala' THEN 13.1
            WHEN 'Motorcycle' THEN 20.0
            WHEN 'Car' THEN 18.9
            ELSE 4.8
        END AS base_speed
    FROM conditions
)
INSERT INTO trips (
    trip_id,
    mode,
    distance_km,
    travel_time_min,
    cost_tzs,
    trip_date,
    time_of_day,
    traffic_condition
)
SELECT
    5 + row_num,
    mode,
    distance_km,
    GREATEST(1, ROUND(
        distance_km / base_speed * 60 *
        CASE traffic_condition
            WHEN 'Low' THEN 1.0
            WHEN 'Moderate' THEN 1.25
            ELSE 1.6
        END *
        (0.85 + ((n * 7) % 31) / 100.0)
    ))::INTEGER,
    CASE mode
        WHEN 'BRT' THEN ROUND(distance_km * (40 + (n % 15) * 2))
        WHEN 'Daladala' THEN ROUND(distance_km * (55 + (n % 20) * 2))
        WHEN 'Motorcycle' THEN ROUND(distance_km * (350 + (n % 10) * 35))
        WHEN 'Car' THEN ROUND(distance_km * (450 + (n % 10) * 40))
        ELSE 0
    END::INTEGER,
    DATE '2026-09-01' + ((n * 7 + mode_order * 3) % 60)::INTEGER,
    time_of_day,
    traffic_condition
FROM calculated;

-- Confirming trips created successfully
SELECT
    COUNT(*) AS total_trips
FROM trips;

SELECT
    mode,
    COUNT(*) AS number_of_trips
FROM trips
GROUP BY mode
ORDER BY mode;

-- Checking data quality
-- Missing values
SELECT
    COUNT(*) AS total_trips,
    COUNT(*) FILTER (WHERE mode IS NULL) AS missing_mode,
    COUNT(*) FILTER (WHERE distance_km IS NULL) AS missing_distance,
    COUNT(*) FILTER (WHERE travel_time_min IS NULL) AS missing_travel_time,
    COUNT(*) FILTER (WHERE cost_tzs IS NULL) AS missing_cost,
    COUNT(*) FILTER (WHERE trip_date IS NULL) AS missing_date,
    COUNT(*) FILTER (WHERE time_of_day IS NULL) AS missing_time_of_day,
    COUNT(*) FILTER (WHERE traffic_condition IS NULL) AS missing_traffic
FROM trips;

-- Duplicates
SELECT
    trip_id,
    COUNT(*) AS occurrences
FROM trips
GROUP BY trip_id
HAVING COUNT(*) > 1;

-- Invalid values (impossible/ suspicious)
SELECT *
FROM trips
WHERE distance_km <= 0
   OR travel_time_min <= 0
   OR cost_tzs < 0;

-- Categorical consistency
-- mode
SELECT DISTINCT mode
FROM trips
ORDER BY mode;

-- Time of the day  
SELECT DISTINCT time_of_day
FROM trips
ORDER BY time_of_day;

-- Traffic condition
SELECT DISTINCT traffic_condition
FROM trips
ORDER BY traffic_condition;

-- Date range
SELECT
    MIN(trip_date) AS earliest_date,
    MAX(trip_date) AS latest_date,
    COUNT(trip_date) AS records_with_dates
FROM trips;


-- Data analysis
-- Operational performance
-- Average travel time by transport mode
SELECT
    mode,
    COUNT(*) AS number_of_trips,
    ROUND(AVG(travel_time_min), 2) AS average_travel_time_min
FROM trips
GROUP BY mode
ORDER BY average_travel_time_min ASC;

-- Average speed by each transport mode
SELECT
    mode,
    COUNT(*) AS number_of_trips,
    ROUND(AVG(distance_km), 2) AS avg_distance_km,
    ROUND(AVG(travel_time_min), 2) AS avg_travel_time_min,
    ROUND(
        AVG(distance_km / (travel_time_min / 60.0)), 2
    ) AS avg_speed_kmh
FROM trips
GROUP BY mode
ORDER BY avg_speed_kmh DESC;

-- Economic performance
-- Average cost per kilometre for each mode
SELECT
    mode,
    COUNT(*) AS number_of_trips,
    ROUND(AVG(cost_tzs), 2) AS avg_trip_cost_tzs,
    ROUND(
        AVG(cost_tzs / NULLIF(distance_km, 0)), 2
    ) AS avg_cost_per_km_tzs
FROM trips
GROUP BY mode
ORDER BY avg_cost_per_km_tzs ASC;

-- Speed-cost tradeoff
SELECT
    mode,
    COUNT(*) AS number_of_trips,
    ROUND(
        AVG(distance_km / (travel_time_min / 60.0)), 2
    ) AS avg_speed_kmh,
    ROUND(
        AVG(cost_tzs / NULLIF(distance_km, 0)), 2
    ) AS avg_cost_per_km_tzs
FROM trips
GROUP BY mode
ORDER BY avg_cost_per_km_tzs ASC;

-- Travel-time variability
-- Travel time variability using sample standard deviation
SELECT
    mode,
    COUNT(*) AS number_of_trips,
    ROUND(AVG(travel_time_min), 2) AS avg_travel_time_min,
    ROUND(STDDEV_SAMP(travel_time_min), 2) AS travel_time_std_dev
FROM trips
GROUP BY mode
ORDER BY travel_time_std_dev ASC;

-- Traffic-condition analysis
-- Comparing average travel time across traffic conditions
SELECT
    traffic_condition,
    COUNT(*) AS number_of_trips,
    ROUND(AVG(travel_time_min), 2) AS avg_travel_time_min
FROM trips
WHERE traffic_condition IS NOT NULL
GROUP BY traffic_condition
ORDER BY avg_travel_time_min ASC;

-- Exploratory traffic-condition comparison by transport mode.
-- Interpret cautiously: traffic-condition categories are not balanced across modes,
-- so this query is not used for mode-specific traffic conclusions.

SELECT
    mode,
    traffic_condition,
    COUNT(*) AS number_of_trips,
    ROUND(AVG(travel_time_min), 2) AS avg_travel_time_min,
    ROUND(AVG(distance_km), 2) AS avg_distance_km,
    ROUND(
        AVG(distance_km / (travel_time_min / 60.0)),
        2
    ) AS avg_speed_kmh
FROM trips
WHERE traffic_condition IS NOT NULL
GROUP BY mode, traffic_condition
ORDER BY mode, avg_travel_time_min;

-- Time of the day analysis
-- Overall
SELECT
    time_of_day,
    COUNT(*) AS number_of_trips,
    ROUND(AVG(travel_time_min), 2) AS avg_travel_time_min
FROM trips
WHERE time_of_day IS NOT NULL
GROUP BY time_of_day
ORDER BY avg_travel_time_min ASC;

-- For each mode
SELECT
    mode,
    time_of_day,
    COUNT(*) AS number_of_trips,
    ROUND(AVG(travel_time_min), 2) AS avg_travel_time_min,
    ROUND(
        AVG(distance_km / (travel_time_min / 60.0)),
        2
    ) AS avg_speed_kmh
FROM trips
WHERE time_of_day IS NOT NULL
GROUP BY mode, time_of_day
ORDER BY mode, avg_travel_time_min;
