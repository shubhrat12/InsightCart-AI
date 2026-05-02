-- 1. Customers Table
CREATE TABLE customers (
    customer_id UUID PRIMARY KEY,
    customer_unique_id UUID,
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);
COPY customers
FROM 'C:/Users/ashru/Desktop/Ashruj/UB_Master''s Assignments and Projects/SEMESTER 2/Data Model and Query Language/Project/Project/customers.csv'
WITH (FORMAT csv, HEADER true);

-- Ensure no nulls in primary key
DELETE FROM customers WHERE customer_id IS NULL;

-- Replace NULLs
UPDATE customers
SET customer_zip_code_prefix = (SELECT AVG(customer_zip_code_prefix)::INT FROM customers)
WHERE customer_zip_code_prefix IS NULL;

UPDATE customers
SET customer_city = 'Unknown'
WHERE customer_city IS NULL;

UPDATE customers
SET customer_state = 'Unknown'
WHERE customer_state IS NULL;

SELECT * FROM customers LIMIT 5;

-- 2. Orders Table
CREATE TABLE orders (
    order_id UUID PRIMARY KEY,
    customer_id UUID REFERENCES customers(customer_id),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);
COPY orders
FROM 'C:/Users/ashru/Desktop/Ashruj/UB_Master''s Assignments and Projects/SEMESTER 2/Data Model and Query Language/Project/Project/orders.csv'
WITH (FORMAT csv, HEADER true);

-- Ensure no nulls in primary key
DELETE FROM orders WHERE order_id IS NULL;

-- Replace NULLs
UPDATE orders
SET order_status = 'Unknown'
WHERE order_status IS NULL;

UPDATE orders
SET order_purchase_timestamp = '1970-01-01'
WHERE order_purchase_timestamp IS NULL;

UPDATE orders
SET order_approved_at = '1970-01-01'
WHERE order_approved_at IS NULL;

UPDATE orders
SET order_delivered_carrier_date = '1970-01-01'
WHERE order_delivered_carrier_date IS NULL;

UPDATE orders
SET order_delivered_customer_date = '1970-01-01'
WHERE order_delivered_customer_date IS NULL;

UPDATE orders
SET order_estimated_delivery_date = '1970-01-01'
WHERE order_estimated_delivery_date IS NULL;

SELECT * FROM orders LIMIT 5;

-- 3. Order Items Table
CREATE TABLE order_items (
    order_id UUID REFERENCES orders(order_id),
    order_item_id INT,
    product_id UUID,
    seller_id UUID,
    shipping_limit_date TIMESTAMP,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);
COPY order_items
FROM 'C:/Users/ashru/Desktop/Ashruj/UB_Master''s Assignments and Projects/SEMESTER 2/Data Model and Query Language/Project/Project/order_items.csv'
WITH (FORMAT csv, HEADER true);

-- Ensure no nulls in composite primary key
DELETE FROM order_items WHERE order_id IS NULL OR order_item_id IS NULL;

-- Replace NULLs
UPDATE order_items
SET shipping_limit_date = '1970-01-01'
WHERE shipping_limit_date IS NULL;

UPDATE order_items
SET price = (SELECT AVG(price) FROM order_items)
WHERE price IS NULL;

UPDATE order_items
SET freight_value = (SELECT AVG(freight_value) FROM order_items)
WHERE freight_value IS NULL;

SELECT * FROM order_items LIMIT 5;

-- 4. Sellers Table
CREATE TABLE sellers (
    seller_id UUID PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);
COPY sellers
FROM 'C:/Users/ashru/Desktop/Ashruj/UB_Master''s Assignments and Projects/SEMESTER 2/Data Model and Query Language/Project/Project/sellers.csv'
WITH (FORMAT csv, HEADER true);
-- Ensure no nulls in primary key
DELETE FROM sellers WHERE seller_id IS NULL;
-- Replace NULLs
UPDATE sellers
SET seller_zip_code_prefix = (SELECT AVG(seller_zip_code_prefix)::INT FROM sellers)
WHERE seller_zip_code_prefix IS NULL;
UPDATE sellers
SET seller_city = 'Unknown'
WHERE seller_city IS NULL;
UPDATE sellers
SET seller_state = 'Unknown'
WHERE seller_state IS NULL;
SELECT * FROM sellers LIMIT 5;

-- 5. Products Table
CREATE TABLE products (
    product_id UUID PRIMARY KEY,
    product_category_name VARCHAR(255),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);
COPY products
FROM 'C:/Users/ashru/Desktop/Ashruj/UB_Master''s Assignments and Projects/SEMESTER 2/Data Model and Query Language/Project/Project/products.csv'
WITH (FORMAT csv, HEADER true);
-- Ensure no nulls in primary key
DELETE FROM products WHERE product_id IS NULL;
-- Replace NULLs
UPDATE products
SET product_category_name = 'Unknown'
WHERE product_category_name IS NULL;
UPDATE products
SET product_name_length = (SELECT AVG(product_name_length)::INT FROM products)
WHERE product_name_length IS NULL;
UPDATE products
SET product_description_length = (SELECT AVG(product_description_length)::INT FROM products)
WHERE product_description_length IS NULL;
UPDATE products
SET product_photos_qty = (SELECT AVG(product_photos_qty)::INT FROM products)
WHERE product_photos_qty IS NULL;
UPDATE products
SET product_weight_g = (SELECT AVG(product_weight_g)::INT FROM products)
WHERE product_weight_g IS NULL;
UPDATE products
SET product_length_cm = (SELECT AVG(product_length_cm)::INT FROM products)
WHERE product_length_cm IS NULL;
UPDATE products
SET product_height_cm = (SELECT AVG(product_height_cm)::INT FROM products)
WHERE product_height_cm IS NULL;
UPDATE products
SET product_width_cm = (SELECT AVG(product_width_cm)::INT FROM products)
WHERE product_width_cm IS NULL;
SELECT * FROM products LIMIT 5;

-- 6. Payments Table
CREATE TABLE payments (
    order_id UUID REFERENCES orders(order_id),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);
COPY payments
FROM 'C:/Users/ashru/Desktop/Ashruj/UB_Master''s Assignments and Projects/SEMESTER 2/Data Model and Query Language/Project/Project/payments.csv'
WITH (FORMAT csv, HEADER true);
-- Delete if order_id or payment_sequential is NULL (if you want to make composite PK)
-- Else just clean NULLs
UPDATE payments
SET payment_type = 'Unknown'
WHERE payment_type IS NULL;
UPDATE payments
SET payment_installments = (SELECT AVG(payment_installments)::INT FROM payments)
WHERE payment_installments IS NULL;
UPDATE payments
SET payment_value = (SELECT AVG(payment_value) FROM payments)
WHERE payment_value IS NULL;
SELECT * FROM payments LIMIT 5;
-- 7. Geolocation Table
CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat FLOAT,
    geolocation_lng FLOAT,
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)
);
COPY geolocation
FROM 'C:/Users/ashru/Desktop/Ashruj/UB_Master''s Assignments and Projects/SEMESTER 2/Data Model and Query Language/Project/Project/geolocation.csv'
WITH (FORMAT csv, HEADER true);
-- Replace NULLs
UPDATE geolocation
SET geolocation_lat = (SELECT AVG(geolocation_lat) FROM geolocation)
WHERE geolocation_lat IS NULL;
UPDATE geolocation
SET geolocation_lng = (SELECT AVG(geolocation_lng) FROM geolocation)
WHERE geolocation_lng IS NULL;
UPDATE geolocation
SET geolocation_city = 'Unknown'
WHERE geolocation_city IS NULL;
UPDATE geolocation
SET geolocation_state = 'Unknown'
WHERE geolocation_state IS NULL;
SELECT * FROM geolocation LIMIT 5;

-- 8. Product Category Name Translation
CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(255) PRIMARY KEY,
    product_category_name_english VARCHAR(255)
);
COPY product_category_name_translation
FROM 'C:/Users/ashru/Desktop/Ashruj/UB_Master''s Assignments and Projects/SEMESTER 2/Data Model and Query Language/Project/Project/product_category_name_translation.csv'
WITH (FORMAT csv, HEADER true);

-- No NULL allowed in primary key
DELETE FROM product_category_name_translation WHERE product_category_name IS NULL;

UPDATE product_category_name_translation
SET product_category_name_english = 'Unknown'
WHERE product_category_name_english IS NULL;

SELECT * FROM product_category_name_translation LIMIT 5;

-- 9. E-commerce Traffic Table
CREATE TABLE ecommerce_traffic (
    date DATE PRIMARY KEY,
    page_views INT,
    unique_visitors INT,
    average_session_duration INTERVAL,
    bounce_rate DECIMAL(5,2)
);
COPY ecommerce_traffic
FROM 'C:/Users/ashru/Desktop/Ashruj/UB_Master''s Assignments and Projects/SEMESTER 2/Data Model and Query Language/Project/Project/ecommerce_traffic.csv'
WITH (FORMAT csv, HEADER true);
-- No NULLs in primary key
DELETE FROM ecommerce_traffic WHERE date IS NULL;
UPDATE ecommerce_traffic
SET page_views = (SELECT AVG(page_views)::INT FROM ecommerce_traffic)
WHERE page_views IS NULL;
UPDATE ecommerce_traffic
SET unique_visitors = (SELECT AVG(unique_visitors)::INT FROM ecommerce_traffic)
WHERE unique_visitors IS NULL;
UPDATE ecommerce_traffic
SET average_session_duration = '00:00:00'
WHERE average_session_duration IS NULL;
UPDATE ecommerce_traffic
SET bounce_rate = (SELECT AVG(bounce_rate) FROM ecommerce_traffic)
WHERE bounce_rate IS NULL;
SELECT * FROM ecommerce_traffic LIMIT 5;

-- 10. Social Media Mentions
CREATE TABLE social_media_mentions (
    date DATE,
    platform VARCHAR(50),
    mentions INT,
    PRIMARY KEY (date, platform)
);
COPY social_media_mentions
FROM 'C:/Users/ashru/Desktop/Ashruj/UB_Master''s Assignments and Projects/SEMESTER 2/Data Model and Query Language/Project/Project/social_media_mentions.csv'
WITH (FORMAT csv, HEADER true);
-- No NULLs in composite key
DELETE FROM social_media_mentions WHERE date IS NULL OR platform IS NULL;
UPDATE social_media_mentions
SET mentions = (SELECT AVG(mentions)::INT FROM social_media_mentions)
WHERE mentions IS NULL;
SELECT * FROM social_media_mentions LIMIT 5;

-- 11. Customer Interactions
CREATE TABLE customer_interactions (
    interaction_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    interaction_type VARCHAR(50),
    interaction_date DATE,
    interaction_channel VARCHAR(50),
    feedback_score INT CHECK (feedback_score BETWEEN 1 AND 10)
);
COPY customer_interactions
FROM 'C:/Users/ashru/Desktop/Ashruj/UB_Master''s Assignments and Projects/SEMESTER 2/Data Model and Query Language/Project/Project/customer_interactions.csv'
WITH (FORMAT csv, HEADER true);
UPDATE customer_interactions
SET customer_name = 'Unknown'
WHERE customer_name IS NULL;
UPDATE customer_interactions
SET interaction_type = 'Unknown'
WHERE interaction_type IS NULL;
UPDATE customer_interactions
SET interaction_date = '1970-01-01'
WHERE interaction_date IS NULL;
UPDATE customer_interactions
SET interaction_channel = 'Unknown'
WHERE interaction_channel IS NULL;
UPDATE customer_interactions
SET feedback_score = (SELECT AVG(feedback_score)::INT FROM customer_interactions)
WHERE feedback_score IS NULL;
SELECT * FROM customer_interactions LIMIT 5;
