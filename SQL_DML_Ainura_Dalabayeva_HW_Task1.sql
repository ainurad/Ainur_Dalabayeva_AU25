-- ================================================
-- TASK 1.1: Add my top-3 favorite movies to the 'film' table
-- ================================================
-- Changes: 
-- 1. rental_duration converted to days (7, 14, 21).
-- 2. language_id is selected dynamically.
-- 3. Added RETURNING *.

-- 1. Yes Man
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
       (SELECT language_id FROM language WHERE name = 'English'), 
       7,   -- Days 
       4.99,
       104,
       19.99,
       'PG-13',
       ARRAY['Behind the Scenes', 'Deleted Scenes'],
       CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM film WHERE UPPER(title) = 'YES MAN')
RETURNING *;

-- 2. The Holiday
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
       (SELECT language_id FROM language WHERE name = 'English'), 
       14,  
       9.99,
       136,
       19.99,
       'PG-13',
       ARRAY['Trailers', 'Commentaries'],
       CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM film WHERE UPPER(title) = 'THE HOLIDAY')
RETURNING *;

-- 3. The Proposal
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
       (SELECT language_id FROM language WHERE name = 'English'), -- Dynamic Language
       21,  -- Days (formerly 3 weeks)
       19.99,
       108,
       19.99,
       'PG-13',
       ARRAY['Behind the Scenes', 'Trailers'],
       CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM film WHERE UPPER(title) = 'THE PROPOSAL')
RETURNING *;

COMMIT;


-- ================================================
-- TASK 1.2: Add main actors to 'actor' table
-- ================================================
-- Changes: Added UPPER checks for case insensitivity and RETURNING *.

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Jim', 'Carrey', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE UPPER(first_name) = 'JIM' AND UPPER(last_name) = 'CARREY')
RETURNING *;

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Zooey', 'Deschanel', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE UPPER(first_name) = 'ZOOEY' AND UPPER(last_name) = 'DESCHANEL')
RETURNING *;

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Cameron', 'Diaz', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE UPPER(first_name) = 'CAMERON' AND UPPER(last_name) = 'DIAZ')
RETURNING *;

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Kate', 'Winslet', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE UPPER(first_name) = 'KATE' AND UPPER(last_name) = 'WINSLET')
RETURNING *;

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Sandra', 'Bullock', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE UPPER(first_name) = 'SANDRA' AND UPPER(last_name) = 'BULLOCK')
RETURNING *;

INSERT INTO actor (first_name, last_name, last_update)
SELECT 'Ryan', 'Reynolds', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE UPPER(first_name) = 'RYAN' AND UPPER(last_name) = 'REYNOLDS')
RETURNING *;

COMMIT;

-- ================================================
-- TASK 1.3: Link actors and films in 'film_actor'
-- ================================================
-- Changes: specified INNER JOIN, added UPPER checks, added RETURNING *.

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, CURRENT_DATE
FROM actor a
INNER JOIN film f ON UPPER(f.title) = 'YES MAN'
WHERE UPPER(a.first_name) = 'JIM' AND UPPER(a.last_name) = 'CARREY'
  AND NOT EXISTS (
      SELECT 1 FROM film_actor fa
      WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
  )
RETURNING *;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, CURRENT_DATE
FROM actor a
INNER JOIN film f ON UPPER(f.title) = 'YES MAN'
WHERE UPPER(a.first_name) = 'ZOOEY' AND UPPER(a.last_name) = 'DESCHANEL'
  AND NOT EXISTS (
      SELECT 1 FROM film_actor fa
      WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
  )
RETURNING *;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, CURRENT_DATE
FROM actor a
INNER JOIN film f ON UPPER(f.title) = 'THE HOLIDAY'
WHERE UPPER(a.first_name) = 'CAMERON' AND UPPER(a.last_name) = 'DIAZ'
  AND NOT EXISTS (
      SELECT 1 FROM film_actor fa
      WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
  )
RETURNING *;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, CURRENT_DATE
FROM actor a
INNER JOIN film f ON UPPER(f.title) = 'THE HOLIDAY'
WHERE UPPER(a.first_name) = 'KATE' AND UPPER(a.last_name) = 'WINSLET'
  AND NOT EXISTS (
      SELECT 1 FROM film_actor fa
      WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
  )
RETURNING *;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, CURRENT_DATE
FROM actor a
INNER JOIN film f ON UPPER(f.title) = 'THE PROPOSAL'
WHERE UPPER(a.first_name) = 'SANDRA' AND UPPER(a.last_name) = 'BULLOCK'
  AND NOT EXISTS (
      SELECT 1 FROM film_actor fa
      WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
  )
RETURNING *;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, CURRENT_DATE
FROM actor a
INNER JOIN film f ON UPPER(f.title) = 'THE PROPOSAL'
WHERE UPPER(a.first_name) = 'RYAN' AND UPPER(a.last_name) = 'REYNOLDS'
  AND NOT EXISTS (
      SELECT 1 FROM film_actor fa
      WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
  )
RETURNING *;

COMMIT;

-- ================================================
-- TASK 1.4: Add favorite movies to any store's inventory
-- ================================================
-- Changes: 
-- 1. store_id selected randomly.
-- 2. Added UPPER checks.
-- 3. Added RETURNING *.

INSERT INTO inventory (film_id, store_id, last_update)
SELECT f.film_id, 
       (SELECT store_id FROM store ORDER BY RANDOM() LIMIT 1), -- Random Store
       CURRENT_DATE
FROM film f
WHERE UPPER(f.title) IN ('YES MAN', 'THE HOLIDAY', 'THE PROPOSAL')
  AND NOT EXISTS (
      SELECT 1 FROM inventory inv 
      WHERE inv.film_id = f.film_id
  )
RETURNING *;

COMMIT;

-- ================================================
-- TASK 1.5: Update an existing customer with >=43 rentals and payments
-- ================================================
-- Changes: specified INNER JOIN, added RETURNING *.

UPDATE customer
SET first_name = 'Ainura',
    last_name = 'Dalabayeva',
    email = 'ainura@gmail.com',
    last_update = CURRENT_DATE
WHERE customer_id = (
    SELECT c.customer_id
    FROM customer c
    INNER JOIN rental r ON c.customer_id = r.customer_id
    INNER JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id) >= 43 
       AND COUNT(DISTINCT p.payment_id) >= 43
    LIMIT 1
)
RETURNING *;

COMMIT;

-- ================================================
-- TASK 6: Remove my rentals and payments (keep customer)
-- ================================================
-- Changes: Added UPPER checks and RETURNING *.

DELETE FROM payment
WHERE customer_id = (
    SELECT customer_id 
    FROM customer 
    WHERE UPPER(first_name) = 'AINURA' AND UPPER(last_name) = 'DALABAYEVA'
)
RETURNING *;

DELETE FROM rental
WHERE customer_id = (
    SELECT customer_id 
    FROM customer 
    WHERE UPPER(first_name) = 'AINURA' AND UPPER(last_name) = 'DALABAYEVA'
)
RETURNING *;

COMMIT;

-- ================================================
-- TASK 7: Rent and pay for favorite movies
-- ================================================
-- Changes: 
-- 1. INNER JOINs
-- 2. staff_id is dynamic based on the store where inventory was placed.
-- 3. Added UPPER checks and RETURNING *.

-- Rent
INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, last_update)
SELECT '2017-01-15', 
       inv.inventory_id,
       cust.customer_id, 
       (SELECT staff_id FROM staff WHERE store_id = inv.store_id LIMIT 1), 
       CURRENT_DATE
FROM inventory inv
INNER JOIN film f ON inv.film_id = f.film_id
INNER JOIN customer cust ON UPPER(cust.first_name) = 'AINURA' AND UPPER(cust.last_name) = 'DALABAYEVA'
WHERE UPPER(f.title) IN ('YES MAN', 'THE HOLIDAY', 'THE PROPOSAL')
  AND NOT EXISTS (
      SELECT 1 FROM rental rent 
      WHERE rent.inventory_id = inv.inventory_id 
      AND rent.customer_id = cust.customer_id
  )
RETURNING *;

-- Payment
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT cust.customer_id, 
       (SELECT staff_id FROM staff WHERE store_id = inv.store_id LIMIT 1), 
       rent.rental_id, 
       f.rental_rate, 
       '2017-01-16'
FROM rental rent
INNER JOIN inventory inv ON rent.inventory_id = inv.inventory_id
INNER JOIN film f ON inv.film_id = f.film_id
INNER JOIN customer cust ON rent.customer_id = cust.customer_id
WHERE UPPER(cust.first_name) = 'AINURA' AND UPPER(cust.last_name) = 'DALABAYEVA'
  AND UPPER(f.title) IN ('YES MAN', 'THE HOLIDAY', 'THE PROPOSAL')
  AND NOT EXISTS (
      SELECT 1 FROM payment pay WHERE pay.rental_id = rent.rental_id
  )
RETURNING *;

COMMIT;

-- ================================================
-- TO CONCLUDE: HERE IS SCRIPT TO SHOW THAT NEW FILMS AND RENTS EXIST
-- ================================================
-- Changes: Explicit JOINs, UPPER checks.

SELECT 
    cust.first_name || ' ' || cust.last_name AS customer_name,
    f.title AS film_title,
    rent.rental_id,
    rent.rental_date,
    pay.payment_id,
    pay.amount AS payment_amount,
    pay.payment_date
FROM customer cust
INNER JOIN rental rent ON cust.customer_id = rent.customer_id
INNER JOIN inventory inv ON rent.inventory_id = inv.inventory_id
INNER JOIN film f ON inv.film_id = f.film_id
LEFT JOIN payment pay ON rent.rental_id = pay.rental_id
WHERE UPPER(cust.first_name) = 'AINURA'
  AND UPPER(cust.last_name) = 'DALABAYEVA'
ORDER BY rent.rental_date, f.title;
