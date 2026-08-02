-- ============================================================
-- 01_cleaning.sql
-- Customer Segmentation Project — Data Cleaning
-- Dataset: UCI Online Retail II (2009-2011)
-- ============================================================
-- Raw data was imported as-is (all TEXT columns) into
-- online_retail_raw from two CSV files (2009-2010, 2010-2011).
-- online_retail_raw is NEVER modified directly — all cleaning
-- logic below produces a new table, online_retail_cleaned.
-- ============================================================

CREATE TABLE online_retail_cleaned AS
SELECT
    invoice,

    -- Standardize stock codes: uppercase + trim whitespace
    UPPER(TRIM(stock_code)) AS stock_code,

    -- Standardize descriptions: uppercase, trim, collapse repeated spaces
    UPPER(TRIM(REGEXP_REPLACE(description, '\s+', ' ', 'g'))) AS description,

    CAST(quantity AS INTEGER) AS quantity,
    CAST(invoice_date AS TIMESTAMP) AS invoice_date,
    CAST(price AS NUMERIC(10,2)) AS price,

    -- customer_id arrives as text with decimal formatting (e.g. "17850.0")
    -- cast through NUMERIC first, then to INTEGER, to avoid cast errors
    CAST(CAST(customer_id AS NUMERIC) AS INTEGER) AS customer_id,

    -- Normalize country labels:
    -- 'EIRE' is the dataset's legacy label for Ireland
    -- 'Unspecified' is left as-is (not renamed) — retained verbatim
    TRIM(CASE
        WHEN country = 'EIRE' THEN 'Ireland'
        ELSE country
    END) AS country,

    -- Flag transaction type based on invoice prefix and quantity sign:
    --   'C' prefix        -> cancellation (customer cancelled an order)
    --   'A' prefix        -> adjustment (manual account/bad debt adjustment)
    --   negative quantity -> inventory_adjustment (stock correction, not a sale)
    --   everything else   -> normal
    CASE
        WHEN invoice LIKE 'C%' THEN 'cancellation'
        WHEN invoice LIKE 'A%' THEN 'adjustment'
        WHEN CAST(quantity AS INTEGER) < 0 THEN 'inventory_adjustment'
        ELSE 'normal'
    END AS transaction_type

FROM online_retail_raw

-- Exclude non-product administrative stock codes (postage, bank charges,
-- manual entries, discounts, etc.) — these are not real product sales
WHERE stock_code NOT IN ('POST','D','C2','S','BANK CHARGES','M','DOT','AMAZONFEE')

  -- Exclude rows with no product description
  AND description IS NOT NULL

  -- Exclude rows with no customer_id — these can't be attributed to any
  -- customer and are not usable for customer-level analysis (RFM, segments)
  AND customer_id IS NOT NULL
  AND customer_id != '';

-- ============================================================
-- Data quality notes:
-- - 'European Community' and 'Unspecified' are retained as-is (not
--   renamed/relabeled); they represent a small share of revenue and
--   are non-standard/placeholder country values in the source data.
-- - Rows lost during cleaning (customer_id nulls, admin stock codes)
--   are intentionally excluded and remain untouched in online_retail_raw.
-- ============================================================
