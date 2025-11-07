-- ================================================
-- TASK 1.1: Add my top-3 favorite movies to the 'film' table
-- ================================================
-- I use INSERT...SELECT with WHERE NOT EXISTS to make the script rerunnable (no duplicates)
-- The column 'last_update' is set to current_date

-- 1️⃣ Yes Man
INSERT INTO film (
    title,
    description,
    release_year,
    language_id,
    rental_duration,
    rental_rate,
    length,
    replacement_cost,
    rating,
    special_features,
    last_update
)
SELECT 'Yes Man',
       'A man decides to say yes to everything for a year and changes his life.',
       2008,
       1,
       1,
       4.99,
       104,
       19.99,
       'PG-13',
       ARRAY['Behind the Scenes', 'Deleted Scenes'],
       CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM film WHERE title = 'Yes Man');

-- 2️⃣ The Holiday
INSERT INTO film (
    title,
    description,
    release_year,
    language_id,
    rental_duration,
    rental_rate,
    length,
    replacement_cost,
    rating,
    special_features,
    last_update
)
SELECT 'The Holiday',
       'Two women swap homes for Christmas and find unexpected love.',
       2006,
       1,
       2,
       9.99,
       136,
       19.99,
       'PG-13',
       ARRAY['Trailers', 'Commentaries'],
       CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM film WHERE title = 'The Holiday');

-- 3️⃣ The Proposal
INSERT INTO film (
    title,
    description,
    release_year,
    language_id,
    rental_duration,
    rental_rate,
    length,
    replacement_cost,
    rating,
    special_features,
    last_update
)
SELECT 'The Proposal',
       'A boss forces her assistant to marry her to avoid deportation to Canada.',
       2009,
       1,
       3,
       19.99,
       108,
       19.99,
       'PG-13',
       ARRAY['Behind the Scenes', 'Trailers'],
       CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM film WHERE title = 'The Proposal');

COMMIT;


-- ================================================
-- TASK 1.2: Add main actors to 'actor' table
-- ================================================
-- I add real actors. 

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Jim', 'Carrey', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Jim' AND last_name = 'Carrey');

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Zooey', 'Deschanel', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Zooey' AND last_name = 'Deschanel');

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Cameron', 'Diaz', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Cameron' AND last_name = 'Diaz');

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Kate', 'Winslet', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Kate' AND last_name = 'Winslet');

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Sandra', 'Bullock', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Sandra' AND last_name = 'Bullock');

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Ryan', 'Reynolds', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Ryan' AND last_name = 'Reynolds');

COMMIT;

-- ================================================
-- TASK 1.3: Link actors and films in 'film_actor'
-- ================================================
-- I use subqueries to get film_id and actor_id dynamically

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, CURRENT_DATE
FROM actor a
JOIN film f ON f.title = 'Yes Man'
WHERE a.first_name = 'Jim' AND a.last_name = 'Carrey'
  AND NOT EXISTS (
      SELECT 1 FROM film_actor fa
      WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
  );

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, CURRENT_DATE
FROM actor a
JOIN film f ON f.title = 'Yes Man'
WHERE a.first_name = 'Zooey' AND a.last_name = 'Deschanel'
  AND NOT EXISTS (
      SELECT 1 FROM film_actor fa
      WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
  );

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, CURRENT_DATE
FROM actor a
JOIN film f ON f.title = 'The Holiday'
WHERE a.first_name = 'Cameron' AND a.last_name = 'Diaz'
  AND NOT EXISTS (
      SELECT 1 FROM film_actor fa
      WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
  );

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, CURRENT_DATE
FROM actor a
JOIN film f ON f.title = 'The Holiday'
WHERE a.first_name = 'Kate' AND a.last_name = 'Winslet'
  AND NOT EXISTS (
      SELECT 1 FROM film_actor fa
      WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
  );

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, CURRENT_DATE
FROM actor a
JOIN film f ON f.title = 'The Proposal'
WHERE a.first_name = 'Sandra' AND a.last_name = 'Bullock'
  AND NOT EXISTS (
      SELECT 1 FROM film_actor fa
      WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
  );

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, CURRENT_DATE
FROM actor a
JOIN film f ON f.title = 'The Proposal'
WHERE a.first_name = 'Ryan' AND a.last_name = 'Reynolds'
  AND NOT EXISTS (
      SELECT 1 FROM film_actor fa
      WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
  );

COMMIT;

-- ================================================
-- TASK 1.4: Add favorite movies to any store's inventory
-- ================================================
-- I use store_id = 1 and select the film_id dynamically.
-- 'inventory_id' is auto-increment, so we don't insert it manually.

INSERT INTO inventory (film_id, store_id, last_update)
SELECT f.film_id, 1, CURRENT_DATE
FROM film f
WHERE f.title IN ('Yes Man', 'The Holiday', 'The Proposal')
  AND NOT EXISTS (
      SELECT 1 FROM inventory inv WHERE inv.film_id = f.film_id AND inv.store_id = 1
  );

COMMIT;

-- ================================================
-- TASK 1.5: Update an existing customer with >=43 rentals and payments
-- ================================================
-- I pick such a customer dynamically (limit 1) and update their info to mine

UPDATE customer
SET first_name = 'Ainura',
    last_name = 'Dalabayeva',
    email = 'ainura@gmail.com',
    last_update = CURRENT_DATE
WHERE customer_id = (
    SELECT c.customer_id
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id, c.address_id
    HAVING COUNT(DISTINCT r.rental_id) >= 43 
       AND COUNT(DISTINCT p.payment_id) >= 43
    LIMIT 1
);

COMMIT;

-- ================================================
-- TASK 6: Remove my rentals and payments (keep customer)
-- ================================================
DELETE FROM payment
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Ainura' AND last_name = 'Dalabayeva');

DELETE FROM rental
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Ainura' AND last_name = 'Dalabayeva');

COMMIT;

-- ================================================
-- TASK 7: Rent and pay for favorite movies
-- ================================================
-- I simulate renting the movies from store 1 by my updated customer

INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, last_update)
SELECT '2017-01-15', inv.inventory_id,
       cust.customer_id, 1, CURRENT_DATE
FROM inventory inv
JOIN film f ON inv.film_id = f.film_id
JOIN customer cust ON cust.first_name = 'Ainura' AND cust.last_name = 'Dalabayeva'
WHERE f.title IN ('Yes Man', 'The Holiday', 'The Proposal')
  AND NOT EXISTS (
      SELECT 1 FROM rental rent WHERE rent.inventory_id = inv.inventory_id AND rent.customer_id = cust.customer_id
  );

-- Make payments for these rentals
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT cust.customer_id, 1, rent.rental_id, f.rental_rate, '2017-01-16'
FROM rental rent
JOIN inventory inv ON rent.inventory_id = inv.inventory_id
JOIN film f ON inv.film_id = f.film_id
JOIN customer cust ON rent.customer_id = cust.customer_id
WHERE cust.first_name = 'Ainura' AND cust.last_name = 'Dalabayeva'
  AND f.title IN ('Yes Man', 'The Holiday', 'The Proposal')
  AND NOT EXISTS (
      SELECT 1 FROM payment pay WHERE pay.rental_id = rent.rental_id
  );

COMMIT;

-- ================================================
-- TO CONCLUDE: HERE IS SCRIPT TO SHOW THAT NEW FILMS AND RENTS ARE EXIST
-- ================================================
SELECT 
    cust.first_name || ' ' || cust.last_name AS customer_name,
    f.title AS film_title,
    rent.rental_id,
    rent.rental_date,
    pay.payment_id,
    pay.amount AS payment_amount,
    pay.payment_date
FROM customer cust
JOIN rental rent ON cust.customer_id = rent.customer_id
JOIN inventory inv ON rent.inventory_id = inv.inventory_id
JOIN film f ON inv.film_id = f.film_id
LEFT JOIN payment pay ON rent.rental_id = pay.rental_id
WHERE cust.first_name = 'Ainura'
  AND cust.last_name = 'Dalabayeva'
ORDER BY rent.rental_date, f.title;

-- ========================================================================
-- TASK 2: DELETE vs VACUUM FULL vs TRUNCATE Performance Investigation
-- ========================================================================

/* 
-- ================================================
-- RESULTS TABLE
-- ================================================

| № | Stage             | Execution Time   | Table Size (total) | Comment                                     |
|---|-------------------|------------------|--------------------|---------------------------------------------|
| 1 | After CREATE      | 34 secs 305 msec | 575 MB             | Table with 10 million rows created          |
| 2 | After DELETE      | 28 secs 995 msec | 383 MB             | Table size didn’t change — space not released |
| 3 | After VACUUM FULL | 14 secs 145 msec | 383 MB             | Table size decreased — space reclaimed      |
| 4 | After RECREATE    | 38 secs 101 msec | 575 MB             | Table recreated successfully                |
| 5 | After TRUNCATE    | 210 msec         | 8192 bytes         | Table cleared instantly                     |

-- ================================================
-- OBSERVATIONS:
-- ================================================

1. After DELETE, the table still occupies almost the same space — deleted rows remain as “dead tuples”.
2. After VACUUM FULL, space is reclaimed, and the table size significantly decreases.
3. TRUNCATE is much faster than DELETE because it removes all data instantly without scanning rows.
4. For large tables, TRUNCATE is the preferred method when you need to clear all data.

-- ================================================
-- CONCLUSIONS:
-- ================================================

1. DELETE — slow and does not immediately release space.  
2. VACUUM FULL — reclaims space but takes additional time.  
3. TRUNCATE — instantly removes all rows and fully frees space.

*/

