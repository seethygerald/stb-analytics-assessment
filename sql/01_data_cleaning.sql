-- ============================================================
-- 01_data_cleaning.sql
-- Singapore Tourism Board Data Analysis
--
-- Purpose:
-- Clean and standardise the three primary STAN datasets:
--   1. Hotel occupancy
--   2. Visitor arrivals by travel mode
--   3. Visitor arrivals by age, sex and length of stay
--
-- Note:
-- The raw tables below are registered as Pandas DataFrames
-- in the Jupyter Notebook before these queries are executed.

## Hotel occupancy data
-- Table: occupancy_clean

SELECT
    CAST(Month AS INTEGER) AS month,
    Quarter AS quarter,
    CAST(Year AS INTEGER) AS year,
    "Hotel Tier" AS hotel_tier,
    CAST("Average Room Rate" AS DOUBLE) AS avg_room_rate,
    CAST("Average Occupancy Rate" AS DOUBLE) AS avg_occupancy_rate,
    MAKE_DATE(
        CAST(Year AS INTEGER),
        CAST(Month AS INTEGER),
        1
    ) AS month_date
FROM occupancy_raw
WHERE "Year" IS NOT NULL;

## Visitor arrival by travel mode
-- Table: travel_mode_clean

SELECT
    CAST(Month AS INTEGER) AS month,
    Quarter AS quarter,
    CAST(Year AS INTEGER) AS year,
    Sex AS sex,
    "Place of Residence" AS country,
    "Region of Residence" AS region,
    "Mode of Arrival" AS arrival_mode,
    CAST("Visitor Arrivals" AS BIGINT) AS visitor_arrivals,

    MAKE_DATE(
        CAST(Year AS INTEGER),
        CAST(Month AS INTEGER),
        1
    ) AS month_date

FROM travel_mode_raw

WHERE Month <> 'Totals'
  AND Year IS NOT NULL;


## Visitor arrivals by age, sex and length of stay
-- Table: length_of_stay_clean

SELECT
    CAST(Month AS INTEGER) AS month,
    Quarter AS quarter,
    CAST(Year AS INTEGER) AS year,
    Sex AS sex,
    "Place of Residence" AS country,
    "Region of Residence" AS region,
    Age AS age_group,
    COALESCE(
        TRY_CAST("Visitor Arrivals" AS BIGINT),
        0
    ) AS visitor_arrivals,
    CASE
        WHEN COALESCE(
            TRY_CAST("Visitor Arrivals" AS BIGINT),
            0
        ) = 0
        THEN 0
        ELSE COALESCE(
            TRY_CAST("Average Length of Stay" AS DOUBLE),
            0
        )
    END AS avg_length_of_stay,
    MAKE_DATE(
        CAST(Year AS INTEGER),
        CAST(Month AS INTEGER),
        1
    ) AS month_date
FROM length_of_stay_raw
WHERE Month <> 'Totals'
  AND Year IS NOT NULL;