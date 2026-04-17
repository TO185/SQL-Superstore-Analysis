-- =====================================================
-- DATABASE: superstore_analysis
-- PROJECT: Superstore Sales Analysis
-- TOTAL QUERIES: 20 (Basic to Advanced)
-- =====================================================

-- Temporary table for raw data
CREATE TABLE temp_superstore (
    row_id INT,
    order_id VARCHAR(50),
    order_date VARCHAR(20),
    ship_date VARCHAR(20),
    ship_mode VARCHAR(50),
    customer_id VARCHAR(50),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    region VARCHAR(50),
    product_id VARCHAR(50),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(255),
    sales DECIMAL(10,4),
    quantity INT,
    discount DECIMAL(5,4),
    profit DECIMAL(10,4)
);

-- ========================================
-- 1. CUSTOMERS TABLE (Duplicate Free)
-- ========================================
CREATE TABLE customers AS
SELECT 
    customer_id,
    MAX(customer_name) as customer_name,
    MAX(segment) as segment,
    MAX(country) as country,
    MAX(city) as city,
    MAX(state) as state,
    MAX(postal_code) as postal_code,
    MAX(region) as region
FROM temp_superstore
WHERE customer_id IS NOT NULL
GROUP BY customer_id;

-- Add primary key
ALTER TABLE customers ADD PRIMARY KEY (customer_id);

-- ========================================
-- 2. PRODUCTS TABLE
-- ========================================
CREATE TABLE products AS
SELECT 
    product_id,
    MAX(product_name) as product_name,
    MAX(category) as category,
    MAX(sub_category) as sub_category
FROM temp_superstore
WHERE product_id IS NOT NULL
GROUP BY product_id;

-- Add primary key
ALTER TABLE products ADD PRIMARY KEY (product_id);

-- ========================================
-- 3. ORDERS TABLE
-- ========================================
CREATE TABLE orders AS
SELECT 
    row_id,
    order_id,
    STR_TO_DATE(order_date, '%m/%d/%Y') as order_date,
    STR_TO_DATE(ship_date, '%m/%d/%Y') as ship_date,
    ship_mode,
    customer_id,
    product_id,
    sales,
    quantity,
    discount,
    profit
FROM temp_superstore;

-- Add primary key
ALTER TABLE orders ADD PRIMARY KEY (row_id);

-- Add foreign keys
ALTER TABLE orders 
ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

ALTER TABLE orders 
ADD FOREIGN KEY (product_id) REFERENCES products(product_id);


USE superstore_analysis;

-- =====================================================
-- SECTION 1: BASIC PERFORMANCE METRICS (Query 1-5)
-- =====================================================

-- ------------------------------------------------------------------
-- QUERY 1: Total Sales, Profit & Quantity by Year
-- ------------------------------------------------------------------
SELECT 
    YEAR(order_date) AS year, 
    COUNT(*) AS orders, 
    ROUND(SUM(sales), 2) AS sales, 
    ROUND(SUM(profit), 2) AS profit, 
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS margin
FROM orders 
WHERE order_date IS NOT NULL
GROUP BY year 
ORDER BY year;

-- ------------------------------------------------------------------
-- QUERY 2: Category-wise Performance
-- ------------------------------------------------------------------
SELECT 
    p.category, 
    ROUND(SUM(o.sales), 2) AS sales, 
    ROUND(SUM(o.profit), 2) AS profit,
    ROUND(SUM(o.profit) / SUM(o.sales) * 100, 2) AS margin
FROM orders o 
JOIN products p ON o.product_id = p.product_id 
GROUP BY p.category 
ORDER BY profit DESC;

-- ------------------------------------------------------------------
-- QUERY 3: Top 10 Customers by Profit
-- ------------------------------------------------------------------
SELECT 
    c.customer_name, 
    c.segment, 
    ROUND(SUM(o.sales), 2) AS sales, 
    ROUND(SUM(o.profit), 2) AS profit
FROM orders o 
JOIN customers c ON o.customer_id = c.customer_id 
GROUP BY c.customer_id 
ORDER BY profit DESC 
LIMIT 10;

-- ------------------------------------------------------------------
-- QUERY 4: Monthly Sales & Profit Trend
-- ------------------------------------------------------------------
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month, 
    ROUND(SUM(sales), 2) AS sales, 
    ROUND(SUM(profit), 2) AS profit
FROM orders 
WHERE order_date IS NOT NULL 
GROUP BY month 
ORDER BY month;

-- ------------------------------------------------------------------
-- QUERY 5: Discount Impact on Profit
-- ------------------------------------------------------------------
SELECT 
    CASE 
        WHEN discount = 0 THEN 'No Discount' 
        WHEN discount <= 0.1 THEN '0-10%' 
        WHEN discount <= 0.2 THEN '10-20%' 
        ELSE '20%+' 
    END AS discount_range,
    COUNT(*) AS orders, 
    ROUND(AVG(profit), 2) AS avg_profit 
FROM orders 
GROUP BY discount_range 
ORDER BY avg_profit DESC;


-- =====================================================
-- SECTION 2: PRODUCT ANALYSIS (Query 6-7)
-- =====================================================

-- ------------------------------------------------------------------
-- QUERY 6: Top 10 Products by Sales
-- ------------------------------------------------------------------
SELECT 
    p.product_name, 
    p.category, 
    ROUND(SUM(o.sales), 2) AS sales
FROM orders o 
JOIN products p ON o.product_id = p.product_id 
GROUP BY p.product_id 
ORDER BY sales DESC 
LIMIT 10;

-- ------------------------------------------------------------------
-- QUERY 7: Bottom 10 Products (Loss Making)
-- ------------------------------------------------------------------
SELECT 
    p.product_name, 
    p.category, 
    ROUND(SUM(o.sales), 2) AS sales, 
    ROUND(SUM(o.profit), 2) AS loss
FROM orders o 
JOIN products p ON o.product_id = p.product_id 
GROUP BY p.product_id 
HAVING loss < 0 
ORDER BY loss ASC 
LIMIT 10;


-- =====================================================
-- SECTION 3: GEOGRAPHIC & SEGMENT ANALYSIS (Query 8-10)
-- =====================================================

-- ------------------------------------------------------------------
-- QUERY 8: Top 10 States by Profit
-- ------------------------------------------------------------------
SELECT 
    c.state, 
    c.region, 
    ROUND(SUM(o.sales), 2) AS sales, 
    ROUND(SUM(o.profit), 2) AS profit
FROM orders o 
JOIN customers c ON o.customer_id = c.customer_id 
GROUP BY c.state, c.region
ORDER BY profit DESC 
LIMIT 10;

-- ------------------------------------------------------------------
-- QUERY 9: Segment-wise Performance
-- ------------------------------------------------------------------
SELECT 
    c.segment, 
    COUNT(DISTINCT c.customer_id) AS customers, 
    ROUND(SUM(o.sales), 2) AS sales, 
    ROUND(SUM(o.profit), 2) AS profit
FROM orders o 
JOIN customers c ON o.customer_id = c.customer_id 
GROUP BY c.segment 
ORDER BY profit DESC;

-- ------------------------------------------------------------------
-- QUERY 10: Shipping Mode Performance
-- ------------------------------------------------------------------
SELECT 
    ship_mode, 
    COUNT(*) AS orders, 
    ROUND(SUM(sales), 2) AS sales, 
    ROUND(SUM(profit), 2) AS profit
FROM orders 
GROUP BY ship_mode 
ORDER BY profit DESC;


-- =====================================================
-- SECTION 4: ADVANCED WINDOW FUNCTIONS (Query 11-14)
-- =====================================================

-- ------------------------------------------------------------------
-- QUERY 11: Running Total of Sales
-- ------------------------------------------------------------------
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month, 
    ROUND(SUM(sales), 2) AS monthly_sales,
    ROUND(SUM(SUM(sales)) OVER (ORDER BY MIN(order_date)), 2) AS running_total
FROM orders 
WHERE order_date IS NOT NULL 
GROUP BY month 
ORDER BY month;

-- ------------------------------------------------------------------
-- QUERY 12: Month-over-Month Growth
-- ------------------------------------------------------------------
WITH monthly AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS month, 
        ROUND(SUM(sales), 2) AS sales,
        LAG(ROUND(SUM(sales), 2)) OVER (ORDER BY MIN(order_date)) AS prev_month
    FROM orders 
    GROUP BY month
)
SELECT 
    month, 
    sales, 
    prev_month, 
    ROUND((sales - prev_month) / prev_month * 100, 2) AS growth 
FROM monthly;

-- ------------------------------------------------------------------
-- QUERY 13: Top 2 Products per Category (Ranking)
-- ------------------------------------------------------------------
WITH ranked AS (
    SELECT 
        p.category, 
        p.product_name, 
        ROUND(SUM(o.sales), 2) AS sales,
        ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY SUM(o.sales) DESC) AS rn
    FROM orders o 
    JOIN products p ON o.product_id = p.product_id 
    GROUP BY p.category, p.product_name
)
SELECT * FROM ranked WHERE rn <= 2;

-- ------------------------------------------------------------------
-- QUERY 14: Customer Lifetime Value (Top 20)
-- ------------------------------------------------------------------
SELECT 
    c.customer_name, 
    c.segment, 
    COUNT(*) AS orders, 
    ROUND(SUM(o.sales), 2) AS lifetime_value,
    DENSE_RANK() OVER (ORDER BY SUM(o.sales) DESC) AS rank_by_sales
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id 
GROUP BY c.customer_id 
ORDER BY lifetime_value DESC 
LIMIT 20;


-- =====================================================
-- SECTION 5: TIME-BASED ANALYSIS (Query 15, 18)
-- =====================================================

-- ------------------------------------------------------------------
-- QUERY 15: Quarterly Performance
-- ------------------------------------------------------------------
SELECT 
    YEAR(order_date) AS year, 
    CONCAT('Q', QUARTER(order_date)) AS quarter, 
    ROUND(SUM(sales), 2) AS sales, 
    ROUND(SUM(profit), 2) AS profit
FROM orders 
GROUP BY year, quarter 
ORDER BY year, quarter;

-- ------------------------------------------------------------------
-- QUERY 18: Best Month Each Year
-- ------------------------------------------------------------------
WITH best AS (
    SELECT 
        YEAR(order_date) AS year, 
        MONTHNAME(order_date) AS month, 
        ROUND(SUM(profit), 2) AS profit,
        ROW_NUMBER() OVER (PARTITION BY YEAR(order_date) ORDER BY SUM(profit) DESC) AS rn
    FROM orders 
    GROUP BY year, month
)
SELECT year, month, profit FROM best WHERE rn = 1;


-- =====================================================
-- SECTION 6: DISCOUNT & PROFIT CORRELATION (Query 16-17)
-- =====================================================

-- ------------------------------------------------------------------
-- QUERY 16: Profit vs Discount Correlation
-- ------------------------------------------------------------------
SELECT 
    ROUND(discount, 1) AS discount_level, 
    COUNT(*) AS orders, 
    ROUND(AVG(profit), 2) AS avg_profit
FROM orders 
GROUP BY discount_level 
ORDER BY discount_level;

-- ------------------------------------------------------------------
-- QUERY 17: Loss Making Sub-Categories
-- ------------------------------------------------------------------
SELECT 
    p.category, 
    p.sub_category, 
    ROUND(SUM(o.sales), 2) AS sales, 
    ROUND(SUM(o.profit), 2) AS profit
FROM orders o 
JOIN products p ON o.product_id = p.product_id 
GROUP BY p.category, p.sub_category 
HAVING profit < 0 
ORDER BY profit ASC;


-- =====================================================
-- SECTION 7: CUSTOMER BEHAVIOR (Query 19-20)
-- =====================================================

-- ------------------------------------------------------------------
-- QUERY 19: Customer Retention (Repeat Buyers)
-- ------------------------------------------------------------------
SELECT 
    order_count, 
    COUNT(*) AS customers, 
    ROUND(AVG(total_spent), 2) AS avg_spent 
FROM (
    SELECT 
        c.customer_id, 
        COUNT(DISTINCT o.order_id) AS order_count, 
        SUM(o.sales) AS total_spent
    FROM customers c 
    JOIN orders o ON c.customer_id = o.customer_id 
    GROUP BY c.customer_id
) t 
GROUP BY order_count 
ORDER BY order_count;

-- ------------------------------------------------------------------
-- QUERY 20: Regional Performance Summary
-- ------------------------------------------------------------------
SELECT 
    c.region, 
    COUNT(DISTINCT c.customer_id) AS customers, 
    ROUND(SUM(o.sales), 2) AS sales, 
    ROUND(SUM(o.profit), 2) AS profit
FROM orders o 
JOIN customers c ON o.customer_id = c.customer_id 
GROUP BY c.region 
ORDER BY profit DESC;

