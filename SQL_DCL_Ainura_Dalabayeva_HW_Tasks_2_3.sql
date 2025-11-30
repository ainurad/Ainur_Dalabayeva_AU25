-- =============================================================================
-- Task 2: Implement Role-Based Authentication Model
-- Database: dvd_rental
-- =============================================================================

-- 1. Create a new user "rentaluser" with password "rentalpassword"
--    Note: explicitly adding LOGIN is required for them to connect.
CREATE ROLE rentaluser WITH LOGIN PASSWORD 'rentalpassword';

--    Give ability to connect (and usage on public schema is usually needed)
GRANT CONNECT ON DATABASE dvd_rental TO rentaluser;
GRANT USAGE ON SCHEMA public TO rentaluser;

-- =============================================================================

-- 2. Grant SELECT permission for the "customer" table
GRANT SELECT ON TABLE customer TO rentaluser;

--    VERIFICATION: Check to make sure permission works
--    Switch to the new user context
SET ROLE rentaluser;

--    Select all customers (Limit to 5 for readability)
SELECT * FROM customer LIMIT 5;

--    Switch back to superuser/admin to continue setup
RESET ROLE;

-- =============================================================================

-- 3. Create a new user group "rental" and add "rentaluser" to it
CREATE ROLE rental; -- Groups are typically roles without LOGIN
GRANT rental TO rentaluser;

-- =============================================================================

-- 4. Grant "rental" group INSERT and UPDATE permissions for "rental" table
GRANT INSERT, UPDATE ON TABLE rental TO rental;

--    CRITICAL STEP: In PostgreSQL, to insert rows with auto-incrementing IDs,
--    the user also needs usage rights on the associated sequence.
GRANT USAGE, SELECT ON SEQUENCE rental_rental_id_seq TO rental;

--    Perform INSERT and UPDATE under that role
SET ROLE rentaluser;

--    A. Insert a new row (Using dummy IDs that are safe for dvd_rental)
--       Assuming inventory_id=1, customer_id=1, staff_id=1 exist.
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES (NOW(), 1, 1, NULL, 1);

--    B. Update an existing row
--       (Updating the row we just inserted or inventory_id 1)
UPDATE rental 
SET return_date = NOW() 
WHERE inventory_id = 1 AND customer_id = 1;

RESET ROLE;

-- =============================================================================

-- 5. Revoke INSERT permission
REVOKE INSERT ON TABLE rental FROM rental;

--    VERIFICATION: Try to insert new rows (This should fail)
SET ROLE rentaluser;

--    This query attempts to insert, but should result in "ERROR: permission denied"
--    (Uncomment the lines below to run the test manually)
--    INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
--    VALUES (NOW(), 2, 1, NULL, 1);

RESET ROLE;

-- =============================================================================

-- 6. Create a personalized role for an existing customer
--    We will use customer_id 1: Mary Smith
--    Her role name will be client_mary_smith

CREATE ROLE client_mary_smith WITH LOGIN PASSWORD 'securePass123';

--    Grant basic connection rights so she can log in later
GRANT CONNECT ON DATABASE dvd_rental TO client_mary_smith;
GRANT USAGE ON SCHEMA public TO client_mary_smith;


-- =============================================================================
-- Task 3: Implement Row-Level Security (RLS)
-- Goal: Configure client_mary_smith to only see her own data in rental/payment
-- =============================================================================

-- 1. Enable Row-Level Security on the target tables
ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

-- 2. Create Policies
--    Policy for RENTAL table: Only see rows where customer_id matches Mary's ID (1)
CREATE POLICY mary_rental_policy ON rental
    FOR SELECT
    TO client_mary_smith
    USING (customer_id = 1);

--    Policy for PAYMENT table: Only see rows where customer_id matches Mary's ID (1)
CREATE POLICY mary_payment_policy ON payment
    FOR SELECT
    TO client_mary_smith
    USING (customer_id = 1);

-- 3. Grant SELECT permissions
--    RLS filters data, but the user still needs permission to select from the table first.
GRANT SELECT ON TABLE rental TO client_mary_smith;
GRANT SELECT ON TABLE payment TO client_mary_smith;

-- 4. Verification
--    Switch to Mary's role
SET ROLE client_mary_smith;

--    Check count in rental table.
--    (If RLS is working, this count will be small, matching her specific history, 
--    rather than the thousands of rows in the full table).
SELECT count(*) AS my_rentals_count FROM rental;

--    Check data to ensure no other IDs are visible
SELECT distinct customer_id AS visible_customer_ids FROM payment; 
--    Result should strictly be '1'.

--    Switch back to admin
RESET ROLE;