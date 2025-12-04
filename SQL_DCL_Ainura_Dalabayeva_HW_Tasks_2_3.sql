-- =============================================================================
-- Task 2: Implement Role-Based Authentication Model
-- Database: dvd_rental
-- =============================================================================

-- 1. Create a new user "rentaluser" 
--    FIXED: Using DO block to check IF NOT EXISTS before creating role
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rentaluser') THEN
    CREATE ROLE rentaluser WITH LOGIN PASSWORD 'rentalpassword';
  END IF;
END
$$;

--    Give ability to connect
GRANT CONNECT ON DATABASE dvd_rental TO rentaluser;
GRANT USAGE ON SCHEMA public TO rentaluser;

-- =============================================================================

-- 2. Grant SELECT permission for the "customer" table
GRANT SELECT ON TABLE customer TO rentaluser;

--    VERIFICATION
SET ROLE rentaluser;
SELECT * FROM customer LIMIT 5;
RESET ROLE;

-- =============================================================================

-- 3. Create a new user group "rental" safely
--    FIXED: DO block for rerunnability
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rental') THEN
    CREATE ROLE rental;
  END IF;
END
$$;

-- Add rentaluser to group
GRANT rental TO rentaluser;

-- =============================================================================

-- 4. Grant permissions
GRANT INSERT, UPDATE ON TABLE rental TO rental;
GRANT USAGE, SELECT ON SEQUENCE rental_rental_id_seq TO rental;

--    Perform INSERT and UPDATE using DYNAMIC data (No hardcoded IDs)
SET ROLE rentaluser;

--    A. Insert a new row dynamically
--       FIXED: find valid IDs via subquery
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
SELECT 
    NOW(), 
    i.inventory_id, 
    c.customer_id, 
    NULL, 
    s.staff_id
FROM inventory i
CROSS JOIN customer c
CROSS JOIN staff s
WHERE c.first_name = 'MARY' AND c.last_name = 'SMITH'
  AND s.staff_id = 1
  AND i.inventory_id NOT IN (SELECT inventory_id FROM rental WHERE return_date IS NULL)
LIMIT 1; 

--    B. Update the row we just inserted (or similar active rental for this user)
--       FIXED: Dynamically find the rental for Mary that is currently open 
UPDATE rental 
SET return_date = NOW() 
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'MARY' AND last_name = 'SMITH')
  AND return_date IS NULL;

RESET ROLE;

-- =============================================================================

-- 5. Revoke INSERT permission
REVOKE INSERT ON TABLE rental FROM rental;

-- =============================================================================

-- 6. Create personalized role safely
--    FIXED: DO block for check
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'client_mary_smith') THEN
    CREATE ROLE client_mary_smith WITH LOGIN PASSWORD 'securePass123';
  END IF;
END
$$;

GRANT CONNECT ON DATABASE dvd_rental TO client_mary_smith;
GRANT USAGE ON SCHEMA public TO client_mary_smith;

-- =============================================================================
-- Task 3: Implement Row-Level Security (RLS)
-- Goal: Configure client_mary_smith to only see her own data
-- =============================================================================

-- 1. Enable RLS
ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

-- 2. Create Policies (Rerunnable: Drop first if exists)
--    FIXED: Script is now rerunnable
DROP POLICY IF EXISTS mary_rental_policy ON rental;
DROP POLICY IF EXISTS mary_payment_policy ON payment;

--    FIXED: Avoided hardcoded ID
CREATE POLICY mary_rental_policy ON rental
    FOR SELECT
    TO client_mary_smith
    USING (customer_id = (SELECT customer_id FROM customer WHERE first_name = 'MARY' AND last_name = 'SMITH'));

CREATE POLICY mary_payment_policy ON payment
    FOR SELECT
    TO client_mary_smith
    USING (customer_id = (SELECT customer_id FROM customer WHERE first_name = 'MARY' AND last_name = 'SMITH'));

-- 3. Grant SELECT permissions 
GRANT SELECT ON TABLE rental TO client_mary_smith;
GRANT SELECT ON TABLE payment TO client_mary_smith;

-- 4. Verification
--    A. Check as Admin 
SELECT count(*) as total_rentals_in_db FROM rental;

--    B. Switch to Mary
SET ROLE client_mary_smith;

--    C. Check count 
SELECT count(*) AS my_rentals_count FROM rental;

--    D. Verify cross-check 
SELECT distinct customer_id AS visible_customer_ids FROM payment; 

RESET ROLE;
