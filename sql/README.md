# SQL Analysis

This folder contains the SQL script used to create, prepare and analyse the simulated urban mobility dataset for the project **Exploring Urban Transport Performance Through Data**.

## File

`mobility_analysis.sql`

## Script Overview

The script is organised into the following stages:

1. **Table creation and initial data insertion** – Creates the `trips` table and inserts five initial sample trip records representing the selected transport modes.
2. **Dataset preparation** – Adds trip date, time-of-day and traffic-condition attributes, then generates additional simulated records.
3. **Data inspection and quality checks** – Examines the dataset structure, record counts, missing values, duplicate IDs, invalid values, categories and date range.
4. **Transport performance analysis** – Uses SQL queries to compare average travel time, travel speed, average trip cost and average cost per kilometre across transport modes.
5. **Travel-time variability analysis** – Calculates sample standard deviation to examine differences in travel-time variation.
6. **Traffic and temporal analysis** – Examines overall travel-time patterns by traffic condition and time of day, including comparisons across transport modes.

## Tools and Technologies

- PostgreSQL 18
- SQL
- pgAdmin 4

## How to Run

1. Open PostgreSQL using pgAdmin 4.
2. Connect to your PostgreSQL server.
3. Create or select an empty database for the project.
4. Open the Query Tool for that database.
5. Open `mobility_analysis.sql`.
6. Execute the script from beginning to end.

**Important:** Run the script in a database where a table named `trips` does not already exist. The script creates this table and inserts the initial records, so it is not designed to be run repeatedly in the same database without resetting it.

## Dataset Note

The dataset contains 200 simulated trip records across five transport modes: BRT, daladala, motorcycles, private cars and walking. It is intended for learning and analytical demonstration. It does not represent actual transport observations or measured travel conditions in Dar es Salaam.

## Analytical Scope

The SQL queries support descriptive comparisons of transport performance, affordability, travel-time variability and temporal patterns. The results should be interpreted within the limitations of the simulated dataset.
