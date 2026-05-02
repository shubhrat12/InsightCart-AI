SELECT * 
FROM customers 
WHERE customer_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

INSERT INTO customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
VALUES (
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890',  -- Random UUID for customer_id
    'b2c3d4e5-f6a1-7890-abcd-ef1234567890',  -- Random UUID for customer_unique_id
    12345,                                    -- Zip code prefix
    'New York',                               -- City
    'NY'                                      -- State
);
SELECT * 
FROM customers 
WHERE customer_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

SELECT * 
FROM orders 
WHERE order_id = 'c3d4e5f6-a1b2-7890-abcd-ef1234567890';
INSERT INTO orders (
    order_id, 
    customer_id, 
    order_status, 
    order_purchase_timestamp, 
    order_approved_at, 
    order_delivered_carrier_date, 
    order_delivered_customer_date, 
    order_estimated_delivery_date
)
VALUES (
    'c3d4e5f6-a1b2-7890-abcd-ef1234567890',  -- Random UUID for order_id
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890',  -- Customer ID from previous insert
    'processing',                             -- Order status
    CURRENT_TIMESTAMP,                        -- Purchase timestamp
    CURRENT_TIMESTAMP + INTERVAL '1 day',     -- Approved at
    CURRENT_TIMESTAMP + INTERVAL '3 days',    -- Delivered to carrier
    CURRENT_TIMESTAMP + INTERVAL '7 days',    -- Delivered to customer
    CURRENT_TIMESTAMP + INTERVAL '5 days'     -- Estimated delivery
);
SELECT * 
FROM customers 
WHERE customer_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

-- Fetch the order before updating
SELECT order_id, order_status, order_delivered_customer_date
FROM orders
WHERE order_id = 'c3d4e5f6-a1b2-7890-abcd-ef1234567890';
-- 1. Update order status
UPDATE orders
SET order_status = 'delivered',
    order_delivered_customer_date = CURRENT_TIMESTAMP
WHERE order_id = 'c3d4e5f6-a1b2-7890-abcd-ef1234567890';
SELECT order_id, order_status, order_delivered_customer_date
FROM orders
WHERE order_id = 'c3d4e5f6-a1b2-7890-abcd-ef1234567890';

SELECT customer_id, customer_city, customer_state, customer_zip_code_prefix
FROM customers
WHERE customer_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
-- 2. Update customer address information
UPDATE customers
SET customer_city = 'Buffalo',
    customer_state = 'NY',
    customer_zip_code_prefix = 14260
WHERE customer_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
SELECT customer_id, customer_city, customer_state, customer_zip_code_prefix
FROM customers
WHERE customer_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

SELECT order_id, payment_sequential, payment_type, payment_installments, payment_value
FROM payments
WHERE order_id = 'b81ef226f3fe1789b1e8b2acac839d17' 
AND payment_sequential = 1;
-- 1. Delete a specific payment record
DELETE FROM payments
WHERE order_id = 'b81ef226f3fe1789b1e8b2acac839d17' 
AND payment_sequential = 1;
SELECT order_id, payment_sequential, payment_type, payment_installments, payment_value
FROM payments
WHERE order_id = 'b81ef226f3fe1789b1e8b2acac839d17' 

SELECT *
FROM social_media_mentions
WHERE date = '2025-01-01';

DELETE FROM social_media_mentions
WHERE date = '2025-01-01';
SELECT *
FROM social_media_mentions
WHERE date = '2025-01-01';
-- 1. Find top 10 products by order count using JOIN and GROUP BY
SELECT p.product_id, p.product_category_name, 
       pct.product_category_name_english,
       COUNT(oi.order_id) as order_count
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN product_category_name_translation pct 
    ON p.product_category_name = pct.product_category_name
GROUP BY p.product_id, p.product_category_name, pct.product_category_name_english
ORDER BY order_count DESC
LIMIT 10;
-- 2. Find average delivery time by state using multiple JOINs
SELECT c.customer_state, 
       AVG(o.order_delivered_customer_date - o.order_purchase_timestamp) as avg_delivery_time
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_time DESC
-- 3. Find sellers with highest total sales using subquery
SELECT s.seller_id, s.seller_city, s.seller_state,
       (SELECT SUM(oi.price)
        FROM order_items oi
        WHERE oi.seller_id = s.seller_id) as total_sales
FROM sellers s
ORDER BY total_sales DESC
LIMIT 5;

-- 4. query to find customers with multiple orders
SELECT c.customer_id, 
       c.customer_city, 
       c.customer_state,
       COUNT(DISTINCT o.order_id) as order_count,
       (SELECT payment_type
        FROM payments p
        JOIN orders o2 ON p.order_id = o2.order_id
        WHERE o2.customer_id = c.customer_id
        GROUP BY payment_type
        ORDER BY COUNT(*) DESC
        LIMIT 1) as preferred_payment_method
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_city, c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 1  
ORDER BY order_count DESC
LIMIT 5;  
-- 5. Sales correlation with social media mentions using CTE and Window Function
WITH monthly_sales AS (
    SELECT DATE_TRUNC('month', o.order_purchase_timestamp) as month,
           SUM(p.payment_value) as total_sales
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id
    GROUP BY month
),
monthly_mentions AS (
    SELECT DATE_TRUNC('month', sm.date) as month,
           SUM(sm.mentions) as total_mentions
    FROM social_media_mentions sm
    GROUP BY month
)
SELECT ms.month, 
       ms.total_sales,
       mm.total_mentions,
       ROUND((ms.total_sales / LAG(ms.total_sales, 1) OVER (ORDER BY ms.month) - 1) * 100, 2) as sales_growth_pct,
       ROUND((mm.total_mentions / LAG(mm.total_mentions, 1) OVER (ORDER BY ms.month) - 1) * 100, 2) as mentions_growth_pct
FROM monthly_sales ms
JOIN monthly_mentions mm ON ms.month = mm.month
ORDER BY ms.month;

SELECT c.customer_state,
       COUNT(DISTINCT c.customer_id) AS number_of_customers,
       COUNT(o.order_id) AS number_of_orders,
       ROUND(AVG(p.payment_value), 2) AS average_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN payments p ON o.order_id = p.order_id
GROUP BY c.customer_state
ORDER BY number_of_orders DESC
LIMIT 10;

SELECT p.product_id,
       p.product_category_name,
       COUNT(oi.order_id) AS times_ordered,
       ROUND(AVG(oi.price), 2) AS average_price
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_category_name
HAVING COUNT(oi.order_id) > 5
ORDER BY times_ordered DESC
LIMIT 5;
SELECT o.order_status,
       CASE 
           WHEN EXTRACT(DOW FROM o.order_purchase_timestamp) IN (0, 6) THEN 'Weekend'
           ELSE 'Weekday'
       END AS day_type,
       COUNT(o.order_id) AS order_count,
       ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400), 1) AS avg_delivery_days
FROM orders o
GROUP BY o.order_status, day_type
ORDER BY o.order_status, day_type;
-- Now making fucntions for insertion, updation etc.

SELECT * FROM customers 
WHERE customer_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567899';

CREATE OR REPLACE FUNCTION add_customer(
    p_customer_id UUID,
    p_customer_unique_id UUID,
    p_customer_zip_code_prefix INT,
    p_customer_city VARCHAR(100),
    p_customer_state VARCHAR(10) 
) RETURNS VOID AS $$
BEGIN
    INSERT INTO customers (
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    ) VALUES (
        p_customer_id,
        p_customer_unique_id,
        p_customer_zip_code_prefix,
        p_customer_city,
        p_customer_state
    );
END;
$$ LANGUAGE plpgsql;


SELECT add_customer(
    'a1b2c3d4-e5f6-7890-abcd-ef1234567899'::uuid,
    'b2c3d4e5-f6a7-8901-bcde-f23456789012'::uuid,
    12345,
    'San Francisco',
    'CA'
);
--2
SELECT * FROM customers 
WHERE customer_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567899';
SELECT * FROM customers 
WHERE customer_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
CREATE OR REPLACE FUNCTION update_customer(
    p_customer_id UUID,
    p_customer_unique_id UUID,
    p_customer_zip_code_prefix INT,
    p_customer_city VARCHAR(100),
    p_customer_state VARCHAR(10)
) RETURNS VOID AS $$
BEGIN
    UPDATE customers
    SET 
        customer_unique_id = p_customer_unique_id,
        customer_zip_code_prefix = p_customer_zip_code_prefix,
        customer_city = p_customer_city,
        customer_state = p_customer_state
    WHERE customer_id = p_customer_id;
END;
$$ LANGUAGE plpgsql;

-- Call the function with updated sample data
SELECT update_customer(
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid,
    'b2c3d4e5-f6a7-8901-bcde-f23456789012'::uuid,
    54321,  -- Changed from 12345
    'Los Angeles',  -- Changed from San Francisco
    'NY'  -- Changed from CA
);

-- Check the customer AFTER updating to see the changes
SELECT * FROM customers 
WHERE customer_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
-- Question 3

CREATE TABLE IF NOT EXISTS order_transaction_logs (
    log_id SERIAL PRIMARY KEY,
    order_id UUID,
    transaction_type VARCHAR(50),
    status VARCHAR(20),
    error_message TEXT,
    log_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE OR REPLACE FUNCTION log_transaction_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Log the transaction status
    INSERT INTO order_transaction_logs (
        order_id, transaction_type, status, error_message
    ) VALUES (
        NEW.order_id, 
        TG_OP, 
        CASE WHEN TG_OP = 'DELETE' THEN 'CANCELED' ELSE NEW.order_status END,
        'Transaction ' || TG_OP || ' completed'
    );
    
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Log the error
    INSERT INTO order_transaction_logs (
        order_id, transaction_type, status, error_message
    ) VALUES (
        COALESCE(NEW.order_id, OLD.order_id), 
        TG_OP, 
        'FAILED', 
        SQLERRM
    );
    
    -- Re-raise the exception to abort the transaction
    RAISE;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER order_transaction_log_trigger
AFTER INSERT OR UPDATE OR DELETE ON orders
FOR EACH ROW
EXECUTE FUNCTION log_transaction_status();

CREATE OR REPLACE FUNCTION simple_process_order(
    p_order_id UUID,
    p_customer_id UUID,
    p_order_status VARCHAR(20)
) RETURNS VARCHAR AS $$
BEGIN
    -- Begin a transaction block
    BEGIN
        -- Insert the order
        INSERT INTO orders (
            order_id,
            customer_id,
            order_status,
            order_purchase_timestamp,
            order_estimated_delivery_date
        ) VALUES (
            p_order_id,
            p_customer_id,
            p_order_status,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP + INTERVAL '7 days'
        );
        
        RETURN 'Order processed successfully';
    EXCEPTION WHEN OTHERS THEN
  
        RAISE EXCEPTION 'Order processing failed: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION simple_cancel_order(
    p_order_id UUID
) RETURNS VARCHAR AS $$
DECLARE
    v_order_status VARCHAR(20);
BEGIN
    -- Check current order status
    SELECT order_status INTO v_order_status
    FROM orders
    WHERE order_id = p_order_id;
    
    -- Begin a transaction block
    BEGIN
        -- Validate order status
        IF v_order_status = 'delivered' OR v_order_status = 'canceled' THEN
            RAISE EXCEPTION 'Cannot cancel order with status: %', v_order_status;
        END IF;
        
        -- Update order status
        UPDATE orders
        SET order_status = 'canceled'
        WHERE order_id = p_order_id;
        
        RETURN 'Order successfully canceled';
    EXCEPTION WHEN OTHERS THEN
        -- The trigger will log the error
        RAISE EXCEPTION 'Order cancellation failed: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

SELECT customer_id FROM customers LIMIT 1;

-- Execute the function with a valid customer_id
SELECT simple_process_order(
    gen_random_uuid(),  
    '06b8999e2fba1a1fbc88172c00ba8bc7', 
    'processing'        
);

-- Try to cancel an already canceled order
DO $$
DECLARE
    v_order_id UUID := '1950d777-989f-6a87-7539-f53795b4c3c3';  
BEGIN
    PERFORM simple_cancel_order(v_order_id);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Caught error: %', SQLERRM;
END;
$$;
-- Check the transaction logs after the failure
SELECT * FROM order_transaction_logs 
ORDER BY log_timestamp DESC 
LIMIT 5;
-- Create a new order with 'processing' status
DO $$
DECLARE
    v_order_id UUID := gen_random_uuid();
    v_customer_id UUID;
BEGIN
    -- Get a valid customer_id
    SELECT customer_id INTO v_customer_id FROM customers LIMIT 1;
    
    -- Insert a new order
    INSERT INTO orders (
        order_id, 
        customer_id, 
        order_status,
        order_purchase_timestamp,
        order_estimated_delivery_date
    ) VALUES (
        v_order_id,
        v_customer_id,
        'processing',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + INTERVAL '7 days'
    );
    
    -- Display the order_id for the next step
    RAISE NOTICE 'Created order with ID: %', v_order_id;
END;
$$;

-- Cancel the processing order (this should succeed)
SELECT simple_cancel_order('bd74b534-d953-44d3-936e-a737eccb61e2');
-- Question 4
 -- 1.
EXPLAIN ANALYZE
SELECT o.order_id, o.order_status, o.order_purchase_timestamp, 
       c.customer_id, c.customer_city, c.customer_state
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_purchase_timestamp BETWEEN '2018-01-01' AND '2018-03-31'
AND c.customer_state = 'SP';

CREATE INDEX idx_orders_purchase_timestamp ON orders (order_purchase_timestamp);
CREATE INDEX idx_customers_state ON customers (customer_state);
CREATE INDEX idx_orders_customer_id ON orders (customer_id);

EXPLAIN ANALYZE
SELECT o.order_id, o.order_status, o.order_purchase_timestamp, 
       c.customer_id, c.customer_city, c.customer_state
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_purchase_timestamp BETWEEN '2018-01-01' AND '2018-03-31'
AND c.customer_state = 'SP';

--2. 
EXPLAIN ANALYZE
SELECT s.seller_id, s.seller_city, s.seller_state, 
       COUNT(oi.order_id) as order_count,
       SUM(oi.price) as total_sales
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
HAVING SUM(oi.price) > 10000
ORDER BY total_sales DESC;

REATE INDEX idx_order_items_seller_id ON order_items (seller_id);
CREATE INDEX idx_order_items_price ON order_items (price);

EXPLAIN ANALYZE
SELECT s.seller_id, s.seller_city, s.seller_state, 
       COUNT(oi.order_id) as order_count,
       SUM(oi.price) as total_sales
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
HAVING SUM(oi.price) > 10000
ORDER BY total_sales DES

-- 3. 

EXPLAIN ANALYZE
SELECT p.product_id, p.product_category_name,
       COUNT(DISTINCT oi.order_id) as order_count,
       AVG(oi.price) as avg_price
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
WHERE p.product_category_name = 'furniture_decor'
GROUP BY p.product_id, p.product_category_name
HAVING COUNT(DISTINCT oi.order_id) > 10
ORDER BY order_count DESC;

CREATE INDEX idx_products_category ON products (product_category_name);
CREATE INDEX idx_order_items_product_id ON order_items (product_id);
CREATE INDEX idx_product_category_order_count ON products (product_category_name, product_id) INCLUDE (product_name_length);

EXPLAIN ANALYZE
SELECT p.product_id, p.product_category_name,
       COUNT(DISTINCT oi.order_id) as order_count,
       AVG(oi.price) as avg_price
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
WHERE p.product_category_name = 'furniture_decor'
GROUP BY p.product_id, p.product_category_name
HAVING COUNT(DISTINCT oi.order_id) > 10
ORDER BY order_count DESC;

