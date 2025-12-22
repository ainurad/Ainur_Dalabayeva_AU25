/*****************************************************************
 TASK 1 
 Top 5 Customers by Sales Percentage Within Each Channel  
******************************************************************/

/*
ANALYSIS (Task 1):
The objective is to identify the top 5 customers per channel based on their sales contribution.
This requires a multi-stage approach using window functions:
1. Sales Calculation: Aggregate customer sales and concurrently calculate the total channel sales 
   using SUM() OVER (PARTITION BY...).
2. Ranking: Apply ROW_NUMBER() to assign a unique rank within each channel, ordered by sales DESC.
3. Filtering: The rank is used in the WHERE clause (in a subsequent CTE/query) to select the Top 5, 
   as window functions cannot be used directly in the WHERE clause.
*/

WITH CustomerSales AS (
    -- Step 1: Calculate customer-level sales and concurrent total channel sales for KPI denominator
    SELECT
        ch.channel_id, -- Fixed: Use unique channel ID for partitioning
        ch.channel_desc,
        cu.cust_id, -- Fixed: Use unique ID to prevent merging customers with same names
        cu.cust_last_name,
        cu.cust_first_name,
        SUM(s.amount_sold) AS customer_sales,
        -- Fixed: Use SUM(SUM(...)) for window function over aggregate
        SUM(SUM(s.amount_sold)) OVER (PARTITION BY ch.channel_id)
            AS total_channel_sales
    FROM sh.sales s
    INNER JOIN sh.customers cu ON s.cust_id = cu.cust_id
    INNER JOIN sh.channels ch ON s.channel_id = ch.channel_id
    GROUP BY ch.channel_id, ch.channel_desc, cu.cust_id, cu.cust_last_name, cu.cust_first_name
),

RankedCustomers AS (
    -- Step 2: Assign row numbers to identify the top 5 within each channel
    SELECT
        cs.*,
        ROW_NUMBER() OVER (
            PARTITION BY cs.channel_id -- Fixed: Partition by unique ID
            ORDER BY cs.customer_sales DESC
        ) AS rank_num
    FROM CustomerSales cs
)

SELECT
    rc.channel_desc,
    rc.cust_last_name,
    rc.cust_first_name,
    TO_CHAR(rc.customer_sales, 'FM999,999,999.00') AS amount_sold,
    TO_CHAR((rc.customer_sales / rc.total_channel_sales) * 100, 'FM99.9999') || '%'
        AS sales_percentage
FROM RankedCustomers rc
WHERE rc.rank_num <= 5
ORDER BY rc.channel_id, rc.rank_num;


/*****************************************************************
 TASK 2  
 Pivot Table: Photo Category Sales in Asia (Year 2000) 
******************************************************************/

/*
ANALYSIS (Task 2):
This task involves creating a pivot table where quarters (Q1-Q4) are columns, and calculating the YEAR_SUM.
The pivot transformation is achieved using Conditional Aggregation (SUM with CASE WHEN).

1. Data Filtering: Filter sales data based on specific criteria (Photo, Asia, 2000).
2. Pivoting: Use SUM(CASE WHEN quarter = X) to transform row-level quarterly data into columnar format.
3. Calculation: Calculate the total YEAR_SUM as the total aggregated sales for the product.
*/

WITH ProductSales AS (
    -- Step 1: Filter data by Photo category, Asia region, and year 2000
    SELECT
        p.prod_name,
        t.calendar_quarter_number AS quarter,
        s.amount_sold
    FROM sh.sales s
    INNER JOIN sh.products p ON s.prod_id = p.prod_id
    INNER JOIN sh.times t ON s.time_id = t.time_id
    INNER JOIN sh.customers c ON s.cust_id = c.cust_id
    INNER JOIN sh.countries co ON c.country_id = co.country_id
    WHERE p.prod_category = 'Photo'
      AND co.country_region = 'Asia'
      AND t.calendar_year = 2000
)

SELECT
    ps.prod_name AS product_name,

    -- Fixed: Removed redundant q_raw columns
    -- Formatted columns for the final report
    TO_CHAR(SUM(CASE WHEN ps.quarter = 1 THEN ps.amount_sold ELSE 0 END), 'FM999,999.00') AS q1,
    TO_CHAR(SUM(CASE WHEN ps.quarter = 2 THEN ps.amount_sold ELSE 0 END), 'FM999,999.00') AS q2,
    TO_CHAR(SUM(CASE WHEN ps.quarter = 3 THEN ps.amount_sold ELSE 0 END), 'FM999,999.00') AS q3,
    TO_CHAR(SUM(CASE WHEN ps.quarter = 4 THEN ps.amount_sold ELSE 0 END), 'FM999,999.00') AS q4,

    -- Yearly totals
    -- Fixed: Added window function for year_sum calculation
    TO_CHAR(SUM(SUM(ps.amount_sold)) OVER (PARTITION BY ps.prod_name), 'FM999,999.00') AS year_sum,
    SUM(SUM(ps.amount_sold)) OVER (PARTITION BY ps.prod_name) AS year_sum_for_sort
FROM ProductSales ps
GROUP BY ps.prod_name
ORDER BY year_sum_for_sort DESC;


/*****************************************************************
 TASK 3  
 Channel-Based Sales Report for the Top 300 Customers 
******************************************************************/

/*
ANALYSIS (Task 3):
This task requires multi-stage filtering: identifying the Top-300 customers based on aggregate sales 
before detailing their transactions by channel. This structure avoids using the RANK() function 
in the HAVING clause, which is prohibited.

1. CustomerTotals: Aggregates total sales for all customers over the required years (1998, 1999, 2001).
2. RankedCustomers: Calculates the RANK() based on the total sales.
3. Top300: Filters the ranked list to obtain the set of customer IDs (cust_id) belonging to the Top-300.
4. ChannelSales: Joins the Top-300 list back to the sales data to aggregate sales by channel.
*/

WITH CustomerTotals AS (
    -- Step 1: Calculate total sales for each customer for the required years
    SELECT
        s.cust_id, -- Fixed: Grouping by cust_id for unique identification
        cu.cust_last_name,
        cu.cust_first_name,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    INNER JOIN sh.customers cu ON s.cust_id = cu.cust_id
    INNER JOIN sh.times t ON s.time_id = t.time_id
    WHERE t.calendar_year IN (1998, 1999, 2001)
    GROUP BY s.cust_id, cu.cust_last_name, cu.cust_first_name
),

RankedCustomers AS (
    -- Step 2: Rank customers based on total sales
    SELECT
        ct.*,
        RANK() OVER (ORDER BY ct.total_sales DESC) AS rank_num
    FROM CustomerTotals ct
),

Top300 AS (
    -- Step 3: Filter the ranked list to obtain the IDs of the top 300 customers
    SELECT
        cust_id,
        cust_last_name,
        cust_first_name
    FROM RankedCustomers
    WHERE rank_num <= 300
),

ChannelSales AS (
    -- Step 4: Calculate per-channel sales only for the selected top 300 customers
    SELECT
        ch.channel_id, -- Fixed: Use channel_id in grouping
        ch.channel_desc,
        t3.cust_id,
        t3.cust_last_name,
        t3.cust_first_name,
        SUM(s.amount_sold) AS amount_sold
    FROM sh.sales s
    INNER JOIN sh.channels ch ON s.channel_id = ch.channel_id
    INNER JOIN sh.times t ON s.time_id = t.time_id
    INNER JOIN Top300 t3 ON s.cust_id = t3.cust_id
    WHERE t.calendar_year IN (1998, 1999, 2001)
    GROUP BY ch.channel_id, ch.channel_desc, t3.cust_id, t3.cust_last_name, t3.cust_first_name
)

SELECT
    cs.channel_desc,
    cs.cust_id,
    cs.cust_last_name,
    cs.cust_first_name,
    TO_CHAR(cs.amount_sold, 'FM999,999,999.00') AS amount_sold
FROM ChannelSales cs
ORDER BY cs.channel_id, cs.amount_sold DESC;


/*****************************************************************
 TASK 4 
 Sales Report for Europe + Americas (Jan–Mar 2000), by Category
******************************************************************/

/*
ANALYSIS (Task 4):
This task requires generating a pivot report comparing sales between 'Europe' and 'Americas' 
for Q1 2000, broken down by month and product category.

1. Data Filtering: Filter sales data for Q1 2000 and the two target regions.
2. Pivoting: Use Conditional Aggregation (SUM with CASE WHEN) to transform region rows into 'Americas SALES' and 'Europe SALES' columns.
3. Sorting: Use the numerical month number (calendar_month_number) to ensure correct chronological sorting.
*/

WITH BaseSales AS (
    -- Step 1: Filter data for Q1 2000 and the two target regions
    SELECT
        t.calendar_month_desc,
        t.calendar_month_number,
        p.prod_category,
        s.amount_sold,
        co.country_region
    FROM sh.sales s
    INNER JOIN sh.products p ON s.prod_id = p.prod_id
    INNER JOIN sh.times t ON s.time_id = t.time_id
    INNER JOIN sh.customers c ON s.cust_id = c.cust_id
    INNER JOIN sh.countries co ON c.country_id = co.country_id
    WHERE t.calendar_year = 2000
      AND t.calendar_month_number IN (1, 2, 3)
      AND co.country_region IN ('Europe', 'Americas')
)

SELECT
    bs.calendar_month_desc,
    bs.prod_category,
    TO_CHAR(
        SUM(CASE WHEN bs.country_region = 'Americas'
                    THEN bs.amount_sold ELSE 0 END),
        'FM999,999.00'
    ) AS americas_sales,
    TO_CHAR(
        SUM(CASE WHEN bs.country_region = 'Europe'
                    THEN bs.amount_sold ELSE 0 END),
        'FM999,999.00'
    ) AS europe_sales
FROM BaseSales bs
GROUP BY bs.calendar_month_desc, bs.calendar_month_number, bs.prod_category
ORDER BY bs.calendar_month_number, bs.prod_category;
