-- ============================================================
-- 03_analysis_questions.sql
-- Customer Segmentation Project — Business Sub-Questions Q1-Q9
-- ============================================================


-- ============================================================
-- Q1: What customer segments exist based on RFM combined,
-- and how much revenue does each segment generate?
-- ============================================================
SELECT customer_segment, COUNT(*) AS customer_count,
    ROUND(SUM(monetary), 2) AS segment_revenue,
    ROUND(SUM(monetary) * 100 / SUM(SUM(monetary)) OVER (), 2) AS revenue_percentage
FROM customer_segments
GROUP BY customer_segment
ORDER BY CASE customer_segment
    WHEN 'Champions' THEN 1 WHEN 'Loyal Customers' THEN 2
    WHEN 'Potential Loyalists' THEN 3 WHEN 'New Customers' THEN 4
    WHEN 'Big Spenders' THEN 5
    WHEN 'Needs Attention' THEN 7 WHEN 'At Risk' THEN 8
    WHEN 'Lost Customers' THEN 9 ELSE 10 END;


-- ============================================================
-- Q2: How much of total revenue comes from our top customers?
-- (Top 20 customers ranked by total revenue, company-wide)
-- ============================================================
WITH top20 AS (
    SELECT customer_id, SUM(quantity * price) AS revenue
    FROM online_retail_cleaned
    WHERE transaction_type = 'normal'
    GROUP BY customer_id
    ORDER BY revenue DESC
    LIMIT 20
)
SELECT ROUND(SUM(revenue), 2) AS top20_revenue,
    ROUND(SUM(revenue) * 100.0 / (
        SELECT SUM(quantity * price)
        FROM online_retail_cleaned
        WHERE transaction_type = 'normal'
    ), 2) AS percentage_of_total
FROM top20;


-- ============================================================
-- Q3: Which historically high-value customers have shown a
-- recent drop in Recency/Frequency/Monetary?
-- (Past = everything before the last 3 months; Recent = last 3 months.
--  Scored independently per period, not reused from Q1's snapshot.)
-- ============================================================
CREATE TABLE at_risk_customers_q3 AS
WITH reference AS (
    SELECT MAX(invoice_date) - INTERVAL '3 months' AS cutoff
    FROM online_retail_cleaned
),
past_base AS (
    SELECT customer_id, MAX(invoice_date) AS recency,
        COUNT(DISTINCT invoice) AS frequency, SUM(quantity * price) AS revenue
    FROM online_retail_cleaned
    WHERE invoice_date < (SELECT cutoff FROM reference) AND transaction_type = 'normal'
    GROUP BY customer_id
),
recent_base AS (
    SELECT customer_id, MAX(invoice_date) AS recency,
        COUNT(DISTINCT invoice) AS frequency, SUM(quantity * price) AS revenue
    FROM online_retail_cleaned
    WHERE invoice_date >= (SELECT cutoff FROM reference) AND transaction_type = 'normal'
    GROUP BY customer_id
),
past_scored AS (
    SELECT customer_id,
        NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(5) OVER (ORDER BY revenue ASC) AS m_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score
    FROM past_base
),
recent_scored AS (
    SELECT customer_id,
        NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(5) OVER (ORDER BY revenue ASC) AS m_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score
    FROM recent_base
),
past_flag AS (
    SELECT customer_id,
        CASE WHEN f_score >= 4 AND r_score >= 4 AND m_score >= 4 THEN 1 ELSE 0 END AS high_value
    FROM past_scored
),
recent_flag AS (
    SELECT customer_id,
        CASE WHEN f_score <= 2 AND r_score <= 2 AND m_score <= 2 THEN 1 ELSE 0 END AS dropped
    FROM recent_scored
)
SELECT p.customer_id, pb.revenue AS past_revenue, p.high_value, r.dropped
FROM past_flag p
JOIN recent_flag r ON p.customer_id = r.customer_id
JOIN past_base pb ON p.customer_id = pb.customer_id
WHERE p.high_value = 1 AND r.dropped = 1;

-- Note: INNER JOIN means customers with ZERO rows in the recent period
-- (fully silent) are excluded here by design. See the fully-silent
-- table below for that separate, more severe churn tier.

SELECT COUNT(*) AS at_risk_customer_count FROM at_risk_customers_q3;


-- Fully silent tier: high-value in the past, ZERO activity in recent period
CREATE TABLE at_risk_customers_fully_silent AS
WITH reference AS (
    SELECT MAX(invoice_date) - INTERVAL '3 months' AS cutoff
    FROM online_retail_cleaned
),
past_base AS (
    SELECT customer_id, MAX(invoice_date) AS recency,
        COUNT(DISTINCT invoice) AS frequency, SUM(quantity * price) AS revenue
    FROM online_retail_cleaned
    WHERE invoice_date < (SELECT cutoff FROM reference) AND transaction_type = 'normal'
    GROUP BY customer_id
),
past_scored AS (
    SELECT customer_id, revenue,
        NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(5) OVER (ORDER BY revenue ASC) AS m_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score
    FROM past_base
),
past_high_value AS (
    SELECT customer_id, revenue
    FROM past_scored
    WHERE f_score >= 4 AND r_score >= 4 AND m_score >= 4
)
SELECT phv.customer_id, phv.revenue AS past_revenue
FROM past_high_value phv
WHERE NOT EXISTS (
    SELECT 1 FROM online_retail_cleaned r
    WHERE r.customer_id = phv.customer_id
      AND r.transaction_type = 'normal'
      AND r.invoice_date >= (SELECT cutoff FROM reference)
);

SELECT COUNT(*) AS fully_silent_customer_count FROM at_risk_customers_fully_silent;
SELECT ROUND(SUM(past_revenue), 2) AS fully_silent_past_revenue FROM at_risk_customers_fully_silent;


-- ============================================================
-- Q4: If at-risk customers churn completely, how much revenue
-- is lost, in absolute terms and as a % of total revenue?
-- ============================================================
WITH at_risk_revenue AS (
    SELECT SUM(past_revenue) AS at_risk_total FROM at_risk_customers_q3
),
total_revenue AS (
    SELECT SUM(quantity * price) AS company_total
    FROM online_retail_cleaned WHERE transaction_type = 'normal'
)
SELECT ROUND(ar.at_risk_total, 2) AS at_risk_total,
    ROUND(tr.company_total, 2) AS company_total,
    ROUND(ar.at_risk_total / tr.company_total * 100, 2) AS pct_revenue_at_risk
FROM at_risk_revenue ar, total_revenue tr;


-- ============================================================
-- Q5: Is the drop explained by product/price changes, or is
-- it genuine churn?
-- ============================================================

-- 5a: Did at-risk customers' top past products stop being sold?
--     (Confirms products still appear in the recent-period catalog.)
SELECT description, stock_code, customer_id, price
FROM online_retail_cleaned
WHERE stock_code IN (
    SELECT r.stock_code
    FROM online_retail_cleaned r
    JOIN at_risk_customers_q3 a ON r.customer_id = a.customer_id
    WHERE r.transaction_type = 'normal'
      AND r.invoice_date < (SELECT MAX(invoice_date) - INTERVAL '3 months' FROM online_retail_cleaned)
    GROUP BY r.stock_code
    ORDER BY SUM(r.quantity * r.price) DESC
    LIMIT 10
)
  AND transaction_type = 'normal'
  AND invoice_date >= (SELECT MAX(invoice_date) - INTERVAL '3 months' FROM online_retail_cleaned);

-- 5b: Did the price of those same products change, company-wide?
SELECT stock_code, description,
    ROUND(AVG(CASE WHEN invoice_date < (SELECT MAX(invoice_date) - INTERVAL '3 months' FROM online_retail_cleaned)
        THEN price END), 2) AS avg_past_price,
    ROUND(AVG(CASE WHEN invoice_date >= (SELECT MAX(invoice_date) - INTERVAL '3 months' FROM online_retail_cleaned)
        THEN price END), 2) AS avg_recent_price
FROM online_retail_cleaned
WHERE stock_code IN (
    SELECT r2.stock_code
    FROM online_retail_cleaned r2
    JOIN at_risk_customers_q3 a ON r2.customer_id = a.customer_id
    WHERE r2.transaction_type = 'normal'
      AND r2.invoice_date < (SELECT MAX(invoice_date) - INTERVAL '3 months' FROM online_retail_cleaned)
    GROUP BY r2.stock_code
    ORDER BY SUM(r2.quantity * r2.price) DESC
    LIMIT 10
)
  AND transaction_type = 'normal'
GROUP BY stock_code, description;

-- 5c: Did at-risk customers' overall buying activity collapse
--     (all products), not just their old favorites?
SELECT customer_id,
    COUNT(DISTINCT CASE WHEN invoice_date < (SELECT MAX(invoice_date) - INTERVAL '3 months' FROM online_retail_cleaned)
        THEN stock_code END) AS past_distinct_products,
    COUNT(DISTINCT CASE WHEN invoice_date >= (SELECT MAX(invoice_date) - INTERVAL '3 months' FROM online_retail_cleaned)
        THEN stock_code END) AS recent_distinct_products,
    COUNT(DISTINCT CASE WHEN invoice_date < (SELECT MAX(invoice_date) - INTERVAL '3 months' FROM online_retail_cleaned)
        THEN invoice END) AS past_orders,
    COUNT(DISTINCT CASE WHEN invoice_date >= (SELECT MAX(invoice_date) - INTERVAL '3 months' FROM online_retail_cleaned)
        THEN invoice END) AS recent_orders
FROM online_retail_cleaned
WHERE customer_id IN (SELECT customer_id FROM at_risk_customers_q3)
  AND transaction_type = 'normal'
GROUP BY customer_id
ORDER BY customer_id;

-- Conclusion: products remained available, prices showed no meaningful
-- change, and activity collapsed across ALL products (not just favorites)
-- -> genuine customer churn, not a product or pricing issue.


-- ============================================================
-- Q6: Which countries show the sharpest decline in customer
-- purchasing (past vs. recent revenue)?
-- ============================================================
WITH past AS (
    SELECT country, SUM(quantity * price) AS past_revenue
    FROM online_retail_cleaned
    WHERE transaction_type = 'normal'
      AND invoice_date < (SELECT MAX(invoice_date) - INTERVAL '3 months' FROM online_retail_cleaned)
    GROUP BY country
),
recent AS (
    SELECT country, SUM(quantity * price) AS recent_revenue
    FROM online_retail_cleaned
    WHERE transaction_type = 'normal'
      AND invoice_date >= (SELECT MAX(invoice_date) - INTERVAL '3 months' FROM online_retail_cleaned)
    GROUP BY country
)
SELECT p.country, p.past_revenue, COALESCE(r.recent_revenue, 0) AS recent_revenue,
    ROUND((COALESCE(r.recent_revenue, 0) - p.past_revenue) * 100.0 / p.past_revenue, 2) AS pct_change
FROM past p
LEFT JOIN recent r ON p.country = r.country
ORDER BY pct_change ASC;

-- Note: countries showing -100% are mostly small markets with low
-- absolute past_revenue; prioritize interpreting decline by combining
-- pct_change with past_revenue size, not pct_change alone.


-- ============================================================
-- Q7: Is overall revenue declining, growing, or flat
-- quarter-over-quarter?
-- ============================================================
CREATE TABLE quarterly_revenue AS
SELECT DATE_TRUNC('quarter', invoice_date) AS quarter,
    ROUND(SUM(quantity * price), 2) AS quarterly_revenue,
    COUNT(DISTINCT invoice) AS order_count,
    COUNT(DISTINCT customer_id) AS active_customers
FROM online_retail_cleaned
WHERE transaction_type = 'normal'
GROUP BY DATE_TRUNC('quarter', invoice_date)
ORDER BY quarter;

SELECT quarter, quarterly_revenue, prev_revenue,
    ROUND((quarterly_revenue - prev_revenue) * 100.0 / prev_revenue, 2) AS pct_change
FROM (
    SELECT quarter, quarterly_revenue,
        LAG(quarterly_revenue) OVER (ORDER BY quarter) AS prev_revenue
    FROM quarterly_revenue
) sub
ORDER BY quarter;


-- ============================================================
-- Q8: Do top-tier (top 20 by revenue) customers concentrate
-- their spend on just a few products (dependency risk)?
-- ============================================================
CREATE TABLE top20_product_dependency AS
WITH top20_customers AS (
    SELECT customer_id
    FROM online_retail_cleaned
    WHERE transaction_type = 'normal'
    GROUP BY customer_id
    ORDER BY SUM(quantity * price) DESC
    LIMIT 20
),
customer_product_revenue AS (
    SELECT r.customer_id, r.stock_code, r.description,
        SUM(r.quantity * r.price) AS product_revenue
    FROM online_retail_cleaned r
    JOIN top20_customers t ON r.customer_id = t.customer_id
    WHERE r.transaction_type = 'normal'
    GROUP BY r.customer_id, r.stock_code, r.description
),
ranked AS (
    SELECT customer_id, stock_code, description, product_revenue,
        RANK() OVER (PARTITION BY customer_id ORDER BY product_revenue DESC) AS revenue_rank,
        SUM(product_revenue) OVER (PARTITION BY customer_id) AS total_customer_revenue
    FROM customer_product_revenue
),
top3_per_customer AS (
    SELECT customer_id, total_customer_revenue,
        SUM(product_revenue) AS top3_revenue
    FROM ranked
    WHERE revenue_rank <= 3
    GROUP BY customer_id, total_customer_revenue
)
SELECT customer_id, total_customer_revenue, top3_revenue,
    ROUND(top3_revenue * 100.0 / total_customer_revenue, 2) AS top3_products_pct_of_revenue
FROM top3_per_customer
ORDER BY customer_id;

-- View the per-customer result:
SELECT * FROM top20_product_dependency ORDER BY customer_id;

-- Summary stat used in reporting (now references the saved table, not an
-- out-of-scope CTE — CTEs only exist within their own single statement):
SELECT ROUND(AVG(top3_products_pct_of_revenue), 2) AS avg_dependency_pct
FROM top20_product_dependency;


-- ============================================================
-- Q9: Do at-risk customers show higher cancellation rates
-- before disappearing (past vs. recent)?
-- ============================================================
SELECT
    CASE WHEN r.invoice_date < (SELECT MAX(invoice_date) - INTERVAL '3 months' FROM online_retail_cleaned)
        THEN 'past' ELSE 'recent' END AS period,
    COUNT(*) FILTER (WHERE r.transaction_type = 'cancellation') AS cancellations,
    COUNT(*) AS total_transactions,
    ROUND(COUNT(*) FILTER (WHERE r.transaction_type = 'cancellation') * 100.0 / COUNT(*), 2) AS cancellation_rate
FROM at_risk_customers_q3 a
JOIN online_retail_cleaned r ON a.customer_id = r.customer_id
GROUP BY period;
