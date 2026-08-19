-- Mesh STAN visitor-arrival data with an external calendar
-- of international/regional concerts held in Singapore.

-- Hypothesis:
-- International concerts in Singapore are associated with
-- stronger visitor growth among key demographic segments.

-- IMPORTANT:
-- This analysis identifies statistical associations.
-- It does NOT establish that concerts caused visitor growth.

-- STAN = Singapore Tourism Analytics Network
-- YoY  = Year-on-Year

## country_demographic_monthly
-- Source: length_of_stay_clean

-- Aggregates monthly visitor arrivals by:
-- Year x Month x Country x Age Group x Sex


CREATE OR REPLACE VIEW country_demographic_monthly AS
SELECT
    year,
    month,
    country,
    age_group,
    sex,
    SUM(visitor_arrivals) AS visitor_arrivals
FROM length_of_stay_clean
WHERE country IS NOT NULL
  AND age_group <> 'Not Stated'
  AND sex <> 'Not Stated'
GROUP BY
    year,
    month,
    country,
    age_group,
    sex;


## country_demographic_yoy_base
-- Source: country_demographic_monthly

-- Adds the visitor-arrival figure from the same demographic
-- segment 12 months earlier.
-- This allows the current month to be compared against
-- the same month in the previous year.

CREATE OR REPLACE VIEW country_demographic_yoy_base AS
SELECT
    *,
    LAG(visitor_arrivals, 12) OVER (
        PARTITION BY
            country,
            age_group,
            sex
        ORDER BY
            year,
            month
    ) AS previous_year_visitors
FROM country_demographic_monthly;

## country_demographic_yoy
-- Source: country_demographic_yoy_base

-- Calculates Year-on-Year visitor-arrival growth for each
-- country, age group and sex combination.
-- Formula: ((Current Visitors / Previous-Year Visitors) - 1) x 100

CREATE OR REPLACE VIEW country_demographic_yoy AS
SELECT
    year,
    month,
    country,
    age_group,
    sex,
    visitor_arrivals,
    previous_year_visitors,
    ROUND(
        (
            visitor_arrivals
            / NULLIF(previous_year_visitors, 0)
            - 1
        ) * 100,
        2
    ) AS visitor_yoy_pct
FROM country_demographic_yoy_base
WHERE previous_year_visitors IS NOT NULL;

## country_demographic_yoy_clean
-- Source: country_demographic_yoy
-- Removes years affected by the COVID-19 tourism disruption.
-- 2020-2022 are excluded because tourism activity was heavily
-- distorted by travel restrictions.
-- 2023 is also excluded because its YoY comparison uses 2022
-- as the previous-year baseline.

CREATE OR REPLACE VIEW country_demographic_yoy_clean AS
SELECT
    *
FROM country_demographic_yoy
WHERE year NOT IN (2020, 2021, 2022, 2023);


## concert_monthly_binary
-- Source: singapore_concert_calendar
-- Creates a binary concert indicator at monthly level.
-- has_concert:
-- 1 = at least one international/regional concert occurred
-- in Singapore during that month.
-- Because only months containing concerts exist in the
-- concert calendar, non-concert months will later be assigned
-- 0 using COALESCE().
-- ============================================================

CREATE OR REPLACE VIEW concert_monthly_binary AS
SELECT
    CAST(event_year AS INTEGER) AS year,
    CAST(event_month AS INTEGER) AS month,
    1 AS has_concert
FROM singapore_concert_calendar
GROUP BY
    event_year,
    event_month;

## country_demographic_concert_binary
-- Sources:
-- 1. country_demographic_yoy_clean
-- 2. concert_monthly_binary
-- Meshes demographic visitor growth with the binary
-- concert/no-concert indicator.

-- Used to compare visitor growth during concert months
-- against visitor growth during non-concert months.

CREATE OR REPLACE VIEW country_demographic_concert_binary AS
SELECT
    d.year,
    d.month,
    d.country,
    d.age_group,
    d.sex,
    d.visitor_yoy_pct,
    COALESCE(
        c.has_concert,
        0
    ) AS has_concert
FROM country_demographic_yoy_clean d
LEFT JOIN concert_monthly_binary c
    ON d.year = c.year
    AND d.month = c.month;

## concert_binary_uplift
-- Source: country_demographic_concert_binary
-- Compares average YoY visitor growth between:
-- 1. Concert months
-- 2. Non-concert months

-- concert_uplift_pct_point measures the difference between
-- average growth during concert months and non-concert months.

-- Example:
-- Concert months     = 12% average YoY growth
-- Non-concert months = 8% average YoY growth
-- Uplift             = +4 percentage points

CREATE OR REPLACE VIEW concert_binary_uplift AS
SELECT
    country,
    age_group,
    sex,
    COUNT(*) FILTER (
        WHERE has_concert = 1
    ) AS concert_months,
    COUNT(*) FILTER (
        WHERE has_concert = 0
    ) AS no_concert_months,
    ROUND(
        AVG(visitor_yoy_pct)
        FILTER (
            WHERE has_concert = 1
        ),
        2
    ) AS concert_month_avg_yoy,
    ROUND(
        AVG(visitor_yoy_pct)
        FILTER (
            WHERE has_concert = 0
        ),
        2
    ) AS no_concert_month_avg_yoy,
    ROUND(
        AVG(visitor_yoy_pct)
        FILTER (
            WHERE has_concert = 1
        )
        -
        AVG(visitor_yoy_pct)
        FILTER (
            WHERE has_concert = 0
        ),
        2
    ) AS concert_uplift_pct_point
FROM country_demographic_concert_binary
WHERE country NOT IN (
    'Others',
    'Not Stated'
)
GROUP BY
    country,
    age_group,
    sex;

## concert_monthly
-- Source: singapore_concert_calendar

-- Counts how many international/regional concerts occurred
-- in Singapore during each month.
-- Unlike concert_monthly_binary, this measures concert
-- intensity instead of simply whether a concert occurred.

CREATE OR REPLACE VIEW concert_monthly AS
SELECT
    CAST(event_year AS INTEGER) AS year,
    CAST(event_month AS INTEGER) AS month,
    COUNT(*) AS concert_count
FROM singapore_concert_calendar
GROUP BY
    event_year,
    event_month;

## country_demographic_concert
-- Sources:
-- 1. country_demographic_yoy_clean
-- 2. concert_monthly

-- Main meshed dataset linking visitor-arrival growth with
-- monthly concert intensity.
-- concert_count:
-- Number of concerts occurring in Singapore during the month.

-- has_concert:
-- 1 = at least one concert
-- 0 = no concerts


-- Used to test whether months with more concerts tend to
-- coincide with stronger visitor-arrival growth.

CREATE OR REPLACE VIEW country_demographic_concert AS
SELECT
    d.year,
    d.month,
    d.country,
    d.age_group,
    d.sex,
    d.visitor_yoy_pct,
    COALESCE(
        c.concert_count,
        0
    ) AS concert_count,
    CASE
        WHEN COALESCE(
            c.concert_count,
            0
        ) > 0
        THEN 1
        ELSE 0
    END AS has_concert
FROM country_demographic_yoy_clean d
LEFT JOIN concert_monthly c
    ON d.year = c.year
    AND d.month = c.month
WHERE d.country NOT IN (
    'Not Stated',
    'Others'
);

## concert_intensity_correlation
-- Source: country_demographic_concert

-- Calculates the Pearson correlation between:
-- 1. Monthly concert count
-- 2. Year-on-Year visitor-arrival growth

-- The correlation is calculated separately for each:
-- Country x Age Group x Sex

-- observations:
-- Number of monthly observations available for each segment.
-- A minimum of 30 observations is required here before a
-- correlation result is retained.

CREATE OR REPLACE VIEW concert_intensity_correlation AS
SELECT
    country,
    age_group,
    sex,
    ROUND(
        CORR(
            concert_count,
            visitor_yoy_pct
        ),
        3
    ) AS correlation,
    COUNT(*) AS observations
FROM country_demographic_concert
WHERE visitor_yoy_pct IS NOT NULL
GROUP BY
    country,
    age_group,
    sex
HAVING COUNT(*) >= 30;


## optional checks

-- SELECT * FROM country_demographic_monthly LIMIT 10;

-- SELECT * FROM country_demographic_yoy_base LIMIT 10;

-- SELECT * FROM country_demographic_yoy LIMIT 10;

-- SELECT * FROM country_demographic_yoy_clean LIMIT 10;

-- SELECT * FROM concert_monthly_binary LIMIT 10;

-- SELECT * FROM country_demographic_concert_binary LIMIT 10;

-- SELECT * FROM concert_binary_uplift
-- ORDER BY concert_uplift_pct_point DESC
-- LIMIT 20;

-- SELECT * FROM concert_monthly
-- ORDER BY year, month;

-- SELECT * FROM country_demographic_concert LIMIT 10;

-- SELECT * FROM concert_intensity_correlation
-- ORDER BY correlation DESC
-- LIMIT 20;