-- **REVENUE TRENDS AND PRODUCT-LEVEL PERFORMANCE**

-- **1. AVERAGE AMOUNT BY COUNTRY**
SELECT c.country, ROUND(AVG(s.amount), 2) AS "average amount"
FROM customers c
JOIN payments s ON c.customerNumber = s.customerNumber
GROUP BY c.country;

-- **2. SALE AMOUNT BY PRODUCT LINE**
SELECT p.productLine, ROUND(SUM(o.priceEach * quantityOrdered), 2) AS "Sale Amount"
FROM orderdetails o
JOIN products p ON o.productCode = p.productCode
GROUP BY p.productLine;

-- **3. TOP 10 BEST SELLING PRODUCT BY QUANTITY**
SELECT p.productName AS "product", SUM(o.quantityOrdered) AS "quantity"
FROM orderdetails o
JOIN products p ON o.productCode = p.productCode
GROUP BY p.productName
ORDER BY quantity DESC
LIMIT 10;

-- **4. AVERAGE NUMBER OF ORDERS PER CUSTOMER**
SELECT 
    COUNT(o.orderNumber) * 1.0 / COUNT(DISTINCT c.customerNumber) AS avg_orders_per_customer
FROM orders o
JOIN customers c ON o.customerNumber = c.customerNumber;

-- **OPERATION**

-- **5. ON TIME SHIPMENT PERCENTAGE**
WITH ontime_order AS (
    SELECT orderNumber
    FROM orders
    WHERE shippedDate <= requiredDate
),
cte AS (
    SELECT 
        COUNT(DISTINCT o.orderNumber) AS total_order, 
        COUNT(lo.orderNumber) AS on_time_order
    FROM orders o
    LEFT JOIN ontime_order lo ON o.orderNumber = lo.orderNumber
    WHERE o.status = 'Shipped'
)
SELECT 
    total_order,
    on_time_order,
    ROUND(1.0 * on_time_order / total_order * 100, 2) AS on_time_rate
FROM cte;

-- **CÁCH 2**
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

-- **6. LATE SHIPMENTS IDENTIFY**
SELECT *
FROM orders 
WHERE shippedDate > requiredDate;

-- **CUSTOMER BEHAVIOUR**

-- **8. CUSTOMER SEGMENTATION BY TOTAL PURCHASE AMOUNT**
WITH cte AS (
    SELECT customerNumber, ROUND(SUM(amount), 2) AS total_spent
    FROM payments
    GROUP BY customerNumber
),
customer_segments AS (
    SELECT 
        customerNumber, 
        total_spent,
        CASE 
            WHEN total_spent >= 100000 THEN 'High Value'
            WHEN total_spent >= 50000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS segment
    FROM cte
)
SELECT c.customerName, cs.segment, cs.total_spent
FROM customers c
LEFT JOIN customer_segments cs ON c.customerNumber = cs.customerNumber
ORDER BY c.customerName;

-- **CÁCH 2**
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

-- **9. FREQUENTLY CO-PURCHASED PRODUCTS**
SELECT
    CASE
        WHEN od1.productCode < od2.productCode THEN od1.productCode
        ELSE od2.productCode
    END AS productid_1,
    CASE
        WHEN od1.productCode > od2.productCode THEN od1.productCode
        ELSE od2.productCode
    END AS productid_2,    
    COUNT(*) AS "time"
FROM orderdetails od1
JOIN orderdetails od2 ON od1.orderNumber = od2.orderNumber
    AND od1.productCode < od2.productCode
GROUP BY productid_1, productid_2
ORDER BY time DESC;

SELECT *
FROM orderdetails
ORDER BY productCode DESC;
