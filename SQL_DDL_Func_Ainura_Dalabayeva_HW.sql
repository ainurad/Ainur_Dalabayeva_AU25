
/*******************************************************************************************
   TASK 1 — CREATE VIEW sales_revenue_by_category_qtr
   
*******************************************************************************************/
CREATE OR REPLACE VIEW public.sales_revenue_by_category_qtr AS
WITH current_period AS (
    SELECT 
        EXTRACT(QUARTER FROM CURRENT_DATE)::int AS qtr,
        EXTRACT(YEAR FROM CURRENT_DATE)::int AS yr
),
category_sales AS (
    SELECT 
        c.name AS category_name,
        SUM(p.amount) AS total_revenue
    FROM public.payment p
    INNER JOIN public.rental r ON p.rental_id = r.rental_id
    INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN public.film f ON i.film_id = f.film_id
    INNER JOIN public.film_category fc ON f.film_id = fc.film_id
    INNER JOIN public.category c ON fc.category_id = c.category_id
    CROSS JOIN current_period cp
    WHERE EXTRACT(QUARTER FROM p.payment_date) = cp.qtr
      AND EXTRACT(YEAR FROM p.payment_date) = cp.yr
    GROUP BY c.name
)
SELECT *
FROM category_sales
WHERE total_revenue > 0;

-- TEST CALL:
-- SELECT * FROM public.sales_revenue_by_category_qtr;

/*******************************************************************************************
   TASK 2 — QUERY LANGUAGE FUNCTION get_sales_revenue_by_category_qtr
   
*******************************************************************************************/
CREATE OR REPLACE FUNCTION public.get_sales_revenue_by_category_qtr(
    p_date date  -- updated input parameter
)
RETURNS TABLE(
    category_name text,
    total_revenue numeric
)
LANGUAGE sql
AS $$
    SELECT 
        c.name::text AS category_name,
        SUM(p.amount)::numeric AS total_revenue
    FROM public.payment p
    INNER JOIN public.rental r ON p.rental_id = r.rental_id
    INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN public.film f ON i.film_id = f.film_id
    INNER JOIN public.film_category fc ON f.film_id = fc.film_id
    INNER JOIN public.category c ON fc.category_id = c.category_id
    -- Extracted quarter and year from the passed date parameter to filter payments
    WHERE EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM p_date)
      AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM p_date)
    GROUP BY c.name
    HAVING SUM(p.amount) > 0;
$$;

-- TEST CALL (Example date):
-- SELECT * FROM public.get_sales_revenue_by_category_qtr('2017-05-01');
/*******************************************************************************************
   TASK 3 — FUNCTION: most_popular_films_by_countries
   
*******************************************************************************************/
CREATE OR REPLACE FUNCTION public.most_popular_films_by_countries(
    p_countries text[] -- Array of countries 
)
RETURNS TABLE(
    country text,
    film text,
    rating text,
    language text,
    length int,
    release_year int
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_missing_countries text[]; -- Variable to store invalid country names
BEGIN
    -- 1. Validation: Check if input countries exist in the database
    SELECT ARRAY_AGG(input_val)
    INTO v_missing_countries
    FROM UNNEST(p_countries) AS input_val
    WHERE UPPER(input_val) NOT IN (SELECT UPPER(c.country) FROM public.country c);

    -- 2. Notification: If there are invalid country names, raise a NOTICE
    IF v_missing_countries IS NOT NULL THEN
        RAISE NOTICE 'The following countries were not found in the database: %', array_to_string(v_missing_countries, ', ');
    END IF;

    -- 3.  Retrieve popular films
    RETURN QUERY
    WITH country_sales AS (
        SELECT 
            co.country::text AS country,
            f.title::text AS film,
            f.rating::text AS rating,
            l.name::text AS language,
            f.length::int,
            f.release_year::int,
            COUNT(*)::bigint AS rentals
        FROM public.rental r
        INNER JOIN public.customer cu ON r.customer_id = cu.customer_id
        INNER JOIN public.address a ON cu.address_id = a.address_id
        INNER JOIN public.city ci ON a.city_id = ci.city_id
        INNER JOIN public.country co ON ci.country_id = co.country_id
        INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
        INNER JOIN public.film f ON i.film_id = f.film_id
        INNER JOIN public.language l ON f.language_id = l.language_id
        -- Filter by country using case-insensitive comparison 
        WHERE UPPER(co.country) = ANY(SELECT UPPER(pc) FROM UNNEST(p_countries) pc)
        GROUP BY co.country, f.title, f.rating, l.name, f.length, f.release_year
    ),
    ranked AS (
        -- Rank films by rental count within each country
        SELECT 
            cs.*,
            RANK() OVER(PARTITION BY cs.country ORDER BY rentals DESC) AS rn
        FROM country_sales cs
    )
    -- Select only the #1 ranked film for each country
    SELECT rs.country, rs.film, rs.rating, rs.language, rs.length, rs.release_year
    FROM ranked rs
    WHERE rn = 1;
END;
$$;

-- TEST CALL:
-- SELECT * FROM public.most_popular_films_by_countries(ARRAY['Afghanistan', 'Brazil', 'Narnia']);


/*******************************************************************************************
   TASK 4 — FUNCTION: films_in_stock_by_title
   
*******************************************************************************************/
CREATE OR REPLACE FUNCTION public.films_in_stock_by_title(
    p_title text
)
RETURNS TABLE(
    row_num bigint,
    film_title text,
    language text,
    customer_name text,
    rental_date timestamp without time zone
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ROW_NUMBER() OVER (ORDER BY f.title, last_r.rental_date DESC) AS row_num,
        f.title::text,
        l.name::text,
        (c.first_name || ' ' || c.last_name)::text AS customer_name,
        last_r.rental_date
    FROM public.film f
    INNER JOIN public.language l ON f.language_id = l.language_id
    INNER JOIN public.inventory i ON f.film_id = i.film_id
    -- Fix: Use LATERAL to get ONLY the most recent rental for this specific inventory item
    LEFT JOIN LATERAL (
        SELECT r.rental_date, r.return_date, r.customer_id
        FROM public.rental r
        WHERE r.inventory_id = i.inventory_id
        ORDER BY r.rental_date DESC
        LIMIT 1
    ) last_r ON true
    LEFT JOIN public.customer c ON last_r.customer_id = c.customer_id
    WHERE 
        -- 1. Fix: Use UPPER/LIKE 
        UPPER(f.title) LIKE '%' || UPPER(p_title) || '%'
        
        -- 2. Fix: Ensure item is actually in stock
        AND (last_r.rental_date IS NULL OR last_r.return_date IS NOT NULL);

    -- Check if the query returned no rows and raise exception if empty
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Movie with title pattern "%" not found in stock history.', p_title;
    END IF;
END;
$$;

-- TEST CALL:
-- SELECT * FROM public.films_in_stock_by_title('LOVE');

/*******************************************************************************************
   TASK 5 — FUNCTION: new_movie

*******************************************************************************************/
CREATE OR REPLACE FUNCTION public.new_movie(
    p_title text,
    p_release_year int DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::int,
    p_language text DEFAULT 'Klingon'
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    lang_id int;
    v_new_film_id int; 
BEGIN
    -- 1. Check for duplicates
    IF EXISTS(SELECT 1 FROM public.film WHERE UPPER(title) = UPPER(p_title)) THEN
        RAISE NOTICE 'Film "%" already exists. Skipping insertion.', p_title;
        RETURN; 
    END IF;

    -- 2. Verify Language exists 
    SELECT language_id INTO lang_id
    FROM public.language
    WHERE UPPER(name) = UPPER(p_language);

    IF lang_id IS NULL THEN
        RAISE EXCEPTION 'Language "%" does not exist', p_language;
    END IF;

    -- 3. Generate ID Manually 
    SELECT COALESCE(MAX(film_id), 0) + 1 INTO v_new_film_id FROM public.film;
    
    INSERT INTO public.film(
        film_id,
        title,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        replacement_cost
    )
    VALUES(
        v_new_film_id, 
        p_title,
        p_release_year,
        lang_id,
        3,
        4.99,
        19.99
    );
END;
$$;

-- TEST CALL:
-- SELECT * FROM public.film WHERE title = 'Interstellar 2';
