CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp Date,
    order_approved_at Date,
    order_delivered_carrier_date Date,
    order_delivered_customer_date Date,
    order_estimated_delivery_date Date
);

Copy orders from 'P:\Projects\Ecommerce_SQL\olist_orders_dataset.csv'
DELIMITER ','
CSV HEADER;

CREATE TABLE order_payments (
    order_id  VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10, 2)
    
);
-- drop table order_items;
Copy order_payments from 'P:\Projects\Ecommerce_SQL\olist_order_payments_dataset.csv'
DELIMITER ','
CSV HEADER;

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date Date,
    price DECIMAL(10, 2),
    freight_value DECIMAL(10, 2)
    
);
Copy order_items from 'P:\Projects\Ecommerce_SQL\olist_order_items_dataset.csv'
DELIMITER ','
CSV HEADER;

CREATE TABLE order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(100),
    review_comment_message TEXT,
    review_creation_date DATE,
    review_answer_timestamp Date
);

Copy order_reviews from 'P:\Projects\Ecommerce_SQL\olist_order_reviews_dataset.csv'
DELIMITER ','
CSV HEADER;

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g DECIMAL(10, 2),
    product_length_cm DECIMAL(10, 2),
    product_height_cm DECIMAL(10, 2),
    product_width_cm DECIMAL(10, 2)
);

Copy products from 'P:\Projects\Ecommerce_SQL\olist_products_dataset.csv'
DELIMITER ','
CSV HEADER;

CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

Copy product_category_name_translation from 'P:\Projects\Ecommerce_SQL\product_category_name_translation.csv'
DELIMITER ','
CSV HEADER;

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(2)
);
Copy sellers from 'P:\Projects\Ecommerce_SQL\olist_sellers_dataset.csv'
DELIMITER ','
CSV HEADER;

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY ,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);
Copy customers from 'P:\Projects\Ecommerce_SQL\olist_customers_dataset.csv'
DELIMITER ','
CSV HEADER;

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat FLOAT,
    geolocation_lng FLOAT,
    geolocation_city VARCHAR(100) ,
    geolocation_state VARCHAR(5)
);
-- Drop table geolocation
Copy geolocation from 'P:\Projects\Ecommerce_SQL\olist_geolocation_dataset.csv'
DELIMITER ','
CSV HEADER;
-- select * from geolocation



CREATE TABLE leads_qualified (
    mql_id VARCHAR(50) PRIMARY KEY,
    first_contact_date DATE,
    landing_page_id VARCHAR(50),
    origin VARCHAR(50)
);
Copy leads_qualified from 'P:\Projects\Ecommerce_SQL\olist_marketing_qualified_leads_dataset.csv'
DELIMITER ','
CSV HEADER;
Drop table leads_closed
CREATE TABLE leads_closed (
    mql_id VARCHAR(50)PRIMARY KEY ,
    seller_id VARCHAR(50) ,
    sdr_id VARCHAR(50),
    sr_id VARCHAR(50),
    won_date DATE,
    business_segment VARCHAR(100),
    lead_type VARCHAR(50),
    lead_behaviour_profile VARCHAR(50),
    has_company VARCHAR(10),
    has_gtin VARCHAR(10),
    average_stock VARCHAR(50),
    business_type VARCHAR(50),
    declared_product_catalog_size INT,
    declared_monthly_revenue DECIMAL(10, 2)
);

Copy leads_closed from 'P:\Projects\Ecommerce_SQL\olist_closed_deals_dataset.csv'
DELIMITER ','
CSV HEADER;




SELECT DISTINCT lq.seller_id
FROM leads_closed lc
LEFT JOIN sellers s ON s.seller_id = lq.seller_id
WHERE s.seller_id IS NULL;

INSERT INTO sellers (seller_id, seller_zip_code_prefix, seller_city, seller_state)
SELECT DISTINCT 
    lc.seller_id,   -- The missing seller_id from leads_qualified
    0,            -- Setting the prefix column value to '0'
    'N/A',          -- Setting the city column to 'N/A'
    'NA'           -- Setting the state column to 'N/A'
FROM leads_closed lc
LEFT JOIN sellers s ON s.seller_id = lc.seller_id
WHERE s.seller_id IS NULL;


INSERT INTO geolocation (geolocation_zip_code_prefix ,
    geolocation_lat ,
    geolocation_lng ,
    geolocation_city  ,
    geolocation_state )
SELECT DISTINCT 
    s.seller_zip_code_prefix,   -- The missing seller_id from leads_qualified
    0, 0,           -- Setting the prefix column value to '0'
    'N/A',          -- Setting the city column to 'N/A'
    'NA'           -- Setting the state column to 'N/A'
FROM sellers s
LEFT JOIN geolocation g ON g.geolocation_zip_code_prefix = s.seller_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL;

INSERT INTO geolocation (geolocation_zip_code_prefix ,
    geolocation_lat ,
    geolocation_lng ,
    geolocation_city  ,
    geolocation_state )
SELECT DISTINCT 
    c.seller_zip_code_prefix,   -- The missing seller_id from leads_qualified
    0, 0,           -- Setting the prefix column value to '0'
    'N/A',          -- Setting the city column to 'N/A'
    'NA'           -- Setting the state column to 'N/A'
FROM sellers c
LEFT JOIN geolocation g ON g.geolocation_zip_code_prefix = c.seller_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL;


SELECT geolocation_zip_code_prefix, COUNT(*) AS group_count
FROM geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*)>1;


WITH DuplicateRows AS (
    SELECT 
        geolocation_zip_code_prefix, 
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state,
        ROW_NUMBER() OVER (PARTITION BY geolocation_zip_code_prefix ORDER BY geolocation_zip_code_prefix) AS rn
    FROM 
        geolocation
)
DELETE FROM geolocation
WHERE geolocation_zip_code_prefix IN (
    SELECT geolocation_zip_code_prefix
    FROM DuplicateRows
    WHERE rn > 1
);


INSERT INTO geolocation (geolocation_zip_code_prefix ,
    geolocation_lat ,
    geolocation_lng ,
    geolocation_city  ,
    geolocation_state )
SELECT DISTINCT 
    c.customer_zip_code_prefix,   -- The missing seller_id from leads_qualified
    0, 0,           -- Setting the prefix column value to '0'
    'N/A',          -- Setting the city column to 'N/A'
    'NA'           -- Setting the state column to 'N/A'
FROM customers c
LEFT JOIN geolocation gl ON gl.geolocation_zip_code_prefix = c.customer_zip_code_prefix
WHERE gl.geolocation_zip_code_prefix IS NULL;

ALTER TABLE order_payments
ADD CONSTRAINT fk_order_payments_order
FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_order
FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_product
FOREIGN KEY (product_id) REFERENCES products(product_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_seller
FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);

ALTER TABLE order_reviews
ADD CONSTRAINT fk_order_reviews_order
FOREIGN KEY (order_id) REFERENCES orders(order_id);

DELETE FROM leads_closed
WHERE seller_id = 'b3a449163f5fe8657f2f0c83f41e7a5a';

ALTER TABLE leads_closed
ADD CONSTRAINT fk_leads_closed_seller
FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);

ALTER TABLE leads_closed
ADD CONSTRAINT fk_leads_closed_mql
FOREIGN KEY (mql_id) REFERENCES leads_qualified(mql_id);

ALTER TABLE geolocation
ADD CONSTRAINT pk_geolocation PRIMARY KEY (geolocation_zip_code_prefix);

ALTER TABLE sellers
ADD CONSTRAINT fk_sellers_geolocation
FOREIGN KEY (seller_zip_code_prefix) REFERENCES geolocation(geolocation_zip_code_prefix);

ALTER TABLE customers
ADD CONSTRAINT fk_customers_geolocation
FOREIGN KEY (customer_zip_code_prefix) REFERENCES geolocation(geolocation_zip_code_prefix);


