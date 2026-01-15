-- 1st requirement ---

-- rewrite the phone number to 000-0000, WHERE phone IS NULL AND email IS NOT NULL ---
select *,coalesce(phone, '000-0000') as phone_mod from prac_cx
where phone is null and email is not null 
                                       or 
  update prac_cx
  set phone  = '000-0000'
  where phone is null 

-- 2nd requirement --

-- change null mail id to no_mail@no_mail.com---
select *,coalesce(email,'no_mail@no_mail.com') as email_mod  from prac_cx where email is null AND phone IS NOT NULL

or
 update prac_cx
  set email = 'no_mail@no_mail.com'
  where email is null 

-- 4th requirement ---

-- check for duplicate customer_id ---

select *,count(customer_id) as count_customerid from prac_cx
group by customer_id 
having count(customer_id) > 1


-- 5th & 6th requirements ---

-- fix inconsistent date in the table and fill up clean date ---

-- MySQL handles dates differently than PostgreSQL, so we need to use STR_TO_DATE

UPDATE prac_ord

SET clean_order_date =

CASE

    WHEN order_date REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(order_date, '%Y/%m/%d')

    WHEN order_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(order_date, '%Y-%m-%d')

    WHEN order_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN STR_TO_DATE(order_date, '%d-%m-%Y')

    WHEN order_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN STR_TO_DATE(order_date, '%d/%m/%Y')

    ELSE NULL

END;

-- 7th requirement ---

-- our insights ---

-- give top 3 and bottom 3 product sold with store location ---

select p1.store_location,row_number() over (order by count(p1.order_id)) as  bottom_cnt, 
row_number() over (order by count(p1.order_id) desc) as top_cnt,count(p1.order_id) as cnt_orderid
from prac_ord p1 join prac_cx p2 on p1.customer_id = p2.customer_id
group by p1.store_location

-- 8th requirement ---

-- A - Top 3 best-selling products by quantity sold ---

-- B - Bottom 2 products by overall sales value ---


with cte as (
select p2.product_id,sum(p2.quantity) as quantity_sold ,max(p1.price) as price_of_product,p1.price * sum(p2.quantity) as sales_value,
row_number() over (order by sum(p2.quantity) desc ) as row_quantity,
row_number() over (order by p1.price * sum(p2.quantity) asc ) as row_sale
from prac_pro p1 join prac_ord_items p2 on p1.product_id = p2.product_id
group by p2.product_id)

select * from cte 
where row_quantity <=3 or  row_sale <=2


-- 9th requirement ---

-- return rate followup ---
SELECT ROUND(

(SELECT COUNT(order_item_id) FROM prac_returns) /

(SELECT COUNT(order_item_id) FROM prac_ord_items) * 100, 3

) AS return_rate;

-- 10th requirement ---

-- product returned + cx name + location + product_name ---


SELECT

a.order_id,

c.name AS customer_name,

b.store_location,

d.name AS product_name,

r.reason

FROM prac_returns r

JOIN prac_ord_items a ON a.order_item_id = r.order_item_id

JOIN prac_ord b ON a.order_id = b.order_id

JOIN prac_cx c ON b.customer_id = c.customer_id

JOIN prac_pro d ON d.product_id = a.product_id;


-- 11th requirement ---

-- revenue by store_location + return count by store location--
 
WITH t1 AS (
    SELECT
    a.*,
    b.product_id AS pid,
    b.quantity,
    c.*
    FROM prac_ord a
    JOIN prac_ord_items b ON a.order_id = b.order_id
    JOIN prac_pro c ON b.product_id = c.product_id
),

t2 AS (

    SELECT
    order_id,
    customer_id,
    store_location,
    pid AS product_id,
    name,
    quantity,
    price,
    quantity * price AS total_rev
    FROM t1
)

SELECT
store_location,
SUM(total_rev) AS total_rev,
ROW_NUMBER() OVER(ORDER BY SUM(total_rev) DESC) AS rank_per_store
FROM t2
GROUP BY store_location;

-- return count by store location ---

WITH t1 AS (
    SELECT
    a.*,
    b.*,
    c.store_location
    FROM prac_ord_items a
    JOIN prac_returns b ON a.order_item_id = b.order_item_id
    JOIN prac_ord c ON c.order_id = a.order_id
)
SELECT
store_location,
COUNT(store_location) AS no_of_pro_ret,
SUM(quantity) AS sum_qnt
FROM t1
GROUP BY store_location;

-- 12th Requirements ---

-- Monthly reveneue trend ---

SELECT
MONTH(clean_order_date) AS month_number,
store_location,
COUNT(order_id) AS total_orders,
ROW_NUMBER() OVER(PARTITION BY MONTH(clean_order_date)) AS month_rn
FROM prac_ord
GROUP BY MONTH(clean_order_date), store_location
ORDER BY month_number;





