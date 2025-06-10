-- Revenue Trends and Product-Level Performance
-- 1. Average Amount by Country
Select c.country, round(avg(s.amount),2) as "average amount"
from customers c
join payments s
on c.customerNumber = s.customerNumber
group by c.country
-- 2. Sale Amount by Product Line
Select p.productLine, round(Sum(o.priceEach*quantityOrdered),2) as "Sale Amount"
from orderdetails o
join products p
on o.productCode = p.productCode
group by p.productLine
-- 3. top 10 best selling product by quantity
Select p.productName as "product", sum(o.quantityOrdered) as "quantity"
from orderdetails o
join products p
on o.productCode = p.productCode
group by p.productName
order by quantity desc
limit 10
-- 4. Average Number of Orders per Customer
SELECT 
    COUNT(o.orderNumber) * 1.0 / COUNT(DISTINCT c.customerNumber) AS avg_orders_per_customer
FROM orders o
JOIN customers c 
ON o.customerNumber = c.customerNumber;

-- Operation
-- 5. On time shipment percentage
WITH ontime_order AS (
    SELECT 
        orderNumber
    FROM orders
    WHERE shippedDate <= requiredDate
),
cte AS (
    SELECT 
        COUNT(DISTINCT o.orderNumber) AS total_order, 
        COUNT(lo.orderNumber) AS on_time_order
    FROM orders o
    LEFT JOIN ontime_order lo
        ON o.orderNumber = lo.orderNumber
    WHERE o.status = 'Shipped'
)
SELECT 
    total_order,
    on_time_order,
    ROUND(1.0 * on_time_order / total_order * 100, 2) AS on_time_rate
FROM cte;
--c2
SELECT 
    COUNT(DISTINCT orderNumber) AS total_order,
    COUNT(DISTINCT CASE WHEN shippedDate <= requiredDate THEN orderNumber END) AS on_time_order,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN shippedDate <= requiredDate THEN orderNumber END)
        / COUNT(DISTINCT orderNumber),
        2
    ) AS on_time_rate
FROM orders
WHERE status = 'Shipped';
-- 6. Late Shipments Identify
SELECT *
FROM orders 
WHERE shippedDate > requiredDate
-- Customer Behaviour
-- 8. based on their total purchase amount into "High Value," "Medium Value," and "Low Value" categories.
with cte as (
    select customerNumber, round(sum(amount),2) as "total_spent"
    from payments
    group by customerNumber),
customer_segments AS (
    SELECT 
        customerNumber, total_spent,
        CASE 
            WHEN total_spent >= 100000 THEN 'High Value'
            WHEN total_spent >= 50000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS segment
    FROM cte
)
Select c.customerName, cs.segment, cs.total_spent
from customers c
left join customer_segments cs
on c.customerNumber = cs.customerNumber
order by c.customerName
-- cách 2
WITH customer_payment AS (
    SELECT customerNumber, amount
    FROM payments
)
SELECT DISTINCT
    c.customerName,
    ROUND(SUM(cp.amount) OVER (PARTITION BY c.customerNumber), 2) AS total_spent,
    CASE 
        WHEN SUM(cp.amount) OVER (PARTITION BY c.customerNumber) >= 100000 THEN 'High Value'
        WHEN SUM(cp.amount) OVER (PARTITION BY c.customerNumber) >= 50000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS segment
FROM customers c
LEFT JOIN customer_payment cp ON c.customerNumber = cp.customerNumber
ORDER BY c.customerName;
-- 9. Frequently Co-Purchased Products
-- Dùng self join lấy các cặp sản phẩm được mua cùng nhau
select
    case
    when od1.productCode < od2.productCode then od1.productCode
    else od2.productCode end as productid_1,
    case
    when od1.productCode > od2.productCode then od1.productCode
    else od2.productCode end as productid_2,    
    count(*) as "time"
from orderdetails od1
join orderdetails od2
on od1.orderNumber = od2.orderNumber
and od1.productCode < od2.productCode
group by productid_1, productid_2
order by time desc
select *
from orderdetails
order by productCode desc
