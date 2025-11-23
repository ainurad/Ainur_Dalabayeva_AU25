
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
    JOIN public.rental r ON p.rental_id = r.rental_id
    JOIN public.inventory i ON r.inventory_id = i.inventory_id
    JOIN public.film f ON i.film_id = f.film_id
    JOIN public.film_category fc ON f.film_id = fc.film_id
    JOIN public.category c ON fc.category_id = c.category_id
    CROSS JOIN current_period cp
    WHERE EXTRACT(QUARTER FROM p.payment_date) = cp.qtr
      AND EXTRACT(YEAR FROM p.payment_date) = cp.yr
    GROUP BY c.name
)
SELECT *
FROM category_sales
WHERE total_revenue > 0;


/*******************************************************************************************
   TASK 2 — QUERY LANGUAGE FUNCTION get_sales_revenue_by_category_qtr
   
*******************************************************************************************/
CREATE OR REPLACE FUNCTION public.get_sales_revenue_by_category_qtr(
    p_qtr int,
    p_year int
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
    JOIN public.rental r ON p.rental_id = r.rental_id
    JOIN public.inventory i ON r.inventory_id = i.inventory_id
    JOIN public.film f ON i.film_id = f.film_id
    JOIN public.film_category fc ON f.film_id = fc.film_id
    JOIN public.category c ON fc.category_id = c.category_id
    WHERE EXTRACT(QUARTER FROM p.payment_date) = p_qtr
      AND EXTRACT(YEAR FROM p.payment_date) = p_year
    GROUP BY c.name
    HAVING SUM(p.amount) > 0;
$$;


/*******************************************************************************************
   TASK 3 — FUNCTION: most_popular_films_by_countries
   
*******************************************************************************************/
CREATE OR REPLACE FUNCTION public.most_popular_films_by_countries(
    countries text[]
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
BEGIN
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
        JOIN public.customer cu ON r.customer_id = cu.customer_id
        JOIN public.address a ON cu.address_id = a.address_id
        JOIN public.city ci ON a.city_id = ci.city_id
        JOIN public.country co ON ci.country_id = co.country_id
        JOIN public.inventory i ON r.inventory_id = i.inventory_id
        JOIN public.film f ON i.film_id = f.film_id
        JOIN public.language l ON f.language_id = l.language_id
        WHERE co.country = ANY(countries)
        GROUP BY co.country, f.title, f.rating, l.name, f.length, f.release_year
    ),
    ranked AS (
        SELECT 
            cs.*,
            RANK() OVER(PARTITION BY cs.country ORDER BY rentals DESC) AS rn
        FROM country_sales cs
    )
    SELECT rs.country, rs.film, rs.rating, rs.language, rs.length, rs.release_year
    FROM ranked rs
    WHERE rn = 1;
END;
$$;


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
    rental_date timestamp
)
LANGUAGE plpgsql
AS $$
DECLARE
    -- Variable to check if any rows were returned
    v_found boolean := false;
BEGIN
    -- loop through the query results to check existence and return them
    FOR row_num, film_title, language, customer_name, rental_date IN
        SELECT 
            ROW_NUMBER() OVER (ORDER BY r.rental_date) AS row_num,
            f.title::text,
            l.name::text,
            (cu.first_name || ' ' || cu.last_name)::text,
            r.rental_date
        FROM public.film f
        JOIN public.language l ON f.language_id = l.language_id
        JOIN public.inventory i ON f.film_id = i.film_id
        JOIN public.rental r ON i.inventory_id = r.inventory_id
        JOIN public.customer cu ON r.customer_id = cu.customer_id
        WHERE f.title ILIKE p_title
    LOOP
        v_found := true;
        RETURN NEXT;
    END LOOP;

    -- If the loop didn't run, no matches were found
    IF NOT v_found THEN
        RAISE EXCEPTION 'Movie with title pattern "%" not found in stock history.', p_title;
    END IF;
END;
$$;


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
    IF EXISTS(SELECT 1 FROM public.film WHERE title = p_title) THEN
        RAISE EXCEPTION 'Film "%" already exists', p_title;
    END IF;

    -- 2. Verify Language exists
    SELECT language_id INTO lang_id
    FROM public.language
    WHERE name = p_language;

    IF lang_id IS NULL THEN
        RAISE EXCEPTION 'Language "%" does not exist', p_language;
    END IF;

    -- 3. Generate ID Manually 
    SELECT COALESCE(MAX(film_id), 0) + 1 INTO v_new_film_id FROM public.film;

    -- 4. Insert
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