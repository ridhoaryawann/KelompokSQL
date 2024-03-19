CREATE DATABASE X_Store;
 
USE X_Store ;


CREATE TABLE Users (user_id INT, cookie_id varchar(100), start_date datetime) ;
CREATE TABLE Events1 (visit_id varchar(100), cookie_id varchar(100), 
page_id INT, event_type INT, sequence_number INT, event_time datetime) ;
CREATE TABLE event_identifier (event_type INT, event_name varchar(100)) ;
CREATE TABLE campaign_identifier (campaign_id INT, products varchar(100), 
campaign_name varchar(100), start_date datetime, end_date datetime) ;
CREATE TABLE page_hierarchy (page_id INT, page_name varchar(100),
 product_category varchar(100), product_id INT) ;
 
 #SECTION 1
 
 #QUESTION 1
 
SELECT COUNT(DISTINCT user_id) AS total_users
FROM Users;

#QUESTION 2

WITH cookies AS
   (SELECT user_id,COUNT(DISTINCT cookie_id) AS total_cookies
 FROM users
 GROUP BY user_id
 )
 SELECT round(cast(sum(total_cookies)/count(user_id) AS FLOAT),3)
 AS avg_cookies_per_user
 FROM cookies ;

#QUESTION 3

SELECT EXTRACT(MONTH FROM event_time) AS month, COUNT(DISTINCT visit_id) AS unique_visits
FROM Events1
GROUP BY EXTRACT(MONTH FROM event_time);

#QUESTION 4

SELECT event_type, COUNT(*) AS event_count
FROM Events1
GROUP BY event_type;

#QUESTION 5

SELECT ROUND(COUNT(DISTINCT visit_id)*100.0/(SELECT COUNT(DISTINCT visit_id) FROM Events1 e ) ,2) 
   AS purchase_percentage
   FROM Events1 e JOIN event_identifier ei
   ON e.event_type=ei.event_type
   WHERE event_name='Purchase' ;

 
 #QUESTION 6
 
 SELECT product_category,
  SUM(CASE WHEN event_name='Page View' THEN 1 ELSE 0 END) AS total_views,
  SUM(CASE WHEN event_name='Add to Cart' THEN 1 ELSE 0 END) AS added_to_cart
  FROM Events1 e JOIN event_identifier ei   
  ON e.event_type=ei.event_type JOIN page_hierarchy p
  ON p.page_id=e.page_id
  WHERE product_category IS NOT NULL
  GROUP BY product_category ;
  
  
 #SECTION 2
 
CREATE TABLE Product_in AS 
WITH cte AS (
SELECT
  e.visit_id,
        e.cookie_id,
  e.event_type,
  p.page_name,
  p.page_id,
  p.product_category,
        p.product_id
 FROM Events1 e
 JOIN page_hierarchy p ON e.page_id = p.page_id),

cte2 AS (
 SELECT page_name,
    product_id,
    product_category,
 CASE WHEN event_type = 1 THEN visit_id END AS page_view,
 CASE WHEN event_type = 2 THEN visit_id END AS cart
 FROM cte 
 WHERE product_id IS NOT NULL
),

cte3 AS (
SELECT visit_id AS purchased
FROM Events1
WHERE event_type = 3
),
cte4 AS (
SELECT page_name, 
product_id,
product_category,
COUNT(page_view) AS product_viewed,
COUNT(cart) AS product_addedtocart,
COUNT(purchased) AS product_purchased,
COUNT(cart) - COUNT(purchased) AS product_abadoned
FROM cte2
LEFT JOIN cte3 ON purchased = cart
GROUP BY page_name, product_id, product_category)

SELECT * FROM cte4;

SELECT * FROM product_in;

#SECTION 3

CREATE TABLE Product_cat AS 
WITH cte5 AS (
SELECT
  e.visit_id,
        e.cookie_id,
  e.event_type,
  p.page_name,
  p.page_id,
  p.product_category,
        p.product_id
 FROM Events1 e
 JOIN page_hierarchy p ON e.page_id = p.page_id),

cte6 AS (
SELECT page_name,
    product_category,
 CASE WHEN event_type = 1 THEN visit_id END AS page_view,
 CASE WHEN event_type = 2 THEN visit_id END AS cart
 FROM cte5
 WHERE product_id IS NOT NULL
),

cte7 AS (
SELECT visit_id AS purchased
FROM Events1
WHERE event_type = 3
),
cte8 AS(
SELECT
product_category,
count(page_view) AS product_viewed,
count(cart) AS product_addedtocart,
count(purchased) AS product_purchased,
count(cart) - count(purchased) AS product_abadoned
FROM cte6
LEFT JOIN cte7 ON purchased = cart
GROUP BY product_category)

SELECT *
FROM cte8;

SELECT * FROM product_cat;

#QUESTION 1

SELECT
    page_name,
    product_viewed
FROM product_in
WHERE product_viewed = (
    SELECT MAX(product_viewed)
    FROM product_in
);

SELECT
    page_name,
    product_addedtocart
FROM product_in
WHERE product_addedtocart = (
    SELECT MAX(product_addedtocart)
    FROM product_in
);

SELECT
    page_name,
    product_purchased
FROM product_in
WHERE product_purchased = (
    SELECT MAX(product_purchased)
    FROM product_in
);

#QUESTION 2

SELECT
    page_name,
    product_abadoned
FROM product_in
WHERE product_abadoned = (
    SELECT MAX(product_abadoned)
    FROM product_in
);

#QUESTION 3

SELECT page_name, ROUND(100*(product_purchased/product_viewed), 2) AS view_to_purchase
FROM product_in
ORDER BY 2 DESC
LIMIT 1;

#QUESTION 4

SELECT 
  ROUND(100*AVG(product_addedtocart/product_viewed),2) AS avg_conversion_rate_view_to_cart_add
  FROM product_in;
  
  #QUESTION 5
  
  SELECT
  ROUND(100*AVG(product_purchased/product_addedtocart),2) AS avg_conversion_rate_cart_add_to_purchase
FROM product_in;