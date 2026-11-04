-- ============================================================
-- E-Commerce Order and Inventory Management System
-- Database: ecom_cep
-- Purpose: Data verification and business analysis queries
-- Tables: customers, products, orders, order_items, payments
--
-- IMPORTANT:
-- 1. Run this script in MySQL Workbench after selecting the ecom_cep database.
-- 2. Each SELECT statement produces its own result grid.
-- 3. The schema has no order_items.unit_price column. Therefore, any
--    order value estimated from products.price uses the CURRENT product
--    price, not necessarily the price at the time the order was placed.
-- 4. payments has no payment_status column, so payment totals below mean
--    amounts recorded in the payments table, not confirmed successful revenue.
-- ============================================================

USE ecom_cep;


-- ------------------------------------------------------------
-- QUERY 01: Count records in all five tables
-- Purpose: Verify that data has been loaded.
-- ------------------------------------------------------------
SELECT 'customers' AS table_name, COUNT(*) AS total_records FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments;


-- ------------------------------------------------------------
-- QUERY 02: Total number of orders
-- Purpose: Count all orders in the system.
-- ------------------------------------------------------------
SELECT COUNT(*) AS total_orders
FROM orders;


-- ------------------------------------------------------------
-- QUERY 03: Number of orders by status
-- Purpose: See how orders are distributed by order_status.
-- ------------------------------------------------------------
SELECT order_status, COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- ------------------------------------------------------------
-- QUERY 04: Orders placed each month
-- Purpose: Analyze order volume over time.
-- ------------------------------------------------------------
SELECT DATE_FORMAT(order_date, '%Y-%m') AS order_month,
       COUNT(*) AS total_orders
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;


-- ------------------------------------------------------------
-- QUERY 05: Total customers by city
-- Purpose: Identify cities with the most registered customers.
-- ------------------------------------------------------------
SELECT city, COUNT(*) AS total_customers
FROM customers
WHERE city IS NOT NULL AND city <> ''
GROUP BY city
ORDER BY total_customers DESC;


-- ------------------------------------------------------------
-- QUERY 06: Top 10 customers by number of orders
-- Purpose: Find customers who place the most orders.
-- ------------------------------------------------------------
SELECT c.customer_id,
       c.name,
       c.email,
       COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name, c.email
ORDER BY total_orders DESC, c.customer_id
LIMIT 10;


-- ------------------------------------------------------------
-- QUERY 07: Customers who have never placed an order
-- Purpose: Find registered customers with no matching order.
-- ------------------------------------------------------------
SELECT c.customer_id, c.name, c.email, c.city
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;


-- ------------------------------------------------------------
-- QUERY 08: Top 10 products by quantity ordered
-- Purpose: Find the most frequently ordered products by units.
-- ------------------------------------------------------------
SELECT p.product_id,
       p.product_name,
       p.category,
       SUM(oi.quantity) AS units_ordered
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY units_ordered DESC, p.product_id
LIMIT 10;


-- ------------------------------------------------------------
-- QUERY 09: Quantity ordered by product category
-- Purpose: Compare demand across product categories.
-- ------------------------------------------------------------
SELECT p.category,
       SUM(oi.quantity) AS units_ordered
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY units_ordered DESC;


-- ------------------------------------------------------------
-- QUERY 10: Products that have never been ordered
-- Purpose: Identify products with no order_items records.
-- ------------------------------------------------------------
SELECT p.product_id, p.product_name, p.category, p.price, p.stock
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
WHERE oi.order_item_id IS NULL
ORDER BY p.product_id;


-- ------------------------------------------------------------
-- QUERY 11: Products with low stock (10 units or fewer)
-- Purpose: Identify products that may need restocking.
-- Note: Change 10 to another threshold if your project uses a different rule.
-- ------------------------------------------------------------
SELECT product_id, product_name, category, stock
FROM products
WHERE stock <= 10
ORDER BY stock ASC, product_name;


-- ------------------------------------------------------------
-- QUERY 12: Current inventory value by product
-- Purpose: Estimate stock value using current price multiplied by stock.
-- ------------------------------------------------------------
SELECT product_id,
       product_name,
       category,
       price,
       stock,
       ROUND(price * stock, 2) AS estimated_inventory_value
FROM products
ORDER BY estimated_inventory_value DESC;


-- ------------------------------------------------------------
-- QUERY 13: Total estimated value of current inventory
-- Purpose: Calculate the estimated value of all current stock.
-- ------------------------------------------------------------
SELECT ROUND(SUM(price * stock), 2) AS total_estimated_inventory_value
FROM products;


-- ------------------------------------------------------------
-- QUERY 14: Total amount recorded in payments
-- Purpose: Sum all amounts stored in the payments table.
-- Note: There is no payment_status column, so this is not filtered by success.
-- ------------------------------------------------------------
SELECT COUNT(*) AS total_payment_records,
       ROUND(SUM(amount), 2) AS total_payment_amount,
       ROUND(AVG(amount), 2) AS average_payment_amount
FROM payments;


-- ------------------------------------------------------------
-- QUERY 15: Payment totals by payment mode
-- Purpose: Compare recorded payment amounts by payment method.
-- ------------------------------------------------------------
SELECT payment_mode,
       COUNT(*) AS payment_count,
       ROUND(SUM(amount), 2) AS total_amount,
       ROUND(AVG(amount), 2) AS average_amount
FROM payments
GROUP BY payment_mode
ORDER BY total_amount DESC;


-- ------------------------------------------------------------
-- QUERY 16: Payments recorded each month
-- Purpose: Analyze payment records over time.
-- ------------------------------------------------------------
SELECT DATE_FORMAT(payment_date, '%Y-%m') AS payment_month,
       COUNT(*) AS payment_count,
       ROUND(SUM(amount), 2) AS total_payment_amount
FROM payments
GROUP BY DATE_FORMAT(payment_date, '%Y-%m')
ORDER BY payment_month;


-- ------------------------------------------------------------
-- QUERY 17: Orders with their customer details
-- Purpose: Demonstrate a JOIN between orders and customers.
-- ------------------------------------------------------------
SELECT o.order_id,
       o.order_date,
       o.order_status,
       c.customer_id,
       c.name AS customer_name,
       c.city
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
ORDER BY o.order_date DESC, o.order_id
LIMIT 50;


-- ------------------------------------------------------------
-- QUERY 18: Order items with product details
-- Purpose: Demonstrate a JOIN between order_items and products.
-- ------------------------------------------------------------
SELECT oi.order_item_id,
       oi.order_id,
       p.product_id,
       p.product_name,
       p.category,
       oi.quantity,
       p.price AS current_product_price,
       ROUND(oi.quantity * p.price, 2) AS estimated_line_value_at_current_price
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
ORDER BY oi.order_id, oi.order_item_id
LIMIT 100;


-- ------------------------------------------------------------
-- QUERY 19: Estimated order value for each order
-- Purpose: Sum quantity multiplied by the CURRENT product price per order.
-- Important: This is an estimate because order_items has no stored unit_price.
-- ------------------------------------------------------------
SELECT o.order_id,
       o.order_date,
       o.order_status,
       c.name AS customer_name,
       ROUND(SUM(oi.quantity * p.price), 2) AS estimated_order_value
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY o.order_id, o.order_date, o.order_status, c.name
ORDER BY estimated_order_value DESC
LIMIT 20;


-- ------------------------------------------------------------
-- QUERY 20: Number of items in each order
-- Purpose: Count total units and distinct product types per order.
-- ------------------------------------------------------------
SELECT o.order_id,
       o.order_date,
       COUNT(oi.order_item_id) AS distinct_order_lines,
       SUM(oi.quantity) AS total_units
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.order_date
ORDER BY total_units DESC, o.order_id
LIMIT 20;


-- ------------------------------------------------------------
-- QUERY 21: Orders with no payment record
-- Purpose: Find orders that do not have a matching payment row.
-- Note: This checks whether a payment record exists, not whether it succeeded.
-- ------------------------------------------------------------
SELECT o.order_id, o.customer_id, o.order_date, o.order_status
FROM orders o
LEFT JOIN payments p ON p.order_id = o.order_id
WHERE p.payment_id IS NULL
ORDER BY o.order_id;


-- ------------------------------------------------------------
-- QUERY 22: Number of payment records per order
-- Purpose: Find orders with multiple payment records.
-- ------------------------------------------------------------
SELECT o.order_id,
       COUNT(p.payment_id) AS payment_records,
       ROUND(SUM(p.amount), 2) AS total_recorded_payment
FROM orders o
JOIN payments p ON p.order_id = o.order_id
GROUP BY o.order_id
HAVING COUNT(p.payment_id) > 1
ORDER BY payment_records DESC, o.order_id;


-- ------------------------------------------------------------
-- QUERY 23: Customer signup counts by month
-- Purpose: Review customer registration trends.
-- ------------------------------------------------------------
SELECT DATE_FORMAT(signup_date, '%Y-%m') AS signup_month,
       COUNT(*) AS new_customers
FROM customers
WHERE signup_date IS NOT NULL
GROUP BY DATE_FORMAT(signup_date, '%Y-%m')
ORDER BY signup_month;


-- ------------------------------------------------------------
-- QUERY 24: Average number of order lines per order
-- Purpose: Calculate the average number of distinct order-item rows.
-- Note: This counts order lines, not total quantity of units.
-- ------------------------------------------------------------
SELECT ROUND(AVG(item_line_count), 2) AS average_order_lines
FROM (
    SELECT o.order_id,
           COUNT(oi.order_item_id) AS item_line_count
    FROM orders o
    LEFT JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.order_id
) AS order_line_counts;


-- ------------------------------------------------------------
-- QUERY 25: Referential integrity check
-- Purpose: Confirm all referenced customers, orders and products exist.
-- Expected result: all four invalid_* counts should be zero.
-- ------------------------------------------------------------
SELECT
    (SELECT COUNT(*)
     FROM orders o
     LEFT JOIN customers c ON c.customer_id = o.customer_id
     WHERE c.customer_id IS NULL) AS invalid_order_customers,

    (SELECT COUNT(*)
     FROM order_items oi
     LEFT JOIN orders o ON o.order_id = oi.order_id
     WHERE o.order_id IS NULL) AS invalid_order_items_orders,

    (SELECT COUNT(*)
     FROM order_items oi
     LEFT JOIN products p ON p.product_id = oi.product_id
     WHERE p.product_id IS NULL) AS invalid_order_items_products,

    (SELECT COUNT(*)
     FROM payments pm
     LEFT JOIN orders o ON o.order_id = pm.order_id
     WHERE o.order_id IS NULL) AS invalid_payment_orders;
