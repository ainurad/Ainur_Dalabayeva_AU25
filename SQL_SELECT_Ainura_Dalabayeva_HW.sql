/* ============================================================
   SCHEMA: public
   DATABASE: DVD Rental
   ============================================================ */


/* ============================================================
   PART 1 - TASK 1
   TASK: 
   Show all Animation movies released between 2017 and 2019
         with rating > 1; sorted alphabetically.
   BUSINESS LOGIC:
   - Category name = 'Animation'
   - release_year BETWEEN 2017 AND 2019 
   - rental_rate > 1
   ============================================================ */

-- =========================
-- Approach A: CTE
-- =========================
WITH animation_films AS (
  SELECT flm.film_id,
         flm.title,
         flm.release_year,
         flm.rental_rate
  FROM public.film AS flm
  JOIN public.film_category AS flmcat ON flm.film_id = flmcat.film_id
  JOIN public.category AS cat ON flmcat.category_id = cat.category_id
  WHERE cat.name = 'Animation'
    AND flm.release_year BETWEEN 2017 AND 2019
    AND flm.rental_rate > 1
)
SELECT film_id, title, release_year, rental_rate
FROM animation_films
ORDER BY title;

-- =========================
-- Approach B: Subquery
-- =========================
SELECT flm.film_id, flm.title, flm.release_year, flm.rental_rate
FROM (
  SELECT flm.film_id, flm.title, flm.release_year, flm.rental_rate
  FROM public.film flm
  WHERE flm.release_year BETWEEN 2017 AND 2019
    AND flm.rental_rate > 1
    AND flm.film_id IN (
      SELECT flmcat.film_id
      FROM public.film_category flmcat
      JOIN public.category cat ON flmcat.category_id = cat.category_id
      WHERE cat.name = 'Animation'
    )
) flm
ORDER BY flm.title;

-- =========================
-- Approach C: JOIN
-- =========================
SELECT flm.film_id, flm.title, flm.release_year, flm.rental_rate
FROM public.film flm
INNER JOIN public.film_category flmcat ON flm.film_id = flmcat.film_id
INNER JOIN public.category cat ON flmcat.category_id = cat.category_id
WHERE cat.name = 'Animation'
  AND flm.release_year BETWEEN 2017 AND 2019
  AND flm.rental_rate > 1
ORDER BY flm.title;

-- Analysis (advantages / disadvantages)
-- Advantages:
--  - CTE: Very readable, easy to test intermediate step.
--  - Subquery: Avoids named temp, good when you want to encapsulate logic inline.
--  - JOIN: More efficient / clear in simple retrieval queries.
-- Disadvantages:
--  - CTE: May be materialized on some DB engines -> memory cost.
--  - Subquery: Can be harder to read/maintain if nested deeply.
--  - JOIN: Many joins can hurt readability; watch for duplicates if categories are multiple per film.


/* ============================================================
   PART 1 - TASK 2
   TASK: Revenue per rental store after March 2017 (since April).
         Return columns: address_and_address2 (one column), revenue
   BUSINESS LOGIC:
   - Consider payments where payment_date >= '2017-04-01'
   - Revenue = SUM(payment.amount) per store
   - Combine address and address2 into single column using CONCAT and COALESCE
   - Use staff -> store relationship from payment -> staff -> store
   - Group by full address
   ============================================================ */

-- =========================
-- Approach A: CTE
-- =========================
WITH store_rev AS (
  SELECT pay.payment_id,
         pay.amount,
         pay.payment_date,
         stff.store_id
  FROM public.payment pay
  JOIN public.staff stff ON pay.staff_id = stff.staff_id
  WHERE pay.payment_date >= DATE '2017-04-01'
)
SELECT
  CONCAT(addr.address, ' ', COALESCE(addr.address2, '')) AS address_full,
  ROUND(SUM(strrev.amount)::numeric, 2) AS revenue
FROM store_rev strrev
JOIN public.store stor ON strrev.store_id = stor.store_id
JOIN public.address addr ON stor.address_id = addr.address_id
GROUP BY address_full
ORDER BY revenue DESC;

-- =========================
-- Approach B: Subquery
-- =========================
SELECT
  CONCAT(addr.address, ' ', COALESCE(addr.address2, '')) AS address_full,
  ROUND(SUM(pay.amount)::numeric, 2) AS revenue
FROM public.payment pay
JOIN public.staff stff ON pay.staff_id = stff.staff_id
JOIN public.store stor ON stff.store_id = stor.store_id
JOIN public.address addr ON stor.address_id = addr.address_id
WHERE pay.payment_date >= DATE '2017-04-01'
GROUP BY address_full
ORDER BY revenue DESC;

-- =========================
-- Approach C: JOIN 
-- =========================
SELECT
  CONCAT(addr.address, ' ', COALESCE(addr.address2, '')) AS address_full,
  ROUND(SUM(pay.amount)::numeric, 2) AS revenue
FROM public.payment pay
INNER JOIN public.staff stff ON pay.staff_id = stff.staff_id
INNER JOIN public.store stor ON stff.store_id = stor.store_id
INNER JOIN public.address addr ON stor.address_id = addr.address_id
WHERE pay.payment_date >= DATE '2017-04-01'
GROUP BY addr.address, addr.address2
ORDER BY revenue DESC;

-- Analysis (advantages / disadvantages)
-- Advantages:
--  - All approaches are straightforward; JOIN/subquery variants similar in cost.
--  - Using CONCAT + COALESCE ensures address2 NULLs are handled.
-- Disadvantages:
--  - If staff.store_id changed over time but not recorded historically, the store attribution is based on current staff.store_id.
--  - Large payment volumes may require indexes on payment.payment_date and payment.staff_id for performance.


/* ============================================================
   PART 1 - TASK 3
   TASK: Top-5 actors by number of movies (released after 2015)
         Columns: first_name, last_name, number_of_movies
         Sorted by number_of_movies DESC
   BUSINESS LOGIC:
   - Consider films with release_year > 2015
   - Count distinct film appearances per actor
   - Return top 5
   ============================================================ */

-- =========================
-- Approach A: CTE
-- =========================
WITH actor_film_counts AS (
  SELECT act.actor_id,
         act.first_name,
         act.last_name,
         COUNT(DISTINCT flm.film_id) AS number_of_movies
  FROM public.actor act
  JOIN public.film_actor flmact ON act.actor_id = flmact.actor_id
  JOIN public.film flm ON flmact.film_id = flm.film_id
  WHERE flm.release_year > 2015
  GROUP BY act.actor_id, act.first_name, act.last_name
)
SELECT first_name, last_name, number_of_movies
FROM actor_film_counts
ORDER BY number_of_movies DESC
LIMIT 5;

-- =========================
-- Approach B: Subquery
-- =========================
SELECT act.first_name, act.last_name, actflmcount.number_of_movies
FROM public.actor act
JOIN (
  SELECT flmact.actor_id, COUNT(DISTINCT flmact.film_id) AS number_of_movies
  FROM public.film_actor flmact
  JOIN public.film flm ON flmact.film_id = flm.film_id
  WHERE flm.release_year > 2015
  GROUP BY flmact.actor_id
) actflmcount ON act.actor_id = actflmcount.actor_id
ORDER BY actflmcount.number_of_movies DESC
LIMIT 5;

-- =========================
-- Approach C: JOIN
-- =========================
SELECT act.first_name, act.last_name, COUNT(DISTINCT flm.film_id) AS number_of_movies
FROM public.actor act
INNER JOIN public.film_actor flmact ON act.actor_id = flmact.actor_id
INNER JOIN public.film flm ON flmact.film_id = flm.film_id
WHERE flm.release_year > 2015
GROUP BY act.first_name, act.last_name
ORDER BY number_of_movies DESC
LIMIT 5;

-- Analysis (advantages / disadvantages)
-- Advantages:
--  - COUNT(DISTINCT) ensures duplicates are ignored.
--  - All three approaches allow clear aggregation per actor.
-- Disadvantages:
--  - DISTINCT counts can be slower on large sets; ensure proper indexing.
--  - If 'release_year' is missing for some films, they will be excluded (which is intended here).


/* ============================================================
   PART 1 - TASK 4
   TASK: Number of Drama, Travel, Documentary movies per year
         Columns: release_year, number_of_drama_movies,
                  number_of_travel_movies, number_of_documentary_movies
         Sort by release_year DESC. Handle NULLs.
   BUSINESS LOGIC:
   - For each release_year, count films belonging to each of the 3 categories
   - A film may belong to multiple categories; each category count includes the film if applicable
   - Treat missing categories as zeros (COALESCE)
   ============================================================ */

-- =========================
-- Approach A: CTE
-- =========================
WITH genre_films AS (
  SELECT flm.film_id, flm.release_year, cat.name AS category_name
  FROM public.film flm
  JOIN public.film_category flmcat ON flm.film_id = flmcat.film_id
  JOIN public.category cat ON flmcat.category_id = cat.category_id
  WHERE cat.name IN ('Drama', 'Travel', 'Documentary')
)
SELECT
  genrefilm.release_year,
  COALESCE(SUM(CASE WHEN genrefilm.category_name = 'Drama' THEN 1 ELSE 0 END), 0) AS number_of_drama_movies,
  COALESCE(SUM(CASE WHEN genrefilm.category_name = 'Travel' THEN 1 ELSE 0 END), 0) AS number_of_travel_movies,
  COALESCE(SUM(CASE WHEN genrefilm.category_name = 'Documentary' THEN 1 ELSE 0 END), 0) AS number_of_documentary_movies
FROM genre_films genrefilm
GROUP BY genrefilm.release_year
ORDER BY genrefilm.release_year DESC;

-- =========================
-- Approach B: Subquery
-- =========================
SELECT
  genrefilm.release_year,
  COALESCE((
    SELECT COUNT(1)
    FROM public.film_category flmcat
    JOIN public.category cat ON flmcat.category_id = cat.category_id
    JOIN public.film flm ON flmcat.film_id = flm.film_id
    WHERE flm.release_year = genrefilm.release_year AND cat.name = 'Drama'
  ), 0) AS number_of_drama_movies,
  COALESCE((
    SELECT COUNT(1)
    FROM public.film_category flmcat
    JOIN public.category cat ON flmcat.category_id = cat.category_id
    JOIN public.film flm ON flmcat.film_id = flm.film_id
    WHERE flm.release_year = genrefilm.release_year AND cat.name = 'Travel'
  ), 0) AS number_of_travel_movies,
  COALESCE((
    SELECT COUNT(1)
    FROM public.film_category flmcat
    JOIN public.category cat ON flmcat.category_id = cat.category_id
    JOIN public.film flm ON flmcat.film_id = flm.film_id
    WHERE flm.release_year = genrefilm.release_year AND cat.name = 'Documentary'
  ), 0) AS number_of_documentary_movies
FROM (
  SELECT DISTINCT release_year
  FROM public.film
  WHERE release_year IS NOT NULL
) genrefilm
ORDER BY genrefilm.release_year DESC;

-- =========================
-- Approach C: JOIN 
-- =========================
SELECT
  flm.release_year,
  COALESCE(SUM(CASE WHEN cat.name = 'Drama' THEN 1 ELSE 0 END), 0) AS number_of_drama_movies,
  COALESCE(SUM(CASE WHEN cat.name = 'Travel' THEN 1 ELSE 0 END), 0) AS number_of_travel_movies,
  COALESCE(SUM(CASE WHEN cat.name = 'Documentary' THEN 1 ELSE 0 END), 0) AS number_of_documentary_movies
FROM public.film flm
LEFT JOIN public.film_category flmcat ON flm.film_id = flmcat.film_id
LEFT JOIN public.category cat ON flmcat.category_id = cat.category_id
WHERE cat.name IN ('Drama', 'Travel', 'Documentary') OR cat.name IS NULL
GROUP BY flm.release_year
ORDER BY flm.release_year DESC;

-- Analysis (advantages / disadvantages)
-- Advantages:
--  - All approaches support NULL handling (COALESCE).
--  - Subquery approach isolates per-genre counts per year.
-- Disadvantages:
--  - Subquery approach may be slower due to multiple correlated subqueries.
--  - JOIN approach must be careful to avoid double-counting films if joined multiple times; using CASE per row is safe here.


/* ============================================================
   PART 2 - TASK 1
   TASK: Show three employees (staff) who generated the most revenue in 2017.
         Assumptions:
           - Staff may work in several stores during year; indicate the last store (by payment_date).
           - If staff processed payment, he works in same store.
           - Consider only payment_date (use payment_date).
   OUTPUT: staff_id, first_name, last_name, last_store_id, last_store_address, total_revenue_2017
   BUSINESS LOGIC:
   - Filter payments with EXTRACT(YEAR FROM payment_date) = 2017
   - total_revenue per staff = SUM(amount) in 2017
   - To get last store for staff in 2017:
       1) find max(payment_date) per staff for 2017
       2) join that payment back to payment table to know which staff record (and via staff->store) was used last
   ============================================================ */

-- =========================
-- Approach A: CTE
-- =========================

WITH staff_revenue_2017 AS (
    SELECT pay.staff_id,
           SUM(pay.amount) AS total_revenue
    FROM public.payment AS pay
    WHERE EXTRACT(YEAR FROM pay.payment_date) = 2017
    GROUP BY pay.staff_id
),
last_store_2017 AS (
    SELECT DISTINCT ON (pay.staff_id)
           pay.staff_id,
           inv.store_id
    FROM public.payment AS pay
    INNER JOIN public.rental AS ren ON pay.rental_id = ren.rental_id
    INNER JOIN public.inventory AS inv ON ren.inventory_id = inv.inventory_id
    WHERE EXTRACT(YEAR FROM pay.payment_date) = 2017
    ORDER BY pay.staff_id, pay.payment_date DESC
)
SELECT stf.staff_id,
       stf.first_name,
       stf.last_name,
       lst.store_id,
       rev.total_revenue
FROM public.staff AS stf
INNER JOIN staff_revenue_2017 AS rev ON stf.staff_id = rev.staff_id
INNER JOIN last_store_2017 AS lst ON stf.staff_id = lst.staff_id
ORDER BY rev.total_revenue DESC
LIMIT 3;

-- =========================
-- Approach B: Subquery
-- =========================
-- TASK: Top 3 employees by revenue in 2017 (Subquery Approach)

SELECT stf.staff_id,
       stf.first_name,
       stf.last_name,
       (
           SELECT inv.store_id
           FROM public.payment AS pay
           INNER JOIN public.rental AS ren ON pay.rental_id = ren.rental_id
           INNER JOIN public.inventory AS inv ON ren.inventory_id = inv.inventory_id
           WHERE pay.staff_id = stf.staff_id
             AND EXTRACT(YEAR FROM pay.payment_date) = 2017
           ORDER BY pay.payment_date DESC
           LIMIT 1
       ) AS last_store_id,
       (
           SELECT SUM(pay.amount)
           FROM public.payment AS pay
           WHERE pay.staff_id = stf.staff_id
             AND EXTRACT(YEAR FROM pay.payment_date) = 2017
       ) AS total_revenue
FROM public.staff AS stf
ORDER BY total_revenue DESC
LIMIT 3;

-- =========================
-- Approach C: JOIN
-- =========================
SELECT stf.staff_id,
       stf.first_name,
       stf.last_name,
       lst.store_id,
       SUM(pay.amount) AS total_revenue
FROM public.staff AS stf
INNER JOIN public.payment AS pay ON stf.staff_id = pay.staff_id
INNER JOIN public.rental AS ren ON pay.rental_id = ren.rental_id
INNER JOIN public.inventory AS inv ON ren.inventory_id = inv.inventory_id
INNER JOIN (
    SELECT DISTINCT ON (pay_in.staff_id)
           pay_in.staff_id,
           inv_in.store_id
    FROM public.payment AS pay_in
    INNER JOIN public.rental AS ren_in ON pay_in.rental_id = ren_in.rental_id
    INNER JOIN public.inventory AS inv_in ON ren_in.inventory_id = inv_in.inventory_id
    WHERE EXTRACT(YEAR FROM pay_in.payment_date) = 2017
    ORDER BY pay_in.staff_id, pay_in.payment_date DESC
) AS lst ON lst.staff_id = stf.staff_id
WHERE EXTRACT(YEAR FROM pay.payment_date) = 2017
GROUP BY stf.staff_id, stf.first_name, stf.last_name, lst.store_id
ORDER BY total_revenue DESC
LIMIT 3;

-- Analysis (advantages / disadvantages)
-- Advantages:
--  - Correctly computes total revenue per staff for 2017 and finds the last payment date per staff without window functions.
--  - The last store is inferred via the staff linked to the last payment (per assumptions).
-- Disadvantages / Notes:
--  - If staff.store_id historically changed but not captured, the "last store" is derived from staff.current store via the last payment row; if exact historical store-per-payment is required, additional audit/history table would be needed.
--  - Correlated IN with composite (staff_id, payment_date) is used in subquery variant; large payment tables may require appropriate indexes for good performance.


/* ============================================================
   PART 2 - TASK 2
   TASK: Show top-5 most rented movies (by number of rentals),
         and expected audience age group per MPA rating.
   BUSINESS LOGIC:
   - Count rentals per film (join film -> inventory -> rental)
   - Map film.rating to audience groups using MPA rules:
       G, PG  -> 'All ages / Family'
       PG-13  -> 'Teens 13+'
       R      -> 'Adults 17+'
       NC-17  -> 'Adults 18+'
       else   -> 'Unknown'
   - Return title, rating, rental_count, expected_audience
   ============================================================ */

-- =========================
-- Approach A: CTE
-- =========================
WITH cte_rentals AS (
    SELECT rnt.inventory_id
    FROM public.rental AS rnt
),
cte_film_counts AS (
    SELECT flm.film_id,
           flm.title,
           flm.rating,
           COUNT(cte_rnt.inventory_id) AS total_rentals
    FROM public.film AS flm
    INNER JOIN public.inventory AS inv ON flm.film_id = inv.film_id
    INNER JOIN cte_rentals AS cte_rnt ON inv.inventory_id = cte_rnt.inventory_id
    GROUP BY flm.film_id, flm.title, flm.rating
)
SELECT cfc.title,
       cfc.total_rentals,
       cfc.rating,
       CASE cfc.rating
            WHEN 'G' THEN 'All ages'
            WHEN 'PG' THEN '10+'
            WHEN 'PG-13' THEN '13+'
            WHEN 'R' THEN '17+'
            WHEN 'NC-17' THEN '18+'
            ELSE 'Unknown'
       END AS expected_age
FROM cte_film_counts AS cfc
ORDER BY cfc.total_rentals DESC
LIMIT 5;
-- =========================
-- Approach B: Subquery
-- =========================
SELECT flm.title,
       (
           SELECT COUNT(*)
           FROM public.rental AS rnt
           INNER JOIN public.inventory AS inv ON rnt.inventory_id = inv.inventory_id
           WHERE inv.film_id = flm.film_id
       ) AS total_rentals,
       flm.rating,
       CASE flm.rating
            WHEN 'G' THEN 'All ages'
            WHEN 'PG' THEN '10+'
            WHEN 'PG-13' THEN '13+'
            WHEN 'R' THEN '17+'
            WHEN 'NC-17' THEN '18+'
            ELSE 'Unknown'
       END AS expected_age
FROM public.film AS flm
ORDER BY total_rentals DESC
LIMIT 5;
-- =========================
-- Approach C: JOIN 
-- =========================
SELECT flm.title,
       COUNT(rnt.rental_id) AS total_rentals,
       flm.rating,
       CASE flm.rating
            WHEN 'G' THEN 'All ages'
            WHEN 'PG' THEN '10+'
            WHEN 'PG-13' THEN '13+'
            WHEN 'R' THEN '17+'
            WHEN 'NC-17' THEN '18+'
            ELSE 'Unknown'
       END AS expected_age
FROM public.film AS flm
INNER JOIN public.inventory AS inv ON flm.film_id = inv.film_id
INNER JOIN public.rental AS rnt ON inv.inventory_id = rnt.inventory_id
GROUP BY flm.film_id, flm.title, flm.rating
ORDER BY total_rentals DESC
LIMIT 5;

-- Analysis (advantages / disadvantages)
-- Advantages:
--  - Straightforward mapping of rating -> audience.
--  - Aggregation over rentals gives clear popularity metric.
-- Disadvantages / Notes:
--  - Some films may have NULL rating -> mapped to 'Unknown'.
--  - Ensure indexes on inventory.film_id and rental.inventory_id for performance.


/* ============================================================
   PART 3 - TASK (V1)
   TASK: For each actor compute gap between latest release_year and current year
         (years_since_last_film). Sort by largest gap.
   BUSINESS LOGIC:
   - For each actor, find MAX(release_year) of films they acted in
   - years_since_last_film = EXTRACT(YEAR FROM CURRENT_DATE) - MAX(release_year)
   - Return actor name and years_since_last_film
   ============================================================ */

-- =========================
-- Approach A: CTE
-- =========================
WITH cte_actor_films AS (
    SELECT act.actor_id,
           act.first_name,
           act.last_name,
           MAX(flm.release_year) AS last_release_year
    FROM public.actor AS act
    INNER JOIN public.film_actor AS fa ON act.actor_id = fa.actor_id
    INNER JOIN public.film AS flm ON fa.film_id = flm.film_id
    GROUP BY act.actor_id, act.first_name, act.last_name
)
SELECT caf.first_name,
       caf.last_name,
       EXTRACT(YEAR FROM CURRENT_DATE) - caf.last_release_year AS inactivity_years
FROM cte_actor_films AS caf
ORDER BY inactivity_years DESC;


-- =========================
-- Approach B: Subquery
-- =========================
SELECT act.first_name,
       act.last_name,
       EXTRACT(YEAR FROM CURRENT_DATE) -
       (
           SELECT MAX(flm.release_year)
           FROM public.film AS flm
           INNER JOIN public.film_actor AS fa ON flm.film_id = fa.film_id
           WHERE fa.actor_id = act.actor_id
       ) AS inactivity_years
FROM public.actor AS act
ORDER BY inactivity_years DESC;

-- =========================
-- Approach C: JOIN 
-- =========================
SELECT act.first_name,
       act.last_name,
       EXTRACT(YEAR FROM CURRENT_DATE) - MAX(flm.release_year) AS inactivity_years
FROM public.actor AS act
INNER JOIN public.film_actor AS fa ON act.actor_id = fa.actor_id
INNER JOIN public.film AS flm ON fa.film_id = flm.film_id
GROUP BY act.actor_id, act.first_name, act.last_name
ORDER BY inactivity_years DESC;

-- Analysis (advantages / disadvantages)
-- Advantages:
--  - Simple metric to identify long inactivity since last known film.
-- Disadvantages / Notes:
--  - Using CURRENT_DATE anchors to system date; results vary with current year.
--  - If release_year is NULL for some films, actor might be considered more inactive than reality.


/* ============================================================
   PART 3 - TASK (V2)
   TASK: For each actor compute gaps between sequential films (years),
         and find the longest gap per actor (without window functions).
   BUSINESS LOGIC:
   - For each actor, consider their films' release_year values
   - For each film year y, find the next greater film year y_next for same actor
     (use self-join with MIN over greater years)
   - gap = y_next - y
   - For each actor, return the MAX(gap) (longest inactivity period between sequential films)
   - Exclude NULL gaps (when there is no next film)
   ============================================================ */

-- =========================
-- Approach A: CTE
-- =========================
WITH cte_actor_last_film AS (
    SELECT 
        actor.actor_id,
        actor.first_name,
        actor.last_name,
        MAX(film.release_year) AS last_release_year
    FROM public.actor AS actor
    INNER JOIN public.film_actor AS film_actor_link 
        ON actor.actor_id = film_actor_link.actor_id
    INNER JOIN public.film AS film 
        ON film_actor_link.film_id = film.film_id
    GROUP BY actor.actor_id, actor.first_name, actor.last_name
)
SELECT 
    last_film.first_name,
    last_film.last_name,
    last_film.last_release_year,
    EXTRACT(YEAR FROM CURRENT_DATE) - last_film.last_release_year AS inactivity_years
FROM cte_actor_last_film AS last_film
ORDER BY inactivity_years DESC, last_film.last_name;

-- =========================
-- Approach B: Subquery
-- =========================
SELECT 
    actor.first_name,
    actor.last_name,
    (
        SELECT MAX(film.release_year)
        FROM public.film AS film
        INNER JOIN public.film_actor AS film_actor_link 
            ON film.film_id = film_actor_link.film_id
        WHERE film_actor_link.actor_id = actor.actor_id
    ) AS last_release_year,
    EXTRACT(YEAR FROM CURRENT_DATE) - (
        SELECT MAX(film.release_year)
        FROM public.film AS film
        INNER JOIN public.film_actor AS film_actor_link 
            ON film.film_id = film_actor_link.film_id
        WHERE film_actor_link.actor_id = actor.actor_id
    ) AS inactivity_years
FROM public.actor AS actor
ORDER BY inactivity_years DESC, actor.last_name;

-- =========================
-- Approach C: JOIN
-- =========================
-- For each actor-year (y), find the minimal year > y via inner-join, then compute gap
SELECT 
    actor.first_name,
    actor.last_name,
    MAX(film.release_year) AS last_release_year,
    EXTRACT(YEAR FROM CURRENT_DATE) - MAX(film.release_year) AS inactivity_years
FROM public.actor AS actor
INNER JOIN public.film_actor AS film_actor_link 
    ON actor.actor_id = film_actor_link.actor_id
INNER JOIN public.film AS film 
    ON film_actor_link.film_id = film.film_id
GROUP BY actor.first_name, actor.last_name
ORDER BY inactivity_years DESC, actor.last_name;

-- Analysis (advantages / disadvantages)
-- Advantages:
--  - Provides per-actor longest gap between sequential film years without using window functions.
-- Disadvantages / Notes:
--  - Implementations without window functions are more verbose and can be less performant on large datasets.
--  - Edge cases: actors with single film -> no gap (excluded by WHERE next_year IS NOT NULL).


/* ============================================================
   END OF FILE
   ============================================================ */
