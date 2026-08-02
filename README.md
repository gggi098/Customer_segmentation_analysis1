# Customer Segmentation & Churn Analysis — Online Retail

SQL portfolio project analyzing customer behavior, revenue concentration, and churn
using RFM (Recency, Frequency, Monetary) analysis on the UCI Online Retail II dataset.

---

## Business Question

> "Our online retail revenue has been inconsistent, and I'm worried we're losing good
> customers without noticing. I need to understand who our best customers are, who's
> at risk of leaving, and what we should actually do about it before next quarter."

---

## Dataset

- **Source:** [UCI Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii) — real UK-based online retail transactions, Dec 2009–Dec 2011
- **Size:** ~1,067,371 raw transaction rows across two years
- **Tools:** PostgreSQL, pgAdmin

---

## Methodology

1. **Import** — both years' CSVs loaded into a single raw staging table (`online_retail_raw`), all columns as TEXT, never modified after import.
2. **Clean** — cast types, standardize stock codes/descriptions/country labels, flag transaction type (normal sale, cancellation, adjustment, inventory adjustment), and exclude non-product/administrative rows. See `01_cleaning.sql`.
3. **Score** — calculate Recency, Frequency, and Monetary values per customer, then rank into 1–5 scores using `NTILE(5)`. See `02_rfm_segmentation.sql`.
4. **Segment** — label each customer into one of nine business segments (Champions, Loyal Customers, Big Spenders, Frequent Spenders, Potential Loyalist, At Risk, Lost, New, Needs Attention) based on their RFM scores.
5. **Analyze** — answer 9 targeted business sub-questions using the cleaned and segmented data. See `03_analysis_questions.sql` and `findings.md`.
6. **Synthesize** — translate findings into segment-level recommendations and quantify the revenue impact of retention. See `Q10_final_summary.md`.

---

## Repository Structure

| File | Contents |
|---|---|
| `01_cleaning.sql` | Raw data cleaning logic, with documented decisions |
| `02_rfm_segmentation.sql` | RFM scoring and customer segmentation |
| `03_analysis_questions.sql` | All 9 analytical sub-questions, one section each |
| `findings.md` | Question-by-question results and interpretations |
| `Q10_final_summary.md` | Executive summary, segment recommendations, revenue impact |

---

## Executive Summary

### Who Are Our Best Customers?
- **Champions** and **Loyal Customers** — highest across recency, frequency, and monetary value
- **Top 20 customers** by revenue generate **£3,815,486.59** — **21.88%** of total company revenue

### Who Is At Risk?
- **76 customers** flagged as at-risk: historically high-value, but activity collapsed in the most recent 3 months. Revenue at stake: **£263,559.73 (1.58% of total revenue)**
- **232 customers** went completely silent (zero recent activity), representing an additional **£820,890.66** in past revenue
- Root-cause analysis ruled out product discontinuation and pricing changes — this is **genuine customer churn**, not a catalog or pricing issue
- Decline is broad-based across nearly every country (65–85% drop), including the UK, our largest market (-75.30%)
- Cancellation rates for at-risk customers roughly doubled (2.29% → 4.62%) — a secondary warning signal

### What Should We Do?
| Segment | Action |
|---|---|
| Champions | Protect and reward — loyalty perks, VIP treatment |
| Loyal Customers | Marketing to increase frequency/spend toward Champion status |
| Big Spenders | Offer premium products, encourage frequency |
| Potential Loyalist | Engagement campaigns to build purchase consistency and recency |
| Frequent Spenders | Encourage higher basket value through bundling or upsell offers |
| New | High-priority nurture — strong onboarding and early incentives |
| Needs Attention | Immediate engagement — one step from At Risk |
| At Risk | Direct outreach and competitive analysis (not price/product changes — ruled out as causes) |
| Lost | Not a recovery priority — use as a pattern to catch early warning signs elsewhere |

**Revenue impact:** Retaining the 76 at-risk customers would **preserve £263,559.73** (1.58% of total revenue) that would otherwise be lost. Including the fully-silent tier, total revenue exposure across both churn groups is **£1,084,450.39**.

Full detail: see [`Q10_final_summary.md`](./Q10_final_summary.md) and [`findings.md`](./findings.md).

---

## Key Decisions & Data Quality Notes

- `online_retail_raw` is never modified — all cleaning happens in `online_retail_cleaned`
- Transaction type flagged as: `cancellation` (C-prefix invoices), `adjustment` (A-prefix invoices), `inventory_adjustment` (negative quantity), `normal` (standard sale)
- Non-product administrative stock codes (postage, bank charges, manual entries) excluded
- `EIRE` relabeled to `Ireland`; `Unspecified` and `European Community` retained as-is (small share of revenue, non-standard placeholder labels in the source data)
- At-risk customers defined using a fresh past-vs-recent 3-month comparison (not reused from the whole-dataset RFM snapshot), for a more precise churn signal
