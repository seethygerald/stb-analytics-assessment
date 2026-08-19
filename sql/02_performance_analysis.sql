-- Analyse Singapore's tourism source-market performance
-- and identify the top 10 tourism markets.
-- COVID-19 years 2020-2022 are excluded because they are not
-- representative of normal tourism conditions.



## Avg country rank
-- Countries are ranked by annual visitor arrivals.
-- Their average rank across observable years is then calculated.
-- ============================================================

WITH country_totals AS (
    SELECT
        year,
        country,
        SUM(visitor_arrivals) AS visitor_arrivals
    FROM travel_mode_clean
    WHERE year NOT IN (2020, 2021, 2022)
    GROUP BY
        year,
        country
),
ranked AS (
    SELECT
        year,
        country,
        visitor_arrivals,
        ROW_NUMBER() OVER (
            PARTITION BY year
            ORDER BY visitor_arrivals DESC
        ) AS rank
    FROM country_totals
)
SELECT
    country,
    ROUND(AVG(rank), 2) AS avg_rank,
    MIN(rank) AS best_rank,
    MAX(rank) AS worst_rank,
    COUNT(DISTINCT year) AS years_observed
FROM ranked
GROUP BY country
ORDER BY avg_rank;


## Top 10 source tourism markets

WITH country_totals AS (
    SELECT
        year,
        country,
        SUM(visitor_arrivals) AS visitor_arrivals
    FROM travel_mode_clean
    WHERE year NOT IN (2020, 2021, 2022)
    GROUP BY
        year,
        country
),
ranked AS (
    SELECT
        year,
        country,
        visitor_arrivals,
        ROW_NUMBER() OVER (
            PARTITION BY year
            ORDER BY visitor_arrivals DESC
        ) AS rank
    FROM country_totals
)
SELECT
    country,
    ROUND(AVG(rank), 2) AS avg_rank,
    MIN(rank) AS best_rank,
    MAX(rank) AS worst_rank,
    COUNT(DISTINCT year) AS years_observed
FROM ranked
GROUP BY country
ORDER BY avg_rank
LIMIT 10;