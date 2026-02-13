-- STARTING WITH DATA QUALITY AND CLEANING
-- Inspecting the orders table quality
SELECT COUNT(*)
FROM orders;

-- Checking for NULLS
Select 
sum(order_id IS NULL) AS Null_order_id,
sum(customer_id IS NULL) AS Null_customer_id,
sum(order_status IS NULL) AS Null_order_status,
sum(order_purchase_timestamp IS NULL) AS Null_order_purchase_timestamp,
sum(order_approved_at IS NULL) AS Null_order_approved_at,
sum(order_delivered_carrier_date IS NULL) AS Null_order_approved_carrier_date,
sum(order_delivered_customer_date IS NULL) AS Null_order_delivered_customer_date,
sum(order_estimated_delivery_date IS NULL) AS Null_order_estimated_delivery_date
FROM orders;

-- Cheking for duplicate
SELECT order_id, COUNT(*) AS dup_order
FROM orders
group by order_id
Having count(*) > 1;

-- Checking for weird timestamps
SELECT *
FROM orders
WHERE order_purchase_timestamp > order_estimated_delivery_date;

-- Lets understand where the nulls are coming from
SELECT *
FROM orders
WHERE customer_id IS NULL
   OR order_status IS NULL
   OR order_purchase_timestamp IS NULL
   OR order_approved_at IS NULL
   OR order_delivered_carrier_date IS NULL
   OR order_delivered_customer_date IS NULL
   OR order_estimated_delivery_date IS NULL;

-- Lets delete the umpty orders
DELETE
FROM orders
WHERE customer_id IS NULL
   OR order_status IS NULL
   OR order_purchase_timestamp IS NULL
   OR order_approved_at IS NULL
   OR order_delivered_carrier_date IS NULL
   OR order_delivered_customer_date IS NULL
   OR order_estimated_delivery_date IS NULL;

-- checking to understand the duplicates
SELECT * 
from orders
where order_id = '9afb4dbb97ba2e4b69f72df48c4cf901';

-- running updates to clean bad dates
-- ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
SELECT @@GLOBAL.sql_mode;

-- temporarily setting a safe sql mode
SET SESSION sql_mode = 'NO_ENGINE_SUBSTITUTION';

UPDATE orders
SET order_delivered_carrier_date = NULL
WHERE order_delivered_carrier_date = '0000-00-00 00:00:00';

UPDATE orders
SET order_approved_at = NULL
WHERE order_approved_at = '0000-00-00 00:00:00';

UPDATE orders
SET order_delivered_customer_date = NULL
WHERE order_delivered_customer_date = '0000-00-00 00:00:00';

UPDATE orders
SET order_purchase_timestamp = NULL
WHERE order_purchase_timestamp = '0000-00-00 00:00:00';

UPDATE orders
SET order_estimated_delivery_date = NULL
WHERE order_estimated_delivery_date = '0000-00-00 00:00:00';

-- removing exact dupicates from the orders table
-- we create a backup table
CREATE TABLE orders_backup AS
SELECT * FROM orders;

CREATE TABLE orders_deduped AS 
select * 
from (select *,
	row_number() over(partition by order_id order by order_id) as rn
    from orders) as temp
where rn = 1;

DROP TABLE orders;
RENAME TABLE orders_deduped to orders;
SELECT * FROM orders;


-- DATA QUALITY OF ORDER_ITEMS
SELECT COUNT(*) from order_items;

Select 
sum(order_id IS NULL) AS Null_order_id,
sum(order_item_id IS NULL) AS Null_order_item_id,
sum(product_id IS NULL) AS Null_product_id,
sum(seller_id IS NULL) AS Null_seller_id,
sum(shipping_limit_date IS NULL) AS Null_shipping_limit_date,
sum(price IS NULL) AS Null_price,
sum(freight_value IS NULL) ASfreight_value
FROM order_items;

SELECT order_id, order_item_id, COUNT(*) AS duplicate_order
FROM order_items
group by order_id, order_item_id
Having count(*) > 1;

-- checking for negative values
select * from order_items
where price < 0 or freight_value < 0;

-- checking for invalid dates
select * from order_items
where shipping_limit_date = '0000-00-00 00:00:00';

-- DATA QUALITY ORDER_PAYMENTS
select 
sum(order_id is null) null_order_id,
sum(payment_sequential is null) null_payment_sequential,
sum(payment_type is null) null_payment_type,
sum(payment_installments is null) null_payment_installments
from order_payments;

select order_id, count(*) duplicate_order_payments
from order_payments
group by order_id
having count(*) > 1;

select * from order_payments where payment_value < 0;
select distinct payment_type from order_payments;

update order_payments
set payment_type = NULL 
where payment_type = 'not_defined';

-- DATA QUALITY PRODUCTS
SELECT
  SUM(product_id IS NULL) AS null_product_id,
  SUM(product_category_name IS NULL) AS null_category,
  SUM(product_name_length IS NULL) AS null_name_len,
  SUM(product_description_length IS NULL) AS null_desc_len,
  SUM(product_photos_qty IS NULL) AS null_photos,
  SUM(product_weight_g IS NULL) AS null_weight,
  SUM(product_length_cm IS NULL) AS null_length,
  SUM(product_height_cm IS NULL) AS null_height,
  SUM(product_width_cm IS NULL) AS null_width
FROM products;

select product_id, count(*) product_count
from products
group by product_id
having count(*) > 1;

-- checking for negatives
SELECT *
FROM products
WHERE product_weight_g < 0
   OR product_length_cm < 0
   OR product_height_cm < 0
   OR product_width_cm < 0;

-- All the facts table are clean, now i will work on cleaning the dimensions
-- 1. customers table
select 
sum(customer_id is null) null_customer_id,
sum(customer_unique_id is null) null_customer_unique_id,
sum(customer_zip_code_prefix is null) null_customer_zip_code_prefix,
sum(customer_city is null) null_customer_city,
sum(customer_state is null) null_cutomer_state
from customers;

-- 2. sellers
SELECT
  SUM(seller_id IS NULL) AS null_seller_id,
  SUM(seller_zip_code_prefix IS NULL) AS null_zip,
  SUM(seller_city IS NULL) AS null_city,
  SUM(seller_state IS NULL) AS null_state
FROM sellers;

SELECT seller_id, COUNT(*) AS dup_count
FROM sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

-- 3. order_reviews
SELECT
  SUM(review_id IS NULL) AS null_review_id,
  SUM(order_id IS NULL) AS null_order_id,
  SUM(review_score IS NULL) AS null_score,
  SUM(review_comment_title IS NULL) AS null_title,
  SUM(review_comment_message IS NULL) AS null_message,
  SUM(review_creation_date IS NULL) AS null_creation,
  SUM(review_answer_timestamp IS NULL) AS null_response_time
FROM order_reviews;

-- finding orders with multiple reviews
SELECT review_id, COUNT(*) AS dup_count
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
order by review_id desc;

SELECT *
FROM order_reviews
WHERE review_id IN (
  SELECT review_id
  FROM order_reviews
  GROUP BY review_id
  HAVING COUNT(*) > 1
);
-- deduplicating the order_reviews table
create table order_reviews_clean as
select * 
from (
	select *,
    row_number() over(partition by order_id order by review_answer_timestamp desc) rn
    from order_reviews
    ) ranked
where rn = 1;

drop table order_reviews;
rename table order_reviews_clean to order_reviews; 

-- PHASE 1 OF THE ANALYSIS (BUSSINESS KPI ANALYSIS)
-- 1. Total orders, Revenue and Customers
SELECT 
	COUNT(DISTINCT o.order_id) Total_orders,
    ROUND(SUM(op.payment_value), 2) Total_revenue,
    COUNT(DISTINCT c.customer_id) Total_customers
FROM order_payments op
JOIN orders o ON op.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id;

-- 2. Monthly Trend (Oders over Time)
SELECT DATE_FORMAT(order_purchase_timestamp, '%Y:%m') Order_month,
COUNT(O.order_id) Order_count,
ROUND(SUM(OP.payment_value), 2) Total_revenue
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY Order_month
ORDER BY Order_month;

-- 3. Top Payment Method
SELECT payment_type,
COUNT(*) Num_transaction,
ROUND(SUM(payment_value), 2) Total_payment
FROM order_payments
GROUP BY payment_type
ORDER BY Total_payment DESC;

-- 4. Average Order Value 
SELECT 
ROUND(SUM(payment_value) / COUNT(DISTINCT order_id), 2) Average_order_value
FROM order_payments;

-- PHASE 2: PRODUCT INSIGHTS
-- 5. Top 10 Best Selling Products By Quantity
SELECT oi.product_id, 
p.product_category_name,
COUNT(*) Total_sold,
ROUND(SUM(oi.price), 2) Total_sales
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY oi.product_id, p.product_category_name
ORDER BY Total_sold DESC
LIMIT 10;

-- 6 Top 10 Category by Sales
SELECT 
  ct.product_category_name_english,
  ROUND(SUM(oi.price), 2) AS category_sales
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN category_translation ct 
  ON p.product_category_name = ct.product_category_name
GROUP BY ct.product_category_name_english
ORDER BY category_sales DESC
LIMIT 10;

-- PHASE 3: DELIVERY PERFORMANCE
-- 7. Average Delivery Time
SELECT 
ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) Avg_delivery_days
FROM orders
WHERE order_status = 'delivered' 
	AND order_delivered_customer_date IS NOT NULL;

-- 8 Late Deliveries (Delivery After Estimated_date)
SELECT 
  COUNT(*) AS late_deliveries,
  ROUND(COUNT(*) * 100.0 / COUNT(order_id), 2) AS percent_late
FROM orders
WHERE order_delivered_customer_date > order_estimated_delivery_date;

-- PHASE 4: CUSTOMER FEEDBACK
-- 9 Review Score Distribution
SELECT 
  review_score,
  COUNT(*) AS count_reviews
FROM order_reviews
GROUP BY review_score
ORDER BY review_score DESC;

-- 10 Correlation Between Review_score And Delivery Time
SELECT 
  r.review_score,
  ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_delivery_days
FROM order_reviews r
JOIN orders o ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY r.review_score
ORDER BY r.review_score DESC;




































































