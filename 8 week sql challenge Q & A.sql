-- Q1. How many customers has Foodie-Fi ever had?
select count(distinct customer_id) total_customers from  
subscriptions ;

-- Q2. What is the monthly distribution of 
-- trial plan start_date values for our dataset — use the start of the month as the group by value?
select date_format(s.start_date, "%M %Y") as monthly_d,
count(p.plan_id) from subscriptions as s join plans as p
on s.plan_id = p.plan_id 
where p.plan_name = 'trial'
group by 1
order by 2 desc;

-- What plan start_date values occur after the year 2020 for our dataset? 
-- Show the breakdown by count of events for each plan_name
select p.plan_name, min(s.start_date), count(s.customer_id) as count_of_events
from subscriptions as s join plans as p 
on s.plan_id = p.plan_id 
where year(s.start_date)> '2020'
group by 1;

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
with churned_customers as 
(
select s.plan_id, count(distinct s.customer_id) as total_count1 from subscriptions as s join plans as p 
on s.plan_id = p.plan_id
where p.plan_name = 'churn'
group by 1
) ,
total_customers as 
(select count(distinct customer_id) as total_count2 from subscriptions 
)
select total_customers.total_count2 , round((churned_customers.total_count1)/(total_customers.total_count2)*100,1) as percentage_cust
from churned_customers , total_customers
 ;

-- How many customers have churned straight after(lead /lag usage) their initial free trial 
-- what percentage is this rounded to the nearest whole number?
with churned_cust as
(
select *, 
lag(plan_id, 1) over (partition by customer_id order by plan_id ) as previous_plan
from subscriptions
)
select count(previous_plan) as churn_count,
round((count(*)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions))*100,0) as percentage_churn
from churned_cust where plan_id = 4 and previous_plan =0 ;


-- start_date in (select start_date from subscriptions where plan_id = 4 )> 
-- start_date in (select start_date from subscriptions where plan_id = 0 ) ;

-- What is the number and percentage of customer plans after their initial free trial?
-- Question is asking for number and percentage of customers who converted to becoming paid customer after the trial.

-- Steps:
-- Find out customer's next plan which is located in the next row using LEAD() function
-- Find the total number and percentage for each plan using COUNT
-- Filter for plan_id = 0 as every customer has to start from the trial plan at 0
with next_plan_cte as(
	select customer_id, plan_id,
		lead(plan_id, 1) over(
			partition by customer_id
			order by plan_id) as next_plan
	from subscriptions)
select next_plan, count(*) as conversions,
	round(count(*) * 100 / (
		select count(distinct(customer_id)) 
        from subscriptions)) as conversion_percent
from next_plan_cte
where next_plan is not null and plan_id = 0
group by next_plan
order by next_plan;

-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
use foodie_fi ;
with cust_count as
(
select plan_id, count(customer_id)
 from subscriptions
 where start_date <= '2020-12-31'
 group by plan_id
 ) 
 select * 
 from cust_count;
 



use dannys_diner;

-- Danny's Dinner 
-- 1. What is the total amount each customer spent at the restaurant?
select customer_id , sum(price) as total_amount from sales as s join menu as m
on s.product_id = m.product_id 
group by 1
order by total_amount desc;
-- 2. How many days has each customer visited the restaurant?
select customer_id, count(order_date) from sales 
group by customer_id;
-- 3. What was the first item from the menu purchased by each customer?
with rank_menu as
(
select s.customer_id,
m.product_name,
s.order_date,
rank() over(partition by customer_id order by order_date asc) as rnk
from sales as s join menu as m on s.product_id = m.product_id
) select customer_id,
product_name,
order_date from rank_menu where rnk =1
group by 1,3,2 ;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name, count(s.product_id) as total_count
from sales as s join menu as m
on s.product_id = m.product_id
group by 1
order by total_count desc ;

-- 5. Which item was the most popular for each customer?
with popular_menu as
(
select s.customer_id, m.product_name, count(s.product_id) as total_count,
dense_rank() over (partition by s.customer_id order by count(s.product_id) desc) as rn
from sales as s join menu as m
on s.product_id = m.product_id
group by 1,2
) select * from popular_menu 
where rn =1 ;

-- 6. Which item was purchased first by the customer after they became a member?
select s.customer_id, m.product_name, mm.join_date, s.order_date from sales as s join menu as m 
on s.product_id = m.product_id join members as mm 
on s.customer_id = mm.customer_id
where s.order_date > mm.join_date;

-- 7. Which item was purchased just before the customer became a member?
select s.customer_id, m.product_name, mm.join_date, s.order_date from sales as s join menu as m 
on s.product_id = m.product_id join members as mm 
on s.customer_id = mm.customer_id
where s.order_date < mm.join_date;
-- 8. What is the total items and amount spent for each member before they became a member?
select s.customer_id, count(s.product_id) , sum(m.price) 
from sales as s join menu as m 
on s.product_id = m.product_id join members as mm 
on s.customer_id = mm.customer_id
where s.order_date < mm.join_date
group by 1;
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
-- how many points would each customer have?
select customer_id,
sum(case when product_name= 'sushi' then price * 20
else price * 10
end)as total_points
from sales as s join menu as m 
on s.product_id = m.product_id
group by customer_id;

-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select s.customer_id, m.product_name ,
datediff(s.order_date - mm.join_date) as dt
from sales as s join menu as m 
on s.product_id = m.product_id
join members as mm 
on s.customer_id = mm.customer_id
where s.order_date > mm.join_date ;

use foodie_fi ;
 
select extract(month from s.start_date) as monthly ,
count(s.customer_id) from plans as p join 
subscriptions as s on 
p.plan_id = s.plan_id
where p.plan_name = 'trial'
group by 1
order by monthly desc ;

use pizza_runner;
-- How many pizzas were ordered?

select count(pizza_id) from customer_orders;
-- How many unique customer orders were made?
select count(distinct customer_id) from customer_orders;

-- How many successful orders were delivered by each runner?
select ro.runner_id, count(distinct co.order_id) from customer_orders as co 
join runner_orders as ro on co.order_id = ro.order_id
where pickup_time not like 'null'
group by runner_id;
-- How many of each type of pizza was delivered?
select co.pizza_id, count(co.pizza_id) from customer_orders as co 
join runner_orders as ro on co.order_id = ro.order_id
where pickup_time not like 'null' 
group by co.pizza_id;

-- How many Vegetarian and Meatlovers were ordered by each customer?
select customer_id, pizza_name, count(distinct order_id) from customer_orders as co
join pizza_names as pn on co.pizza_id = pn.pizza_id
group by customer_id, pizza_name ;

-- What was the maximum number of pizzas delivered in a single order?
select co.order_id, count(co.pizza_id) as pizza_delivered from customer_orders as co 
join runner_orders as ro on co.order_id = ro.order_id 
where pickup_time not like 'null'
group by co.order_id
order by count(co.pizza_id) desc ;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
select co.customer_id, count(co.pizza_id) as total_pizza_delivered from customer_orders as co 
join runner_orders as ro on co.order_id = ro.order_id 
join pizza_recipes as pr on co.pizza_id = pr.pizza_id  
where (pickup_time not like 'null') and ((co.exclusions not like 'null' and co.exclusions is not null )
or (co.extras not like 'null' and co.extras not like 'NaN' and co.extras is not null ))
group by co.customer_id;


SELECT 
  c.customer_id, 
  COUNT(CASE WHEN (c.exclusions IS NOT NULL) or (c.exclusions not like 'null') OR (c.extras IS NOT NULL)
  	THEN 1 END) AS changed_orders,
  COUNT(CASE WHEN (c.exclusions IS NULL) or (c.exclusions not like 'null') AND (c.extras IS NULL)
  	THEN 1 END) AS unchanged_orders
FROM pizza_runner.customer_orders c
JOIN pizza_runner.runner_orders r
  ON c.order_id = r.order_id
WHERE pickup_time not like 'null'
GROUP BY c.customer_id
ORDER BY c.customer_id;

SELECT 
  c.customer_id, 
  COUNT(CASE WHEN c.exclusions IS NOT NULL OR c.extras IS NOT NULL 
  	THEN 1 END) AS changed_orders,
  COUNT(CASE WHEN c.exclusions IS NULL AND c.extras IS NULL
  	THEN 1 END) AS unchanged_orders
FROM pizza_runner.customer_orders c
JOIN pizza_runner.runner_orders r
  ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.customer_id
ORDER BY c.customer_id;

-- How many pizzas were delivered that had both exclusions and extras?

select count(pizza_id) from customer_orders
 where exclusions regexp ('[0-9]') and extras regexp ('[0-9]')
 group by customer_id;
 
 -- What was the total volume of pizzas ordered for each hour of the day?
 select count(pizza_id), hour(order_time) as hr
 from customer_orders 
 group by 2
 order by hr;
 
 -- What was the volume of orders for each day of the week?
 select weekday(order_time) as each_day ,count(pizza_id) 
 from customer_orders 
 group by 1
 order by each_day ;
 
 -- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01) ( Review )
 SELECT  week(registration_date) AS Week, count(runner_id)  
FROM runners
WHERE '2021-01-01' <= registration_date
  AND registration_date < '2021-01-01'
GROUP BY week(registration_date)
ORDER BY week(registration_date);
-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select ro.runner_id,
avg(timestampdiff(MINUTE, order_time, pickup_time)) as avg_time 
from customer_orders as co join 
runner_orders as ro on co.order_id = ro.order_id
where ro.pickup_time <> 'null'
group by ro.runner_id ;

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
select co.order_id, count(co.pizza_id) , 
timestampdiff(MINUTE, co.order_time, ro.pickup_time) as time_taken
from customer_orders as co join runner_orders as ro on 
co.order_id = ro.order_id
group by co.order_id , time_taken;

-- What was the average distance travelled for each customer?
select co.customer_id, 
round(avg(ro.distance), 2) as avg_distance
from runner_orders as ro join customer_orders as co on
ro.order_id = co.order_id
where ro.distance <> 'null'
group by co.customer_id ; 

-- What was the difference between the longest and shortest delivery times for all orders?
select 
(max(duration) - min(duration)) as time_diff
from runner_orders
where duration <> 'null' ;

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
select runner_id,
round(avg((distance /duration)*60), 0) as avg_speed
from runner_orders
where distance <> 'null'
group by runner_id ;

-- What is the successful delivery percentage for each runner?
with cte1 as 
(
select runner_id, count(order_id) as total_cnt1
from runner_orders 
where duration <> 'null'
group by runner_id
), cte2 as
(select runner_id, count(order_id) as total_cnt2
from runner_orders group by runner_id) 
select cte2.runner_id, round((cte1.total_cnt1/ cte2.total_cnt2 *100),1) as percentage_cust
from cte1, cte2
;


