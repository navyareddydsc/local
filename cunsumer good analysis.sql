USE `gdb023`;
select * from dim_customer;
/*  Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
business in the  APAC  region.*/

select market
 from dim_customer 
 where region = 'APAC';

/* 2.  What is the percentage of unique product increase in 2021 vs. 2020? The 
final output contains these fields, 
unique_products_2020 
unique_products_2021 
percentage_chg */

with x as
(select count(distinct product_code) as unique_products_2020 
from fact_sales_monthly where fiscal_year = 2020),
y as
(select count(distinct product_code) as unique_products_2021
from fact_sales_monthly where fiscal_year = 2021)
select
x.unique_products_2020,
y.unique_products_2021,
round((y.unique_products_2021-x.unique_products_2020/x.unique_products_2020)*100,2)
as percentage_chg from x,y;



/*3.  Provide a report with all the unique product counts for each  segment  and 
sort them in descending order of product counts. The final output contains 
2 fields, 
segment 
product_count */

SELECT segment, COUNT(DISTINCT product) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

/*4.  Follow-up: Which segment had the most increase in unique products in 
2021 vs 2020? The final output contains these fields, 
segment 
product_count_2020 
product_count_2021 
difference*/

WITH ProductCounts AS (
    SELECT 
        p.segment,
        SUM(CASE WHEN d.fiscal_year = 2020 THEN 1 ELSE 0 END) AS product_count_2020,
        SUM(CASE WHEN d.fiscal_year = 2021 THEN 1 ELSE 0 END) AS product_count_2021
    FROM 
        dim_product p
    JOIN 
        fact_sales_monthly d ON p.product_code = d.product_code GROUP BY p.segment
)SELECT segment,
    product_count_2020,
    product_count_2021,
    (product_count_2021 - product_count_2020) AS difference
FROM 
    ProductCounts ORDER BY difference DESC;
    
    
   /* 5.  Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, 
product_code 
product 
manufacturing_cost 
codebasics.io */

select m.product_code, p.product, m.manufacturing_cost from fact_manufacturing_cost m 
join dim_product p using (product_code)
where m.manufacturing_cost = (select max(manufacturing_cost) 
from fact_manufacturing_cost)
or m.manufacturing_cost = (select min(manufacturing_cost) 
from fact_manufacturing_cost) 
order by m.manufacturing_cost desc;

/*6.  Generate a report which contains the top 5 customers who received an 
average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
Indian  market. The final output contains these fields, 
customer_code 
customer 
average_discount_percentage */

select i.customer_code, c.customer, round(avg(i.pre_invoice_discount_pct)*100,2)as
avg_dis_pct from fact_pre_invoice_deductions i join dim_customer c using (customer_code)
where fiscal_year = 2021 and c.market = "india" group by i.customer_code, c.customer
order by avg_dis_pct desc
limit 5;

/*7.  Get the complete report of the Gross sales amount for the customer  “Atliq 
Exclusive”  for each month  .  This analysis helps to  get an idea of low and 
high-performing months and take strategic decisions. 
The final report contains these columns: 
Month 
fiscal_yearYear 
Gross sales Amount*/

select monthname(s.date)as month, s.fiscal_year,
round(sum(g.gross_price*sold_quantity),2) as gross_sales_amt 
from fact_sales_monthly s
join dim_customer c using(customer_code)
join fact_gross_price g using(product_code)
where customer="Atliq Exclusive"
group by monthname(s.date),s.fiscal_year
order by fiscal_year;


   /* 8.  In which quarter of 2020, got the maximum total_sold_quantity? The final 
output contains these fields sorted by the total_sold_quantity, 
Quarter 
total_sold_quantity */

SELECT 
case
when month(date) in (9,10,11) then "Q1"
when month(date) in (12,01,02) then "Q2"
when month(date) in (03,04,05) then "Q3"
else "Q4"
end as quarters,
sum(sold_quantity) as total_sold_qty
from fact_sales_monthly
where fiscal_year = 2020
group by quarters
order by total_sold_qty desc;


/*9.  Which channel helped to bring more gross sales in the fiscal year 2021 
and the percentage of contribution?  The final output  contains these fields, 
channel 
gross_sales_mln 
percentage*/

with x as (
    select c.channel, round(sum(g.gross_price*s.sold_quantity)/100000,2) as gross_sales_mln 
    from fact_sales_monthly s 
    join dim_customer c using(customer_code)
    join fact_gross_price g using (product_code)
    where s.fiscal_year = 2021
    group by c.channel) 
select channel, gross_sales_mln, round((gross_sales_mln/(select sum(gross_sales_mln) from x))*100,2) as pct 
from x 
order by gross_sales_mln desc;

    
   /* 10.  Get the Top 3 products in each division that have a high 
total_sold_quantity in the fiscal_year 2021? The final output contains these 
fields, 
division 
product_code 
codebasics.io 
product 
total_sold_quantity 
rank_order*/

with x as (
select p.division, s.product_code, p.product, sum(s.sold_quantity) as
total_sold_quantity, rank() over(partition by p.division order by sum(s.sold_quantity)desc)as 
'rank_order' from dim_product p
join fact_sales_monthly s on
p.product_code = s.product_code
where s.fiscal_year = 2021
group by p.division, s.product_code, p.product)
select * from x
where rank_order in(1,2,3) order by division, rank_order;





 







