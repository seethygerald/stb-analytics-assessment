
-- Contains the four final analytical datasets exported to
-- CSV and used as data sources for the Looker dashboard.

## Table 1: tourism_market_performance
-- Monthly visitor-arrival performance by source market.

SELECT
    t.year,
    t.month,
    t.month_date,
    t.country,
    SUM(t.visitor_arrivals) AS visitor_arrivals,
    CASE
        WHEN t.country IN (
            SELECT country
            FROM average_country_rank_top10
        )
        THEN 1
        ELSE 0
    END AS is_top10
FROM travel_mode_clean t
WHERE t.country NOT IN (
        'Others',
        'Not Stated'
      )
  AND t.year NOT IN (2020, 2021, 2022)
GROUP BY
    t.year,
    t.month,
    t.month_date,
    t.country
ORDER BY
    t.month_date,
    t.country;
-- Add previous year's arrivals.
SELECT
    year,
    month,
    month_date,
    country,
    visitor_arrivals,
    is_top10,
    LAG(visitor_arrivals, 12) OVER (
        PARTITION BY country
        ORDER BY month_date
    ) AS previous_year_arrivals
FROM tourism_market_performance
ORDER BY
    country,
    month_date;
-- Calculate YoY visitor growth.
SELECT
    year,
    month,
    month_date,
    country,
    visitor_arrivals,
    is_top10,
    previous_year_arrivals,
    CASE
        WHEN previous_year_arrivals > 0
        THEN ROUND(
            (
                visitor_arrivals
                - previous_year_arrivals
            ) * 100.0
            / previous_year_arrivals,
            2
        )
        ELSE NULL
    END AS visitor_yoy_pct
FROM tourism_market_performance_yoy
ORDER BY
    country,
    month_date;


## Table 2: top10_demographics
-- Show the composition of Singapore's top 10 tourism markets
-- by age group and sex.

WITH demographic_totals AS (
    SELECT
        year,
        country,
        age_group,
        sex,
        SUM(visitor_arrivals)
            AS demographic_visitors
    FROM length_of_stay_clean
    WHERE year NOT IN (2020, 2021, 2022)
      AND country IN (
            SELECT country
            FROM average_country_rank_top10
          )
      AND country NOT IN (
            'Others',
            'Not Stated'
          )
      AND age_group <> 'Not Stated'
      AND sex <> 'Not Stated'
    GROUP BY
        year,
        country,
        age_group,
        sex
),
market_totals AS (
    SELECT
        year,
        country,
        SUM(demographic_visitors)
            AS total_market_visitors
    FROM demographic_totals
    GROUP BY
        year,
        country
)
SELECT
    d.year,
    d.country,
    d.age_group,
    d.sex,
    d.demographic_visitors,
    m.total_market_visitors,
    ROUND(
        d.demographic_visitors * 100.0
        / NULLIF(
            m.total_market_visitors,
            0
        ),
        2
    ) AS demographic_share_pct
FROM demographic_totals d
LEFT JOIN market_totals m
    ON d.year = m.year
    AND d.country = m.country
ORDER BY
    d.year,
    d.country,
    demographic_share_pct DESC;
-- Append long-term demographic ranking metadata.
SELECT
    d.*,
    r.avg_rank,
    r.best_rank,
    r.worst_rank,
    r.years_observed
FROM top10_demographics d
LEFT JOIN avg_country_demographic_rank_top10 r
    ON d.country = r.country
    AND d.age_group = r.age_group
    AND d.sex = r.sex
ORDER BY
    d.country,
    d.year,
    d.demographic_share_pct DESC;

# Table 3: concert_monthly_analysis
-- Monthly dataset meshing visitor growth with concert
-- intensity.

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
)
ORDER BY
    d.country,
    d.age_group,
    d.sex,
    d.year,
    d.month;

## Table 4: concert_statistical_results
-- Combine binary concert-month testing and concert-intensity
-- correlation testing into one output table.
-- binary_test_results and final_intensity_concert_analysis
-- are generated after Python/SciPy statistical tests.
-- ============================================================

SELECT
    b.country,
    b.age_group,
    b.sex,
    b.concert_months,
    b.no_concert_months,
    ROUND(
        b.concert_avg_yoy,
        2
    ) AS concert_avg_yoy,
    ROUND(
        b.no_concert_avg_yoy,
        2
    ) AS no_concert_avg_yoy,
    ROUND(
        b.uplift_pct_point,
        2
    ) AS uplift_pct_point,
    ROUND(
        b.t_statistic,
        3
    ) AS t_statistic,
    ROUND(
        b.p_value,
        4
    ) AS binary_p_value,
    ROUND(
        i.correlation,
        3
    ) AS correlation,
    ROUND(
        i.p_value,
        4
    ) AS intensity_p_value,
    i.observations,
    i.result AS intensity_result
FROM binary_test_results b
LEFT JOIN final_intensity_concert_analysis i
    ON b.country = i.country
    AND b.age_group = i.age_group
    AND b.sex = i.sex
ORDER BY
    b.country,
    b.age_group,
    b.sex;