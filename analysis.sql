-->> Customer Metrics

-- 1.Customer Lifetime Value (CLV):
-- Sum of the total order values per customer (top 5).

SELECT customer_id, CONCAT('R$ ', SUM(payment_value)) AS total_order_value 
FROM  orders 
JOIN  order_payments ON orders.order_id = order_payments.order_id 
GROUP BY customer_id
Order By SUM(payment_value) desc LIMIT 10;

-- Avg of the total order values per customer:
SELECT CONCAT('R$ ', ROUND(AVG(payment_value), 2)) AS total_order_value
FROM orders 
JOIN order_payments ON orders.order_id = order_payments.order_id;

-- Average Order Value (AOV)
-- This query calculates the average value of an order.
SELECT CONCAT('R$ ', ROUND(SUM(payment_value) / COUNT(DISTINCT orders.order_id), 2)) AS average_order_value 
FROM  orders 
JOIN order_payments 
ON  orders.order_id = order_payments.order_id;

-- 3. Customer Segmentation by Location
-- This query groups customers based on their 
-- location (customer_state or customer_city), and shows the total order count per location.

-- top 10 cities by number of orders

SELECT 
    UPPER(customer_city) AS city,
    COUNT(orders.order_id) as city_order_count
FROM 
    customers
    JOIN orders USING (customer_id)
GROUP BY customer_city
ORDER BY city_order_count DESC
LIMIT 10;

-- top 10 states by number of orders

SELECT 
    UPPER(customer_state) AS state,
    COUNT(orders.order_id) as states_order_count
FROM 
    customers
    JOIN orders USING (customer_id)
GROUP BY customer_state
ORDER BY states_order_count DESC
LIMIT 10;

-- states by number of order value

SELECT 
    customer_state,  
    CONCAT('R$ ', ROUND(SUM(payment_value), 2)) AS total_order_value 
FROM orders o JOIN customers c
ON o.customer_id = c.customer_id 
JOIN  order_payments op
ON o.order_id = op.order_id 
GROUP BY  customer_state
	order by SUM(payment_value) desc;

-- cities by number of order value

SELECT 
    UPPER(c.customer_city),  
    CONCAT('R$ ', ROUND(SUM(op.payment_value), 2)) AS total_order_value 
FROM orders o JOIN customers c
ON o.customer_id = c.customer_id 
JOIN  order_payments op
ON o.order_id = op.order_id 
GROUP BY  c.customer_city
	order by SUM(op.payment_value) desc;

-- 2. Order Metrics

-- Total Orders:
-- Total number of orders placed.

SELECT 
    COUNT(order_id) AS total_orders
FROM 
    orders;

-- Order Status Breakdown
-- This query returns the distribution of orders based on their status (e.g., delivered, pending, canceled).

SELECT 
    order_status, COUNT(order_id) AS order_count
FROM orders
GROUP BY order_status order by order_count desc;

--  Order Delivery Time
-- This query calculates the average time between the order placement and delivery to the customer
SELECT 
    Round(AVG(order_delivered_customer_date - order_purchase_timestamp),0) AS avg_delivery_time
FROM orders
WHERE  order_delivered_customer_date IS NOT NULL;

-- 3. Product Metrics

-- Top-Selling Products
-- This query returns the products with the highest number of sales, sorted in descending order.

SELECT 
    oi.product_id, COUNT(oi.product_id) AS total_sales, pc.product_category_name_english
FROM order_items oi JOIN products p 
	ON p.product_id = oi.product_id
	JOIN product_category_name_translation pc
	ON pc.product_category_name = p.product_category_name
GROUP BY oi.product_id, pc.product_category_name_english
ORDER BY  total_sales DESC;

-- Average Product Rating
-- This query calculates the average review score for each product.

SELECT 
    oi.product_id, AVG(review_score) AS avg_rating, pc.product_category_name_english as Category
FROM order_reviews rev JOIN order_items oi ON  rev.order_id = oi.order_id
	JOIN products p 
	ON p.product_id = oi.product_id
	JOIN product_category_name_translation pc
	ON pc.product_category_name = p.product_category_name
GROUP BY oi.product_id,Category ORDER BY avg_rating desc;

-- Product Return Rate
-- This query calculates the percentage of products that were returned or refunded.

WITH total_orders AS (
    SELECT product_id,COUNT(order_id) AS total_orders
    FROM order_items
    GROUP BY product_id
),
cancelled_orders AS (
    SELECT  oi.product_id, COUNT(o.order_id) AS cancelled_orders 
    FROM  order_items oi JOIN orders o ON oi.order_id = o.order_id
    WHERE order_status = 'canceled' OR order_status = 'unavailable'
    GROUP BY oi.product_id
)
SELECT t.product_id, 
     CONCAT(ROUND(r.cancelled_orders * 100.0 / t.total_orders, 2), '%') AS cancellation_rate
FROM total_orders t
LEFT JOIN cancelled_orders r ON t.product_id = r.product_id
	where (r.cancelled_orders * 100.0 / t.total_orders)>0
	order by (r.cancelled_orders * 100.0 / t.total_orders) desc;

-- High Value Orders Product wise

SELECT 
    pc.product_category_name_english AS product_category,
    CONCAT('R$ ', ROUND(SUM(op.payment_value),2)) AS order_value
FROM 
    orders o
JOIN 
    customers c ON o.customer_id = c.customer_id
JOIN 
    order_items oi ON o.order_id = oi.order_id
JOIN 
    order_payments op ON o.order_id = op.order_id
JOIN 
    products p ON oi.product_id = p.product_id
JOIN 
    product_category_name_translation pc ON pc.product_category_name = p.product_category_name
GROUP BY 
    pc.product_category_name
HAVING 
    SUM(op.payment_value) > 1000 
ORDER BY 
    SUM(op.payment_value) DESC;

-- Expensive Orders Product wise

SELECT 
    pc.product_category_name_english AS product_category,
    CONCAT('R$ ', ROUND(AVG(op.payment_value),2)) AS total_order_value
FROM 
    orders o
JOIN 
    customers c ON o.customer_id = c.customer_id
JOIN 
    order_items oi ON o.order_id = oi.order_id
JOIN 
    order_payments op ON o.order_id = op.order_id
JOIN 
    products p ON oi.product_id = p.product_id
JOIN 
    product_category_name_translation pc ON pc.product_category_name = p.product_category_name
GROUP BY 
    pc.product_category_name
 HAVING 
    AVG(op.payment_value) > 200
ORDER BY 
    AVG(op.payment_value) DESC;

-- 4. Sellers Metrics

-- Top Sellers by Revenue
SELECT seller_id, CONCAT('R$ ', ROUND(SUM(payment_value), 2)) AS total_revenue
FROM order_items oi
JOIN order_payments op ON oi.order_id = op.order_id
GROUP BY seller_id
ORDER BY SUM(payment_value) DESC;

-- Order Delivery Performance by Seller
SELECT seller_id, ROUND(AVG(order_delivered_carrier_date - order_approved_at), 0) AS avg_delivery_time
FROM  order_items oi
JOIN  orders o ON oi.order_id = o.order_id
WHERE order_delivered_carrier_date IS NOT NULL
GROUP BY seller_id
HAVING COUNT(o.order_id) > 10
ORDER BY avg_delivery_time ASC
	limit 10
	;


CREATE VIEW ProductWithCategoryEnglish AS
SELECT 
    p.product_id,
    p.product_category_name, 
    pc.product_category_name_english AS category_name_english
FROM 
    products p
JOIN 
    product_category_name_translation pc 
ON 
    p.product_category_name = pc.product_category_name;

-- 5.Reviews Metrics

-- Average Review
SELECT 
    AVG(review_score) AS avg_review_score
FROM 
    order_reviews;

-- Average Review Category wise
SELECT 
   p.category_name_english AS Category, ROUND(AVG(review_score),2) AS avg_review_score
FROM 
    order_reviews o JOIN order_items oi ON o.order_id=oi.order_id
	JOIN ProductWithCategoryEnglish p 
	ON p.product_id = oi.product_id
	
	Group BY p.category_name_english
	Order by AVG(review_score) DESC

-- Average reviews for high value orders
	SELECT 
     
    AVG(r.review_score) AS avg_review_score
FROM 
    orders o
JOIN 
    order_items oi ON o.order_id = oi.order_id
JOIN 
    products p ON oi.product_id = p.product_id
JOIN 
    product_category_name_translation pc ON p.product_category_name = pc.product_category_name 
JOIN 
    order_reviews r ON o.order_id = r.order_id
WHERE 
    oi.price > 200

ORDER BY 
    avg_review_score DESC;


-- 6. Marketing Metrics 
-- Creating a view combining two different tables on lead for convenience
CREATE VIEW Marketing AS
SELECT 
    lc.*,lq.first_contact_date ,lq.landing_page_id, lq.origin 
FROM 
    leads_closed lc JOIN 
    leads_qualified lq 
ON 
    lc.mql_id = lq.mql_id

-- Average days needed to convert a lead

SELECT 
    origin, 
    ROUND(AVG(won_date - first_contact_date), 0) AS AVG_days_needed,
    CONCAT(ROUND((COUNT(mql_id) * 100.0 / SUM(COUNT(mql_id)) OVER ()),2),'%') AS percentage_of_leads
FROM 
    Marketing
GROUP BY 
    origin;

-- Lead-to-Order-Delivery Conversion Time For different Sellers

SELECT s.seller_id, ROUND(AVG(o.order_delivered_customer_date - m.first_contact_date), 0) AS AVG_days_needed_lead_to_order
From Marketing m JOIN sellers s ON m.seller_id = s.seller_id
JOIN order_items oi on oi.seller_id = s.seller_id
JOIN orders o on o.order_id = oi.order_id
	Group By s.seller_id
HAVING AVG(o.order_delivered_customer_date - m.first_contact_date) IS NOT NULL ORDER BY AVG_days_needed_lead_to_order;

-- Successful leads
SELECT origin AS lead_generation_source,
CONCAT(ROUND((COUNT(landing_page_id) * 100.0 / SUM(COUNT(landing_page_id)) OVER ()),2),'%') As percentage
	From leads_qualified lc 
Group By origin;
-- Website and Social Media Marketing Effectiveness :
WITH total_leads AS (
    SELECT 
        SUM(COUNT(landing_page_id)) OVER () AS total_leads
    FROM 
        leads_qualified
)
SELECT 
    CONCAT(ROUND(
        (COUNT(CASE WHEN origin IN ('direct_traffic', 'organic_search') THEN landing_page_id END) * 100.0) 
        / (SELECT total_leads FROM total_leads), 2), '%') AS lead_generation_from_website,
    CONCAT(ROUND(
        (COUNT(CASE WHEN origin IN ('social') THEN landing_page_id END) * 100.0) 
        / (SELECT total_leads FROM total_leads), 2), '%') AS lead_generation_through_social_media_marketing
FROM 
    leads_qualified;


-- 7. Geolocation Metrics

--  Sales by Region (Customer Location)
-- This query calculates total sales grouped by customer city and state.
SELECT 
    customer_city, customer_state, 
    CONCAT('R$ ',ROUND(SUM(payment_value),2)) AS total_sales
FROM  orders o JOIN 
    order_payments op ON o.order_id = op.order_id
JOIN  customers c ON o.customer_id = c.customer_id
GROUP BY 
    customer_city,customer_state
ORDER BY SUM(payment_value) DESC;

--  Seller Concentration by Region
-- This query calculates the number of sellers in each city and state.

SELECT 
    seller_city, seller_state,  COUNT(seller_id) AS seller_count
FROM sellers
	WHERE seller_state <> 'NA'
GROUP BY seller_city, seller_state
ORDER BY 
    seller_count DESC;

SELECT 
    customer_city, 
    customer_state,  
    COUNT( customer_id) AS  customer_count
FROM 
     customers
WHERE  customer_state <> 'NA'
GROUP BY 
     customer_city,  customer_state
ORDER BY 
     customer_count DESC;


-- 8.Payment Metrics
-- Payment Method Distribution:
-- Percentage of orders paid via different payment methods (e.g., credit card, PayPal).

SELECT 
    payment_type, 
    COUNT(*) AS total_orders,
    CONCAT(ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM order_payments)),2), '%') AS payment_method_percentage
FROM 
    order_payments
GROUP BY 
    payment_type
ORDER BY 
    payment_method_percentage DESC;

-- Installment Plans Usage:
-- Number of orders using installment payments.

SELECT 
    pc.product_category_name_english AS product_category, count(oi.*) AS oder_quantity,
    SUM(op.payment_installments) AS installment_orders, 
	(SUM(op.payment_installments)/count(oi.*)) AS avg_installments_per_orders,
	CONCAT('R$ ',ROUND( AVG(op.payment_value / op.payment_installments),2)) AS avg_installment_value     
FROM 
    order_payments op
JOIN 
    order_items oi ON op.order_id = oi.order_id
JOIN 
    products p ON oi.product_id = p.product_id
JOIN 
    product_category_name_translation pc ON p.product_category_name = pc.product_category_name
WHERE 
    op.payment_installments > 1
GROUP BY 
    pc.product_category_name_english
ORDER BY 
    avg_installments_per_orders DESC;

-- 9. Shipping Metrics
-- On-time Delivery Rate (i.e., the percentage of orders delivered before the estimated delivery date)
SELECT 
    CONCAT(ROUND((COUNT(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date 
	THEN 1 END) * 100.0 / COUNT(order_id)),2),'%') AS on_time_delivery_rate
FROM 
    orders
WHERE 
    order_delivered_customer_date IS NOT NULL 
    AND order_estimated_delivery_date IS NOT NULL;
-- Average delivery cost region-wise
SELECT 
    c.customer_city, 
    c.customer_state, 
    ROUND(AVG(oi.freight_value), 2) AS avg_freight_value
FROM 
    orders o
JOIN 
    customers c ON o.customer_id = c.customer_id
JOIN 
    order_items oi ON o.order_id = oi.order_id
GROUP BY 
    c.customer_city, c.customer_state
ORDER BY 
    avg_freight_value DESC;
-- Average delivery cost category wise
SELECT  pc.product_category_name_english AS product_category, 
    ROUND(AVG(oi.freight_value), 2) AS avg_freight_value
FROM 
    orders o
JOIN 
    customers c ON o.customer_id = c.customer_id
JOIN 
    order_items oi ON o.order_id = oi.order_id
JOIN 
    products p ON oi.product_id = p.product_id
JOIN
	product_category_name_translation pc ON pc.product_category_name=p.product_category_name
GROUP BY 
     pc.product_category_name_english
ORDER BY 
    avg_freight_value DESC;


--10. Growth Metrics
-- Revenue, Net Profit , Average Order Profit year on year category wise

SELECT 
    pc.product_category_name_english AS product_category, 
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS order_year,
	count(op.order_id) AS number_of_orders,
    SUM(op.payment_value) AS total_revenue, 
    SUM(op.payment_value - (oi.price + oi.freight_value)) AS net_profit, 
    AVG(op.payment_value - (oi.price + oi.freight_value)) AS avg_order_profit
FROM 
    products p JOIN product_category_name_translation pc on pc.product_category_name=p.product_category_name
JOIN 
    order_items oi ON p.product_id = oi.product_id
JOIN 
    order_payments op ON oi.order_id = op.order_id
JOIN 
    orders o ON oi.order_id = o.order_id
GROUP BY 
    pc.product_category_name_english, EXTRACT(YEAR FROM o.order_purchase_timestamp)
ORDER BY 
    order_year DESC, net_profit DESC;

-- Growth of Revenue, Net Profit , Average Order Profit year on year category wise
WITH yearly_stats AS (
    SELECT 
        pc.product_category_name_english AS product_category, 
        EXTRACT(YEAR FROM o.order_purchase_timestamp) AS order_year,
        SUM(op.payment_value) AS total_revenue, 
        SUM(op.payment_value - (oi.price + oi.freight_value)) AS net_profit, 
        AVG(op.payment_value - (oi.price + oi.freight_value)) AS avg_order_profit
    FROM 
        products p 
    JOIN 
        product_category_name_translation pc ON pc.product_category_name = p.product_category_name
    JOIN 
        order_items oi ON p.product_id = oi.product_id
    JOIN 
        order_payments op ON oi.order_id = op.order_id
    JOIN 
        orders o ON oi.order_id = o.order_id
    GROUP BY 
        pc.product_category_name_english, EXTRACT(YEAR FROM o.order_purchase_timestamp)
    ORDER BY 
        order_year DESC, net_profit DESC
)
SELECT 
    product_category, 
    order_year, 
    total_revenue, 
    ROUND(((total_revenue - LAG(total_revenue) OVER (PARTITION BY product_category ORDER BY order_year)) / 
        NULLIF(LAG(total_revenue) OVER (PARTITION BY product_category ORDER BY order_year), 0)) * 100, 2) AS revenue_yoy_growth_percentage,
    ROUND(((net_profit - LAG(net_profit) OVER (PARTITION BY product_category ORDER BY order_year)) / 
        NULLIF(LAG(net_profit) OVER (PARTITION BY product_category ORDER BY order_year), 0)) * 100, 2) AS net_profit_yoy_growth_percentage,
    ROUND(((avg_order_profit - LAG(avg_order_profit) OVER (PARTITION BY product_category ORDER BY order_year)) / 
        NULLIF(LAG(avg_order_profit) OVER (PARTITION BY product_category ORDER BY order_year), 0)) * 100, 2) AS avg_order_profit_yoy_growth_percentage
FROM 
    yearly_stats
ORDER BY 
    product_category, order_year;


-- top 10 sellers of 2018
WITH yearly_seller_stats AS (
    SELECT 
        oi.seller_id, 
        EXTRACT(YEAR FROM o.order_purchase_timestamp) AS order_year,
        SUM(op.payment_value) AS total_revenue
    FROM 
        order_items oi
    JOIN 
        orders o ON oi.order_id = o.order_id
    JOIN 
        order_payments op ON oi.order_id = op.order_id
    GROUP BY 
        oi.seller_id, EXTRACT(YEAR FROM o.order_purchase_timestamp)
),

seller_growth AS (
    SELECT 
        seller_id, 
        order_year, 
        total_revenue, 
        LAG(total_revenue) OVER (PARTITION BY seller_id ORDER BY order_year) AS prev_year_revenue,
        ROUND(((total_revenue - LAG(total_revenue) OVER (PARTITION BY seller_id ORDER BY order_year)) / 
            NULLIF(LAG(total_revenue) OVER (PARTITION BY seller_id ORDER BY order_year), 0)) * 100, 2) AS revenue_yoy_growth
    FROM 
        yearly_seller_stats
)

SELECT 
    seller_id, 
    order_year, 
    total_revenue, 
    revenue_yoy_growth
FROM 
    seller_growth
WHERE 
    revenue_yoy_growth IS NOT NULL
Group BY seller_id, order_year, 
    total_revenue, 
    revenue_yoy_growth
HAVING order_year IN (2018)	
ORDER BY 
    total_revenue DESC
LIMIT 10;

