
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

WITH DailyAggregated AS (
    -- Aggregate sales at daily level
    -- Include adjacent weeks / year to handle borders correctly
    SELECT 
        t.calendar_year,
        t.calendar_date,
        t.calendar_week_number,
        t.day_name,
        SUM(s.amount_sold) AS daily_amount
    FROM sales s
    JOIN times t ON s.time_id = t.time_id
    WHERE t.calendar_year IN (1999, 2000)
    GROUP BY 
        t.calendar_year,
        t.calendar_date,
        t.calendar_week_number,
        t.day_name
)
SELECT 
    calendar_date,
    calendar_week_number,

    -- Cumulative sum of sales within the same year and week
    SUM(daily_amount) OVER (
        PARTITION BY calendar_year, calendar_week_number
        ORDER BY calendar_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CUM_SUM,

    -- Centered moving average with weekday-specific window frames
    CASE
        WHEN day_name = 'Monday' THEN
            AVG(daily_amount) OVER (
                ORDER BY calendar_date
                ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING
            )
        WHEN day_name = 'Friday' THEN
            AVG(daily_amount) OVER (
                ORDER BY calendar_date
                ROWS BETWEEN 1 PRECEDING AND 2 FOLLOWING
            )
        ELSE
            AVG(daily_amount) OVER (
                ORDER BY calendar_date
                ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
            )
    END AS CENTERED_3_DAY_AVG
FROM DailyAggregated
WHERE calendar_year = 1999
  AND calendar_week_number BETWEEN 49 AND 51
ORDER BY calendar_date;


/* =============================================================================
   TASK 3

   Goal:
   - Show correct usage of:
       1) ROWS   (physical rows)
       2) RANGE  (logical time range)
       3) GROUPS (peer groups)
   ============================================================================= */


-- ---------------------------------------------------------------------------
-- 1) ROWS FRAME
-- Physical row-based window.
-- Calculates a rolling sum over the last 5 rows.
-- ---------------------------------------------------------------------------
SELECT 
    t.calendar_date,
    s.amount_sold,
    SUM(s.amount_sold) OVER (
        ORDER BY t.calendar_date
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS sum_last_5_rows
FROM sales s
JOIN times t ON s.time_id = t.time_id;


-- ---------------------------------------------------------------------------
-- 2) RANGE FRAME
-- Logical time-based window.
-- Includes all sales from the last 3 calendar days.
-- ---------------------------------------------------------------------------
SELECT 
    t.calendar_date,
    s.amount_sold,
    SUM(s.amount_sold) OVER (
        ORDER BY t.calendar_date
        RANGE BETWEEN INTERVAL '3' DAY PRECEDING AND CURRENT ROW
    ) AS sum_last_3_days
FROM sales s
JOIN times t ON s.time_id = t.time_id;


-- ---------------------------------------------------------------------------
-- 3) GROUPS FRAME
-- Peer-group based window.
-- Treats each distinct date as a single group.
-- ---------------------------------------------------------------------------
SELECT 
    t.calendar_date,
    s.amount_sold,
    AVG(s.amount_sold) OVER (
        ORDER BY t.calendar_date
        GROUPS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS avg_last_3_distinct_days
FROM sales s
JOIN times t ON s.time_id = t.time_id;