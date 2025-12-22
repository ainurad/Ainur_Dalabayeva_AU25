
/* =============================================================================
   TASK 1

   Goal:
   - Analyze sales by region, year, and channel
   - Calculate:
       * AMOUNT_SOLD
       * % BY CHANNELS (share within region & year)
       * % PREVIOUS PERIOD (previous year)
       * % DIFF (year-over-year change)
   ============================================================================= */

WITH BaseSales AS (
    -- Aggregate sales by region, year, and channel
    SELECT 
        co.country_region,
        t.calendar_year,
        ch.channel_desc,
        SUM(s.amount_sold) AS amount_sold
    FROM sales s
    JOIN times t      ON s.time_id = t.time_id
    JOIN customers c  ON s.cust_id = c.cust_id
    JOIN countries co ON c.country_id = co.country_id
    JOIN channels ch  ON s.channel_id = ch.channel_id
    WHERE t.calendar_year BETWEEN 1999 AND 2001
      AND co.country_region IN ('Americas', 'Asia', 'Europe')
    GROUP BY 
        co.country_region,
        t.calendar_year,
        ch.channel_desc
),
PercentageCalc AS (
    -- Calculate percentage of total sales per channel
    -- Explicit window frame covers the entire region-year partition
    SELECT 
        country_region,
        calendar_year,
        channel_desc,
        amount_sold,
        amount_sold
        / SUM(amount_sold) OVER (
            PARTITION BY country_region, calendar_year
            ORDER BY channel_desc
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) * 100 AS pct_by_channels
    FROM BaseSales
)
SELECT 
    country_region,
    calendar_year,
    channel_desc,
    amount_sold AS AMOUNT_SOLD,
    ROUND(pct_by_channels, 2) AS "% BY CHANNELS",
    ROUND(
        LAG(pct_by_channels) OVER (
            PARTITION BY country_region, channel_desc
            ORDER BY calendar_year
        ),
        2
    ) AS "% PREVIOUS PERIOD",
    ROUND(
        pct_by_channels
        - LAG(pct_by_channels) OVER (
            PARTITION BY country_region, channel_desc
            ORDER BY calendar_year
        ),
        2
    ) AS "% DIFF"
FROM PercentageCalc
ORDER BY 
    country_region,
    calendar_year,
    channel_desc;


/* =============================================================================
   TASK 2

   Goal:
   - Show cumulative weekly sales (CUM_SUM)
   - Calculate a centered moving average with special rules:
       * Monday  -> Sat + Sun + Mon + Tue
       * Friday  -> Thu + Fri + Sat + Sun
       * Other days -> previous, current, next day
   ============================================================================= */

/* =============================================================================
   TASK 2: Weekly Sales Analysis (Weeks 49-51, 1999)
   Requirements:
   - Calculate CUM_SUM: Weekly cumulative sales total.
   - Calculate CENTERED_3_DAY_AVG: Centered moving average with specific logic 
     for Monday (Sat-Tue) and Friday (Thu-Sun).
   - Ensure boundary accuracy for the start of week 49 and end of week 51.
   ============================================================================= */

WITH DailyAggregated AS (
    -- Aggregating sales by day. Using a wider date range to ensure border accuracy.
    SELECT 
        t.time_id, 
        t.calendar_week_number,
        TRIM(TO_CHAR(t.time_id, 'Day')) AS day_name, 
        SUM(s.amount_sold) AS daily_amount
    FROM sh.sales s
    JOIN sh.times t ON s.time_id = t.time_id
    WHERE t.calendar_year IN (1999, 2000)
    GROUP BY t.time_id, t.calendar_week_number, t.day_name
)
SELECT 
    time_id,
    calendar_week_number,
    -- CUM_SUM: Resets at the beginning of each week.
    SUM(daily_amount) OVER (
        PARTITION BY calendar_week_number 
        ORDER BY time_id 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CUM_SUM,
    -- CENTERED_3_DAY_AVG: Special window frame logic based on the day of the week.
    CASE 
        WHEN day_name = 'Monday' THEN 
            -- Includes 2 preceding rows (Sat, Sun) and 1 following row (Tue).
            AVG(daily_amount) OVER (ORDER BY time_id ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING)
        WHEN day_name = 'Friday' THEN 
            -- Includes 1 preceding row (Thu) and 2 following rows (Sat, Sun).
            AVG(daily_amount) OVER (ORDER BY time_id ROWS BETWEEN 1 PRECEDING AND 2 FOLLOWING)
        ELSE 
            -- Standard 3-day window: Yesterday, Today, and Tomorrow.
            AVG(daily_amount) OVER (ORDER BY time_id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
    END AS CENTERED_3_DAY_AVG
FROM DailyAggregated
WHERE calendar_week_number BETWEEN 49 AND 51
  AND EXTRACT(YEAR FROM time_id) = 1999
ORDER BY time_id;

/* =============================================================================
   TASK 3

   Goal:
   - Show correct usage of:
       1) ROWS   (physical rows)
       2) RANGE  (logical time range)
       3) GROUPS (peer groups)
   ============================================================================= */

-- 1) ROWS Mode: Physical row-based window.
-- Reason: Chosen when you need a fixed number of records regardless of their values 
-- (e.g., exactly the last 5 transactions).
SELECT time_id, amount_sold,
    SUM(amount_sold) OVER (
        ORDER BY time_id 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) as rows_sum_last_5
FROM sh.sales
LIMIT 10;

-- 2) RANGE Mode: Logical value-based window (Time/Date).
-- Reason: Essential for time-series analysis where you need to include all 
-- records within a specific logical interval (e.g., the last 3 days).
SELECT time_id, amount_sold,
    SUM(amount_sold) OVER (
        ORDER BY time_id 
        RANGE BETWEEN INTERVAL '3' DAY PRECEDING AND CURRENT ROW
    ) as range_sum_3_days
FROM sh.sales
LIMIT 10;

-- 3) GROUPS Mode: Peer-group based window.
-- Reason: Used when rows with identical sort values (e.g., the same date) 
-- should be treated as a single unit. It counts the number of distinct groups 
-- rather than rows or values.
SELECT time_id, amount_sold,
    AVG(amount_sold) OVER (
        ORDER BY time_id 
        GROUPS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as groups_avg_last_3_dates
FROM sh.sales
LIMIT 10;
