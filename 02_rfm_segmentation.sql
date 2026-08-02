-- ============================================================
-- 02_rfm_segmentation.sql
-- Customer Segmentation Project — RFM Scoring & Segmentation
-- ============================================================

-- ------------------------------------------------------------
-- STEP 1: RFM Scoring
-- Recency  = days since each customer's last purchase
-- Frequency = number of distinct invoices (orders)
-- Monetary  = total revenue (quantity * price)
--
-- NTILE(5) splits customers into 5 equal-sized buckets, scored 1-5.
-- Direction convention: 5 = best, 1 = worst, for all three scores.
--   r_score: most RECENT customers get score 5 (ORDER BY days DESC)
--   f_score: HIGHEST frequency gets score 5 (ORDER BY frequency ASC)
--   m_score: HIGHEST monetary gets score 5 (ORDER BY monetary ASC)
-- ------------------------------------------------------------

CREATE TABLE customer_rfm_scored AS
WITH rfm_base AS (
    SELECT customer_id,
        MAX(invoice_date) AS last_purchase_date,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(quantity * price) AS monetary
    FROM online_retail_cleaned
    WHERE transaction_type = 'normal'
    GROUP BY customer_id
),
reference AS (
    SELECT MAX(invoice_date)::date AS max_date FROM online_retail_cleaned
),
rfm_calculated AS (
    SELECT customer_id,
        (SELECT max_date FROM reference) - last_purchase_date::date AS days_since_last_purchase,
        frequency, monetary
    FROM rfm_base
)
SELECT customer_id, days_since_last_purchase, frequency, monetary,
    NTILE(5) OVER (ORDER BY days_since_last_purchase DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
FROM rfm_calculated;

-- ------------------------------------------------------------
-- STEP 2: Customer Segmentation
-- Business labels applied on top of RFM scores.
-- Segment logic verified to leave zero customers in "Others" —
-- every combination of r/f/m scores (all 125 possibilities) is
-- covered by one of the branches below.
-- ------------------------------------------------------------

CREATE TABLE customer_segments AS
SELECT *,
    CONCAT(r_score, f_score, m_score) AS rfm_code,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN f_score >= 4 AND m_score IN (3,4,5) AND r_score IN (3,4) THEN 'Loyal Customers'
        WHEN m_score >= 4 AND f_score <= 4 THEN 'Big Spenders'
        WHEN f_score >= 3 AND m_score <= 2 THEN 'Frequent Spenders'
        WHEN r_score >= 4 AND f_score <= 2 AND m_score <= 2 THEN 'New'
        WHEN r_score <= 5 AND (f_score = 3 OR m_score = 3) THEN 'Potential Loyalist'
        WHEN r_score = 3 AND f_score <= 2 AND m_score <= 2 THEN 'Needs Attention'
        WHEN r_score <= 2 AND (f_score >= 3 OR m_score >= 3) THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
        ELSE 'Others'
    END AS customer_segment
FROM customer_rfm_scored;

-- ------------------------------------------------------------
-- Note: the "At Risk" label in this table is a whole-dataset,
-- single-snapshot proxy based on relative recency/frequency/monetary
-- scores. It is DIFFERENT and less precise than the "at risk" definition
-- used in 03_analysis_questions.sql (Q3), which compares each customer's
-- own past period against their own recent period. Consider renaming
-- this segment "Dormant" in reporting to avoid confusion between the two.
-- ------------------------------------------------------------
