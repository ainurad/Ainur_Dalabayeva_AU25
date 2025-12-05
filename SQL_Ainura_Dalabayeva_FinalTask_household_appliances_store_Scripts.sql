-- SQL script for Household Appliances Store

DROP SCHEMA IF EXISTS store CASCADE;
CREATE SCHEMA store;
SET search_path TO store;

-- =========================================================
-- 1. PARENT TABLES
-- (Categories, Suppliers, Products, Customers, Employees)
-- =========================================================
CREATE TABLE store.category (
    category_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE store.supplier (
    supplier_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_name VARCHAR(200) NOT NULL,
    contact_email VARCHAR(200),
    contact_phone VARCHAR(30)
);

CREATE TABLE store.product (
    product_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id INT NOT NULL REFERENCES store.category(category_id),
    supplier_id INT NOT NULL REFERENCES store.supplier(supplier_id),
    brand VARCHAR(100) NOT NULL,
    model_code VARCHAR(100) NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0,
    created_at DATE NOT NULL DEFAULT CURRENT_DATE
);

-- ---------------------------------------------------------
-- Customers and Employees
-- ---------------------------------------------------------
CREATE TABLE store.customer (
    customer_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(200) UNIQUE NOT NULL,
    phone VARCHAR(30),
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE store.employee (
    employee_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    job_title VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- =========================================================
-- 2. ORDERS AND ORDER ITEMS
-- =========================================================
CREATE TABLE store.orders (
    order_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_number VARCHAR(60) UNIQUE NOT NULL,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL,
    customer_id INT NOT NULL REFERENCES store.customer(customer_id),
    employee_id INT REFERENCES store.employee(employee_id),
    total_amount NUMERIC(14,2) NOT NULL DEFAULT 0
);

CREATE TABLE store.order_item (
    order_item_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id INT NOT NULL REFERENCES store.orders(order_id),
    product_id INT NOT NULL REFERENCES store.product(product_id),
    quantity INT NOT NULL,
    item_price NUMERIC(12,2) NOT NULL,
    line_total NUMERIC(14,2) GENERATED ALWAYS AS (quantity * item_price) STORED
);

-- =========================================================
-- 3. TRANSACTIONS TABLE
-- =========================================================
CREATE TABLE store.transaction (
    transaction_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id INT REFERENCES store.orders(order_id),
    transaction_date TIMESTAMP NOT NULL DEFAULT now(),
    amount NUMERIC(14,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    note TEXT
);

-- =========================================================
-- 4. CONSTRAINTS
-- Named CHECKs, enums, non-negative, dates after 2024-01-01
-- =========================================================
ALTER TABLE store.product
    ADD CONSTRAINT chk_product_price_nonneg CHECK (unit_price >= 0),
    ADD CONSTRAINT chk_product_stock_nonneg CHECK (stock_quantity >= 0);

ALTER TABLE store.order_item
    ADD CONSTRAINT chk_order_item_qty_pos CHECK (quantity > 0),
    ADD CONSTRAINT chk_order_item_price_nonneg CHECK (item_price >= 0);

ALTER TABLE store.orders
    ADD CONSTRAINT chk_orders_status_enum CHECK (status IN ('pending','shipped','delivered','cancelled')),
    ADD CONSTRAINT chk_orders_date_after_2024 CHECK (order_date > DATE '2024-01-01'),
    ADD CONSTRAINT chk_orders_total_nonneg CHECK (total_amount >= 0);

ALTER TABLE store.transaction
    ADD CONSTRAINT chk_transaction_amount_positive CHECK (amount > 0),
    ADD CONSTRAINT chk_transaction_date_after_2024 CHECK (transaction_date > TIMESTAMP '2024-01-01 00:00:00');

ALTER TABLE store.employee
    ADD CONSTRAINT chk_hire_date_after_2024 CHECK (hire_date > DATE '2024-01-01');

ALTER TABLE store.customer
    ADD CONSTRAINT chk_registration_date_after_2024 CHECK (registration_date > DATE '2024-01-01');

-- =========================================================
-- 5. INSERT SAMPLE DATA
-- =========================================================

-- ---------------------------------------------------------
-- Categories
-- ---------------------------------------------------------
INSERT INTO store.category (category_name) VALUES
('Kitchen'), ('Cleaning'), ('Laundry'), ('Climate'), ('Small Appliances'), ('Audio-Video');

-- ---------------------------------------------------------
-- Suppliers
-- ---------------------------------------------------------
INSERT INTO store.supplier (company_name, contact_email, contact_phone) VALUES
('Global Tech Supply','sales@globaltech.example','77020000001'),
('KitchenPro Ltd','sales@kitchenpro.example','77020000002'),
('HomeClean Distributors','sales@homeclean.example','77020000003'),
('LaundryWorld','sales@laundryworld.example','77020000004'),
('ClimateSolutions','sales@climate.example','77020000005'),
('AV Imports','sales@av.example','77020000006');

-- ---------------------------------------------------------
-- Products
-- ---------------------------------------------------------
INSERT INTO store.product (category_id, supplier_id, brand, model_code, unit_price, stock_quantity, created_at)
VALUES
((SELECT category_id FROM store.category WHERE category_name='Kitchen' LIMIT 1), 2, 'HeatQuick', 'MQ-700', 9900.00, 18, CURRENT_DATE - INTERVAL '70 days'),
((SELECT category_id FROM store.category WHERE category_name='Kitchen' LIMIT 1), 2, 'BoilPro', 'EK-17', 2999.00, 40, CURRENT_DATE - INTERVAL '65 days'),
((SELECT category_id FROM store.category WHERE category_name='Cleaning' LIMIT 1), 3, 'HomeBot', 'VB-2', 24950.00, 12, CURRENT_DATE - INTERVAL '50 days'),
((SELECT category_id FROM store.category WHERE category_name='Laundry' LIMIT 1), 4, 'WashMaster', 'WM-7', 39900.00, 6, CURRENT_DATE - INTERVAL '40 days'),
((SELECT category_id FROM store.category WHERE category_name='Kitchen' LIMIT 1), 1, 'CookWell', 'AF-300', 7999.00, 25, CURRENT_DATE - INTERVAL '75 days'),
((SELECT category_id FROM store.category WHERE category_name='Climate' LIMIT 1), 5, 'CoolKeep', 'RF-200', 59900.00, 4, CURRENT_DATE - INTERVAL '30 days'),
((SELECT category_id FROM store.category WHERE category_name='Small Appliances' LIMIT 1), 2, 'BoilPro', 'KTL-45', 1499.00, 50, CURRENT_DATE - INTERVAL '20 days'),
((SELECT category_id FROM store.category WHERE category_name='Audio-Video' LIMIT 1), 6, 'SoundMax', 'SM-10', 12999.00, 10, CURRENT_DATE - INTERVAL '15 days');

-- ---------------------------------------------------------
-- Customers
-- ---------------------------------------------------------
INSERT INTO store.customer (first_name, last_name, email, phone, registration_date) VALUES
('Ainur','Dalabayeva','ainur.d@example.com','77010000001', CURRENT_DATE - INTERVAL '85 days'),
('Bek','S','bek.s@example.com','77010000002', CURRENT_DATE - INTERVAL '75 days'),
('Damla','T','damla.t@example.com','77010000003', CURRENT_DATE - INTERVAL '65 days'),
('Eldar','K','eldar.k@example.com','77010000004', CURRENT_DATE - INTERVAL '55 days'),
('Farida','M','farida.m@example.com','77010000005', CURRENT_DATE - INTERVAL '45 days'),
('Gulnar','R','gulnar.r@example.com','77010000006', CURRENT_DATE - INTERVAL '35 days');

-- ---------------------------------------------------------
-- Employees
-- ---------------------------------------------------------
INSERT INTO store.employee (first_name, last_name, job_title, hire_date) VALUES
('Zhan','I','Sales Manager', CURRENT_DATE - INTERVAL '200 days'),
('Lina','O','Cashier', CURRENT_DATE - INTERVAL '180 days'),
('Marat','B','Warehouse', CURRENT_DATE - INTERVAL '150 days'),
('Sara','P','Sales Assistant', CURRENT_DATE - INTERVAL '100 days'),
('Nurlan','T','Procurement', CURRENT_DATE - INTERVAL '60 days'),
('Aigul','S','Cleaner', CURRENT_DATE - INTERVAL '30 days');

-- ---------------------------------------------------------
-- Orders
-- ---------------------------------------------------------
INSERT INTO store.orders (order_number, order_date, status, customer_id, employee_id, total_amount)
SELECT
    'ORD-' || to_char((CURRENT_DATE - (s.seq * INTERVAL '3 days')),'YYMMDD') || '-' || s.seq,
    (CURRENT_DATE - (s.seq * INTERVAL '3 days'))::date,
    (ARRAY['pending','shipped','delivered','cancelled'])[ (s.seq % 4) + 1 ],
    (SELECT customer_id FROM store.customer ORDER BY random() LIMIT 1),
    (SELECT employee_id FROM store.employee ORDER BY random() LIMIT 1),
    0.00
FROM generate_series(1,8) AS s(seq);

-- ---------------------------------------------------------
-- Order Items
-- Create multiple items per order
-- ---------------------------------------------------------
INSERT INTO store.order_item (order_id, product_id, quantity, item_price)
SELECT o.order_id, p.product_id, ((o.order_id + p.product_id) % 3) + 1, p.unit_price
FROM store.orders o
CROSS JOIN store.product p
WHERE (o.order_id % 4) = (p.product_id % 4)
LIMIT 20;

-- ---------------------------------------------------------
-- Recompute orders.total_amount
-- ---------------------------------------------------------
UPDATE store.orders o
SET total_amount = COALESCE( (SELECT SUM(oi.line_total) FROM store.order_item oi WHERE oi.order_id = o.order_id), 0 )
WHERE EXISTS (SELECT 1 FROM store.order_item oi WHERE oi.order_id = o.order_id);

-- ---------------------------------------------------------
-- Transactions 
-- For some orders and some prepayments
-- ---------------------------------------------------------
INSERT INTO store.transaction (order_id, transaction_date, amount, payment_method, note)
SELECT o.order_id, now() - (o.order_id * INTERVAL '1 days'), o.total_amount, (ARRAY['card','cash','bank_transfer'])[ (o.order_id % 3) + 1 ], NULL
FROM store.orders o
WHERE o.total_amount > 0
LIMIT 6;

INSERT INTO store.transaction (order_id, transaction_date, amount, payment_method, note)
VALUES (NULL, now() - INTERVAL '7 days', 1000.00, 'card', 'prepayment'),
       (NULL, now() - INTERVAL '2 days', 500.00, 'cash', 'store credit');

-- =========================================================
-- 6. FUNCTIONS
-- =========================================================
CREATE OR REPLACE FUNCTION store.update_product_column(p_product_id INT, p_column TEXT, p_value TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    IF p_column NOT IN ('brand','model_code','unit_price','stock_quantity') THEN
        RAISE EXCEPTION 'Column % cannot be updated by this function', p_column;
    END IF;
    IF p_column = 'unit_price' THEN
        EXECUTE format('UPDATE store.product SET %I = $1 WHERE product_id = $2', p_column)
        USING p_value::numeric, p_product_id;
    ELSIF p_column = 'stock_quantity' THEN
        EXECUTE format('UPDATE store.product SET %I = $1 WHERE product_id = $2', p_column)
        USING p_value::int, p_product_id;
    ELSE
        EXECUTE format('UPDATE store.product SET %I = $1 WHERE product_id = $2', p_column)
        USING p_value, p_product_id;
    END IF;
    RAISE NOTICE 'Product % column % updated', p_product_id, p_column;
END;
$$;

CREATE OR REPLACE FUNCTION store.add_transaction(p_order_number TEXT, p_amount NUMERIC, p_payment_method VARCHAR, p_tx_date TIMESTAMP DEFAULT now())
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    v_order_id INT;
BEGIN
    IF p_order_number IS NOT NULL THEN
        SELECT order_id INTO v_order_id FROM store.orders WHERE order_number = p_order_number;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Order with number % not found', p_order_number;
        END IF;
    ELSE
        v_order_id := NULL;
    END IF;
    
    INSERT INTO store.transaction (order_id, transaction_date, amount, payment_method)
    VALUES (v_order_id, p_tx_date, p_amount, p_payment_method);
    
    RAISE NOTICE 'Transaction added successfully for Order: %, Amount: %', p_order_number, p_amount;
END;
$$;

-- =========================================================
-- 7. VIEW: MOST-RECENT QUARTER ANALYTICS
-- (uses MAX(order_date))
-- =========================================================
CREATE OR REPLACE VIEW store.quarter_sales_analytics AS
WITH maxd AS (SELECT MAX(order_date) AS max_order_date FROM store.orders),
quarter AS (
    SELECT date_trunc('quarter', max_order_date)::date AS q_start,
           (date_trunc('quarter', max_order_date) + INTERVAL '3 months - 1 day')::date AS q_end
    FROM maxd
)
SELECT p.brand, p.model_code, c.category_name,
       SUM(oi.quantity) AS total_qty_sold,
       SUM(oi.line_total) AS total_revenue,
       q.q_start AS quarter_start, q.q_end AS quarter_end
FROM store.orders o
INNER JOIN store.order_item oi ON oi.order_id = o.order_id
INNER JOIN store.product p ON p.product_id = oi.product_id
INNER JOIN store.category c ON c.category_id = p.category_id
CROSS JOIN quarter q
WHERE o.order_date BETWEEN q.q_start AND q.q_end
GROUP BY p.brand, p.model_code, c.category_name, q.q_start, q.q_end
ORDER BY total_revenue DESC;

-- =========================================================
-- 8. READ-ONLY ROLE CREATION AND GRANTS
-- =========================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'manager_readonly') THEN
        CREATE ROLE manager_readonly WITH LOGIN;
        RAISE NOTICE 'Role manager_readonly created';
    ELSE
        RAISE NOTICE 'Role manager_readonly already exists';
    END IF;
END
$$;

GRANT USAGE ON SCHEMA store TO manager_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA store TO manager_readonly;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA store TO manager_readonly;

-- =========================================================
-- 9. CHECK RESULTS / VERIFICATION
-- =========================================================

-- ---------------------------------------------------------
-- 9.1 Check the View (Analytics)
-- ---------------------------------------------------------
SELECT * FROM store.quarter_sales_analytics;

-- ---------------------------------------------------------
-- 9.2 Check Transactions
-- ---------------------------------------------------------
SELECT * FROM store.transaction ORDER BY transaction_date DESC;

-- ---------------------------------------------------------
-- 9.3 Check Orders Update
-- Verify that total_amount was calculated
-- ---------------------------------------------------------
SELECT order_id, customer_id, order_date, total_amount, status 
FROM store.orders 
WHERE total_amount > 0 
ORDER BY order_id 
LIMIT 5;

-- ---------------------------------------------------------
-- 9.4 Check Permissions 
-- Verifying the role exists
-- ---------------------------------------------------------
SELECT rolname, rolsuper, rolinherit, rolcreaterole, rolcreatedb, rolcanlogin 
FROM pg_roles 
WHERE rolname = 'manager_readonly';