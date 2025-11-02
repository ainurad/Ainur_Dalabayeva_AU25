/* ============================================================
   SCHEMA: public
   DATABASE: DVD Rental
   ============================================================ */


/* ============================================================
   PART 1 - TASK 1
   TASK: 
   Show all Animation movies released between 2017 and 2019
         with rating > 1; sorted alphabetically (title).
   BUSINESS LOGIC:
   - Category name = 'Animation'
   - release_year BETWEEN 2017 AND 2019 
   - rental_rate > 1
   ============================================================ */

-- =========================
-- Approach A: CTE
-- =========================
WITH animation_films AS (
  SELECT f.film_id,
         f.title,
         f.release_year,
         f.rental_rate
  FROM public.film f
  JOIN public.film_category fc ON f.film_id = fc.film_id
  JOIN public.category c ON fc.category_id = c.category_id
  WHERE c.name = 'Animation'
    AND f.release_year BETWEEN 2017 AND 2019
    AND f.rental_rate > 1
)
SELECT film_id, title, release_year, rental_rate
FROM animation_films
ORDER BY title;

-- =========================
-- Approach B: Subquery
-- =========================
SELECT sq.film_id, sq.title, sq.release_year, sq.rental_rate
FROM (
  SELECT f.film_id, f.title, f.release_year, f.rental_rate
  FROM public.film f
  WHERE f.release_year BETWEEN 2017 AND 2019
    AND f.rental_rate > 1
    AND f.film_id IN (
      SELECT fc.film_id
      FROM public.film_category fc
      JOIN public.category c ON fc.category_id = c.category_id
      WHERE c.name = 'Animation'
    )
) sq
ORDER BY sq.title;

-- =========================
-- Approach C: JOIN
-- =========================
SELECT f.film_id, f.title, f.release_year, f.rental_rate
FROM public.film f
INNER JOIN public.film_category fc ON f.film_id = fc.film_id
INNER JOIN public.category c ON fc.category_id = c.category_id
WHERE c.name = 'Animation'
  AND f.release_year BETWEEN 2017 AND 2019
  AND f.rental_rate > 1
ORDER BY f.title;

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
WITH payments_after_2017 AS (
  SELECT p.payment_id,
         p.amount,
         p.payment_date,
         st.store_id
  FROM public.payment p
  JOIN public.staff st ON p.staff_id = st.staff_id
  WHERE p.payment_date >= DATE '2017-04-01'
)
SELECT
  CONCAT(a.address, ' ', COALESCE(a.address2, '')) AS address_full,
  ROUND(SUM(pa.amount)::numeric, 2) AS revenue
FROM payments_after_2017 pa
JOIN public.store s ON pa.store_id = s.store_id
JOIN public.address a ON s.address_id = a.address_id
GROUP BY address_full
ORDER BY revenue DESC;

-- =========================
-- Approach B: Subquery
-- =========================
SELECT
  CONCAT(a.address, ' ', COALESCE(a.address2, '')) AS address_full,
  ROUND(SUM(p.amount)::numeric, 2) AS revenue
FROM public.payment p
JOIN public.staff st ON p.staff_id = st.staff_id
JOIN public.store s ON st.store_id = s.store_id
JOIN public.address a ON s.address_id = a.address_id
WHERE p.payment_date >= DATE '2017-04-01'
GROUP BY address_full
ORDER BY revenue DESC;

-- =========================
-- Approach C: JOIN 
-- =========================
SELECT
  CONCAT(a.address, ' ', COALESCE(a.address2, '')) AS address_full,
  ROUND(SUM(p.amount)::numeric, 2) AS revenue
FROM public.payment p
INNER JOIN public.staff st ON p.staff_id = st.staff_id
INNER JOIN public.store s ON st.store_id = s.store_id
INNER JOIN public.address a ON s.address_id = a.address_id
WHERE p.payment_date >= DATE '2017-04-01'
GROUP BY a.address, a.address2
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
  SELECT a.actor_id,
         a.first_name,
         a.last_name,
         COUNT(DISTINCT f.film_id) AS number_of_movies
  FROM public.actor a
  JOIN public.film_actor fa ON a.actor_id = fa.actor_id
  JOIN public.film f ON fa.film_id = f.film_id
  WHERE f.release_year > 2015
  GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT first_name, last_name, number_of_movies
FROM actor_film_counts
ORDER BY number_of_movies DESC
LIMIT 5;

-- =========================
-- Approach B: Subquery
-- =========================
SELECT a.first_name, a.last_name, afc.number_of_movies
FROM public.actor a
JOIN (
  SELECT fa.actor_id, COUNT(DISTINCT fa.film_id) AS number_of_movies
  FROM public.film_actor fa
  JOIN public.film f ON fa.film_id = f.film_id
  WHERE f.release_year > 2015
  GROUP BY fa.actor_id
) afc ON a.actor_id = afc.actor_id
ORDER BY afc.number_of_movies DESC
LIMIT 5;

-- =========================
-- Approach C: JOIN
-- =========================
SELECT a.first_name, a.last_name, COUNT(DISTINCT f.film_id) AS number_of_movies
FROM public.actor a
INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN public.film f ON fa.film_id = f.film_id
WHERE f.release_year > 2015
GROUP BY a.first_name, a.last_name
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
  SELECT f.film_id, f.release_year, c.name AS category_name
  FROM public.film f
  JOIN public.film_category fc ON f.film_id = fc.film_id
  JOIN public.category c ON fc.category_id = c.category_id
  WHERE c.name IN ('Drama', 'Travel', 'Documentary')
)
SELECT
  gf.release_year,
  COALESCE(SUM(CASE WHEN gf.category_name = 'Drama' THEN 1 ELSE 0 END), 0) AS number_of_drama_movies,
  COALESCE(SUM(CASE WHEN gf.category_name = 'Travel' THEN 1 ELSE 0 END), 0) AS number_of_travel_movies,
  COALESCE(SUM(CASE WHEN gf.category_name = 'Documentary' THEN 1 ELSE 0 END), 0) AS number_of_documentary_movies
FROM genre_films gf
GROUP BY gf.release_year
ORDER BY gf.release_year DESC;

-- =========================
-- Approach B: Subquery
-- =========================
SELECT
  f.release_year,
  COALESCE((
    SELECT COUNT(1)
    FROM public.film_category fc2
    JOIN public.category c2 ON fc2.category_id = c2.category_id
    JOIN public.film f2 ON fc2.film_id = f2.film_id
    WHERE f2.release_year = f.release_year AND c2.name = 'Drama'
  ), 0) AS number_of_drama_movies,
  COALESCE((
    SELECT COUNT(1)
    FROM public.film_category fc2
    JOIN public.category c2 ON fc2.category_id = c2.category_id
    JOIN public.film f2 ON fc2.film_id = f2.film_id
    WHERE f2.release_year = f.release_year AND c2.name = 'Travel'
  ), 0) AS number_of_travel_movies,
  COALESCE((
    SELECT COUNT(1)
    FROM public.film_category fc2
    JOIN public.category c2 ON fc2.category_id = c2.category_id
    JOIN public.film f2 ON fc2.film_id = f2.film_id
    WHERE f2.release_year = f.release_year AND c2.name = 'Documentary'
  ), 0) AS number_of_documentary_movies
FROM (
  SELECT DISTINCT release_year
  FROM public.film
  WHERE release_year IS NOT NULL
) f
ORDER BY f.release_year DESC;

-- =========================
-- Approach C: JOIN 
-- =========================
SELECT
  f.release_year,
  COALESCE(SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END), 0) AS number_of_drama_movies,
  COALESCE(SUM(CASE WHEN c.name = 'Travel' THEN 1 ELSE 0 END), 0) AS number_of_travel_movies,
  COALESCE(SUM(CASE WHEN c.name = 'Documentary' THEN 1 ELSE 0 END), 0) AS number_of_documentary_movies
FROM public.film f
LEFT JOIN public.film_category fc ON f.film_id = fc.film_id
LEFT JOIN public.category c ON fc.category_id = c.category_id
WHERE c.name IN ('Drama', 'Travel', 'Documentary') OR c.name IS NULL
GROUP BY f.release_year
ORDER BY f.release_year DESC;

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
WITH payments_2017 AS (
  SELECT p.payment_id,
         p.payment_date,
         p.amount,
         p.staff_id
  FROM public.payment p
  WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
),
staff_revenue AS (
  SELECT p.staff_id,
         SUM(p.amount) AS total_revenue_2017
  FROM payments_2017 p
  GROUP BY p.staff_id
),
staff_last_payment AS (
  -- get last payment_date per staff in 2017
  SELECT p.staff_id, MAX(p.payment_date) AS last_payment_date
  FROM payments_2017 p
  GROUP BY p.staff_id
),
staff_last_store AS (
  -- get payment row that corresponds to last payment_date per staff, then derive store via staff table
  SELECT slp.staff_id, p.payment_id, p.payment_date, st.store_id
  FROM staff_last_payment slp
  JOIN public.payment p
    ON slp.staff_id = p.staff_id
   AND slp.last_payment_date = p.payment_date
  JOIN public.staff st ON p.staff_id = st.staff_id
)
SELECT sr.staff_id,
       s.first_name,
       s.last_name,
       sls.store_id AS last_store_id,
       CONCAT(a.address, ' ', COALESCE(a.address2, '')) AS last_store_address,
       ROUND(sr.total_revenue_2017::numeric, 2) AS total_revenue_2017
FROM staff_revenue sr
JOIN public.staff s ON sr.staff_id = s.staff_id
LEFT JOIN staff_last_store sls ON sr.staff_id = sls.staff_id
LEFT JOIN public.store st ON sls.store_id = st.store_id
LEFT JOIN public.address a ON st.address_id = a.address_id
ORDER BY sr.total_revenue_2017 DESC
LIMIT 3;

-- =========================
-- Approach B: Subquery
-- =========================
SELECT
  sr.staff_id,
  s.first_name,
  s.last_name,
  sls.last_store_id,
  CONCAT(a.address, ' ', COALESCE(a.address2, '')) AS last_store_address,
  ROUND(sr.total_revenue_2017::numeric, 2) AS total_revenue_2017
FROM (
  -- total revenue per staff
  SELECT p.staff_id, SUM(p.amount) AS total_revenue_2017
  FROM public.payment p
  WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
  GROUP BY p.staff_id
) sr
JOIN public.staff s ON sr.staff_id = s.staff_id
LEFT JOIN (
  -- last store info per staff via last payment_date -> payment -> staff.store_id
  SELECT p.staff_id, st.store_id AS last_store_id
  FROM public.payment p
  JOIN public.staff st ON p.staff_id = st.staff_id
  WHERE (p.staff_id, p.payment_date) IN (
    SELECT p2.staff_id, MAX(p2.payment_date) AS last_payment_date
    FROM public.payment p2
    WHERE EXTRACT(YEAR FROM p2.payment_date) = 2017
    GROUP BY p2.staff_id
  )
) sls ON sr.staff_id = sls.staff_id
LEFT JOIN public.store st ON sls.last_store_id = st.store_id
LEFT JOIN public.address a ON st.address_id = a.address_id
ORDER BY sr.total_revenue_2017 DESC
LIMIT 3;

-- =========================
-- Approach C: JOIN
-- =========================
-- totals per staff in 2017
SELECT totals.staff_id,
       s.first_name,
       s.last_name,
       last.store_id AS last_store_id,
       CONCAT(ad.address, ' ', COALESCE(ad.address2, '')) AS last_store_address,
       ROUND(totals.total_revenue_2017::numeric, 2) AS total_revenue_2017
FROM (
  SELECT p.staff_id, SUM(p.amount) AS total_revenue_2017
  FROM public.payment p
  WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
  GROUP BY p.staff_id
) totals
JOIN public.staff s ON totals.staff_id = s.staff_id
LEFT JOIN (
  -- join payment to itself to get the payment row that has the max date per staff 
  SELECT p1.staff_id, p1.payment_id, p1.payment_date, st1.store_id
  FROM public.payment p1
  JOIN (
    SELECT p2.staff_id, MAX(p2.payment_date) AS max_pd
    FROM public.payment p2
    WHERE EXTRACT(YEAR FROM p2.payment_date) = 2017
    GROUP BY p2.staff_id
  ) m ON p1.staff_id = m.staff_id AND p1.payment_date = m.max_pd
  JOIN public.staff st1 ON p1.staff_id = st1.staff_id
) last ON totals.staff_id = last.staff_id
LEFT JOIN public.store st_store ON last.store_id = st_store.store_id
LEFT JOIN public.address ad ON st_store.address_id = ad.address_id
ORDER BY totals.total_revenue_2017 DESC
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
WITH film_rental_counts AS (
  SELECT f.film_id,
         f.title,
         f.rating,
         COUNT(r.rental_id) AS rental_count
  FROM public.film f
  JOIN public.inventory i ON f.film_id = i.film_id
  JOIN public.rental r ON i.inventory_id = r.inventory_id
  GROUP BY f.film_id, f.title, f.rating
)
SELECT title, rating, rental_count,
       CASE
         WHEN rating IN ('G','PG') THEN 'All ages / Family'
         WHEN rating = 'PG-13' THEN 'Teens 13+'
         WHEN rating = 'R' THEN 'Adults 17+'
         WHEN rating = 'NC-17' THEN 'Adults 18+'
         ELSE 'Unknown'
       END AS expected_audience
FROM film_rental_counts
ORDER BY rental_count DESC
LIMIT 5;

-- =========================
-- Approach B: Subquery
-- =========================
SELECT fr.title, fr.rating, fr.rental_count,
       CASE
         WHEN fr.rating IN ('G','PG') THEN 'All ages / Family'
         WHEN fr.rating = 'PG-13' THEN 'Teens 13+'
         WHEN fr.rating = 'R' THEN 'Adults 17+'
         WHEN fr.rating = 'NC-17' THEN 'Adults 18+'
         ELSE 'Unknown'
       END AS expected_audience
FROM (
  SELECT f.film_id, f.title, f.rating, COUNT(r.rental_id) AS rental_count
  FROM public.film f
  JOIN public.inventory i ON f.film_id = i.film_id
  JOIN public.rental r ON i.inventory_id = r.inventory_id
  GROUP BY f.film_id, f.title, f.rating
) fr
ORDER BY fr.rental_count DESC
LIMIT 5;

-- =========================
-- Approach C: JOIN 
-- =========================
SELECT f.title, f.rating, COUNT(r.rental_id) AS rental_count,
       CASE
         WHEN f.rating IN ('G','PG') THEN 'All ages / Family'
         WHEN f.rating = 'PG-13' THEN 'Teens 13+'
         WHEN f.rating = 'R' THEN 'Adults 17+'
         WHEN f.rating = 'NC-17' THEN 'Adults 18+'
         ELSE 'Unknown'
       END AS expected_audience
FROM public.film f
INNER JOIN public.inventory i ON f.film_id = i.film_id
INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
GROUP BY f.title, f.rating
ORDER BY rental_count DESC
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
WITH actor_last_release AS (
  SELECT a.actor_id,
         a.first_name,
         a.last_name,
         MAX(f.release_year) AS last_release_year
  FROM public.actor a
  JOIN public.film_actor fa ON a.actor_id = fa.actor_id
  JOIN public.film f ON fa.film_id = f.film_id
  GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT first_name, last_name,
       (EXTRACT(YEAR FROM CURRENT_DATE) - last_release_year) AS years_since_last_film
FROM actor_last_release
ORDER BY years_since_last_film DESC
LIMIT 20;

-- =========================
-- Approach B: Subquery
-- =========================
SELECT a.first_name, a.last_name,
       (EXTRACT(YEAR FROM CURRENT_DATE) - sub.last_release_year) AS years_since_last_film
FROM public.actor a
JOIN (
  SELECT fa.actor_id, MAX(f.release_year) AS last_release_year
  FROM public.film_actor fa
  JOIN public.film f ON fa.film_id = f.film_id
  GROUP BY fa.actor_id
) sub ON a.actor_id = sub.actor_id
ORDER BY years_since_last_film DESC
LIMIT 20;

-- =========================
-- Approach C: JOIN 
-- =========================
SELECT a.first_name, a.last_name,
       (EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year)) AS years_since_last_film
FROM public.actor a
INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN public.film f ON fa.film_id = f.film_id
GROUP BY a.first_name, a.last_name
ORDER BY years_since_last_film DESC
LIMIT 20;

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
WITH actor_years AS (
  SELECT DISTINCT a.actor_id, a.first_name, a.last_name, f.release_year
  FROM public.actor a
  JOIN public.film_actor fa ON a.actor_id = fa.actor_id
  JOIN public.film f ON fa.film_id = f.film_id
  WHERE f.release_year IS NOT NULL
),
actor_next_year AS (
  SELECT ay1.actor_id,
         ay1.first_name,
         ay1.last_name,
         ay1.release_year AS year,
         (SELECT MIN(ay2.release_year)
          FROM actor_years ay2
          WHERE ay2.actor_id = ay1.actor_id
            AND ay2.release_year > ay1.release_year
         ) AS next_year
  FROM actor_years ay1
)
SELECT first_name, last_name, MAX(next_year - year) AS longest_gap
FROM actor_next_year
WHERE next_year IS NOT NULL
GROUP BY first_name, last_name
ORDER BY longest_gap DESC
LIMIT 20;

-- =========================
-- Approach B: Subquery
-- =========================
SELECT a.first_name, a.last_name, MAX(ay.next_year - ay.year) AS longest_gap
FROM public.actor a
JOIN (
  -- derive pairs (year, next_year) via correlated subquery for each actor-year
  SELECT ay.actor_id, ay.release_year AS year,
         (SELECT MIN(ay2.release_year)
          FROM (
            SELECT DISTINCT fa2.actor_id, f2.release_year
            FROM public.film_actor fa2
            JOIN public.film f2 ON fa2.film_id = f2.film_id
          ) ay2
          WHERE ay2.actor_id = ay.actor_id
            AND ay2.release_year > ay.release_year
         ) AS next_year
  FROM (
    SELECT DISTINCT fa.actor_id, f.release_year
    FROM public.film_actor fa
    JOIN public.film f ON fa.film_id = f.film_id
    WHERE f.release_year IS NOT NULL
  ) ay
) ay ON a.actor_id = ay.actor_id
WHERE ay.next_year IS NOT NULL
GROUP BY a.first_name, a.last_name
ORDER BY longest_gap DESC
LIMIT 20;

-- =========================
-- Approach C: JOIN-based (self-join + aggregation)
-- =========================
-- For each actor-year (y), find the minimal year > y via self-join, then compute gap
SELECT a.first_name, a.last_name, MAX(ay2.next_year - ay1.release_year) AS longest_gap
FROM (
  SELECT DISTINCT fa.actor_id, f.release_year
  FROM public.film_actor fa
  JOIN public.film f ON fa.film_id = f.film_id
  WHERE f.release_year IS NOT NULL
) ay1
JOIN (
  -- For each actor and year, find the minimal greater year (next_year)
  SELECT ay.actor_id, ay.release_year,
         MIN(ayg.release_year) AS next_year
  FROM (
    SELECT DISTINCT fa.actor_id, f.release_year
    FROM public.film_actor fa
    JOIN public.film f ON fa.film_id = f.film_id
    WHERE f.release_year IS NOT NULL
  ) ay
  LEFT JOIN (
    SELECT DISTINCT fa2.actor_id, f2.release_year
    FROM public.film_actor fa2
    JOIN public.film f2 ON fa2.film_id = f2.film_id
    WHERE f2.release_year IS NOT NULL
  ) ayg
    ON ay.actor_id = ayg.actor_id
   AND ayg.release_year > ay.release_year
  GROUP BY ay.actor_id, ay.release_year
) ay2 ON ay1.actor_id = ay2.actor_id AND ay1.release_year = ay2.release_year
JOIN public.actor a ON ay1.actor_id = a.actor_id
WHERE ay2.next_year IS NOT NULL
GROUP BY a.first_name, a.last_name
ORDER BY longest_gap DESC
LIMIT 20;

-- Analysis (advantages / disadvantages)
-- Advantages:
--  - Provides per-actor longest gap between sequential film years without using window functions.
-- Disadvantages / Notes:
--  - Implementations without window functions are more verbose and can be less performant on large datasets.
--  - Edge cases: actors with single film -> no gap (excluded by WHERE next_year IS NOT NULL).


/* ============================================================
   END OF FILE
   ============================================================ */
