# Findings — Customer Segmentation Analysis

Full queries for every question below are in `03_analysis_questions.sql` (Q1–Q9) and `02_rfm_segmentation.sql` (segmentation logic).

---

## Q1: What customer segments exist based on RFM combined?

**Query:** See `02_rfm_segmentation.sql` and `03_analysis_questions.sql` — Q1 section

**Result:**

| customer_segment | customer_count | segment_revenue | revenue_percentage |
|---|---|---|---|
| Champions | 1299 | 11,930,519.42 | 68.41 |
| Loyal Customers | 558 | 1,795,401.58 | 10.30 |
| Big Spenders | 546 | 1,486,432.35 | 8.52 |
| Potential Loyalist | 1041 | 923,273.51 | 5.29 |
| At Risk | 74 | 614,113.04 | 3.52 |
| Lost | 1358 | 354,343.49 | 2.03 |
| Frequent Spenders | 321 | 137,490.80 | 0.79 |
| New | 364 | 109,344.91 | 0.63 |
| Needs Attention | 303 | 88,041.20 | 0.50 |

**Interpretation:** Customers were split into nine segments based on their Recency, Frequency, and Monetary scores (1–5 scale, 5 = best). Champions represent the company's most valuable segment: although they account for only 22% of customers, they generate **68.41%** of revenue, showing strong revenue concentration among high-value buyers. Loyal Customers and Big Spenders form the next tier (10.30% and 8.52% of revenue respectively). Lost, despite being the largest group by count (1,358), contribute only 2.03% of revenue. At Risk (this table's whole-dataset RFM proxy) is a relatively small group at 74 customers — note this is a broader, less precise definition than the "at risk" group used in Q3/Q4, which is based on each customer's own past-vs-recent activity comparison.

*Note: Champions is defined as the top 40% on each RFM dimension (scores 4–5), not the top 20%. Since recency, frequency, and spending are naturally correlated in real purchase behavior, this threshold captures a larger, more concentrated group than three independent 20% cutoffs would.*

---

## Q2: How much of total revenue comes from our top customers?

**Query:** See `03_analysis_questions.sql` — Q2 section

**Result:**

| top20_revenue | percentage_of_total |
|---|---|
| 3,815,486.59 | 21.88 |

**Interpretation:** The top 20 customers by total revenue generate **£3,815,486.59**, or **21.88%** of total company revenue. Revenue is meaningfully concentrated in a small group of customers — both a strength (high-value relationships) and a risk (dependency on a small base).

---

## Q3: Which historically high-value customers have shown a recent drop in R/F/M?

**Query:** See `03_analysis_questions.sql` — Q3 section

**Result:**

| customer_id | past_revenue | recent_revenue | high_value | dropped |
|---|---|---|---|---|
| 12412 | 2098.79 | 306.14 | 1 | 1 |
| 12609 | 2731.74 | 290.12 | 1 | 1 |
| 12633 | 4958.93 | 197.23 | 1 | 1 |
| 12637 | 7819.91 | 322.40 | 1 | 1 |
| 13145 | 1304.72 | 118.80 | 1 | 1 |

**Interpretation:** 76 customers were high-value in the past period but collapsed to minimal activity in the most recent 3 months. A further 232 customers went completely silent (zero recent orders), representing £820,890.66 in past revenue — a separate, more severe churn tier.

---

## Q4: If at-risk customers churn completely, how much revenue is lost?

**Query:** See `03_analysis_questions.sql` — Q4 section

**Result:**

| at_risk_total | company_total | pct_revenue_at_risk |
|---|---|---|
| 263,559.73 | 16,709,814.41 | 1.58 |

**Interpretation:** If the 76 at-risk customers churn completely, the company stands to lose **£263,559.73** — **1.58%** of total revenue. This is the direct revenue exposure tied to retention efforts for this group.

---

## Q5: Is the drop explained by price/product changes, or genuine churn?

**Query:** See `03_analysis_questions.sql` — Q5 section (5a, 5b, 5c)

**Result:** All top 10 products previously purchased by at-risk customers were confirmed still available and still being purchased by other customers in the recent period. Average prices on those same products showed no meaningful change between past and recent periods. At-risk customers' order and product-variety counts collapsed across the board (not just their previous favorites) — e.g., one customer dropped from 68 distinct products / 8 orders in the past to 9 products / 1 order recently.

**Interpretation:** The drop is **not explained by product discontinuation or pricing changes** — both were ruled out. Combined with the sharp, across-the-board activity collapse, this points to **genuine customer churn** driven by factors outside this dataset (e.g., competitor activity, changing needs, service dissatisfaction).

---

## Q6: Which countries show the sharpest decline in customer purchasing?

**Query:** See `03_analysis_questions.sql` — Q6 section

**Result:**

| country | past_revenue | recent_revenue | pct_change |
|---|---|---|---|
| United Kingdom | 11,727,527.61 | 2,896,966.66 | -75.30 |
| Ireland | 514,514.33 | 78,418.67 | -84.76 |
| Netherlands | 447,491.96 | 102,460.70 | -77.10 |
| Germany | 317,523.19 | 71,436.80 | -77.50 |
| France | 242,775.60 | 72,542.80 | -70.12 |

**Interpretation:** Nearly every country declined 65–85% in the recent period vs. the past, including the UK (our largest market) at -75.30%. Decline is broad-based and global, not isolated to one region — this supports the genuine-churn conclusion over a market-specific cause. A handful of very small markets show -100%, but their low absolute revenue makes them a minor factor. Because the dataset covers only two years, seasonal effects cannot be completely separated from customer churn; however, the decline is broad across countries and segments, which weakens a purely seasonal explanation.

---

## Q7: Is overall revenue declining, growing, or flat quarter-over-quarter?

**Query:** See `03_analysis_questions.sql` — Q7 section

**Result:**

| year | quarter | revenue | prev_revenue | qoq_growth_pct |
|---|---|---|---|---|
| 2009 | Q4 | 681,179.72 | — | — |
| 2010 | Q1 | 1,707,184.77 | 681,179.72 | 150.62 |
| 2010 | Q2 | 1,814,898.71 | 1,707,184.77 | 6.31 |
| 2010 | Q3 | 1,988,112.81 | 1,814,898.71 | 9.54 |
| 2010 | Q4 | 3,054,008.37 | 1,988,112.81 | 53.61 |
| 2011 | Q1 | 1,591,935.51 | 3,054,008.37 | -47.87 |
| 2011 | Q2 | 1,770,181.37 | 1,591,935.51 | 11.20 |
| 2011 | Q3 | 2,170,439.95 | 1,770,181.37 | 22.61 |
| 2011 | Q4 | 2,661,019.10 | 2,170,439.95 | 22.60 |

**Interpretation:** Revenue grew steadily from 2009 Q4 through 2010 Q4 (£681K → £3.05M), dropped sharply in 2011 Q1 (-47.87%), then recovered and grew again through 2011 Q4. Overall trend is long-term growth, with one significant anomaly worth flagging for further investigation.

---

## Q8: Do top-tier customers concentrate on a few products (dependency risk)?

**Query:** See `03_analysis_questions.sql` — Q8 section

**Result:**

| customer_id | revenue | top3_products_pct_of_revenue |
|---|---|---|
| 16446 | 168,469.60 | 100.00 |
| 12346 | 77,183.60 | 99.52 |
| 18102 | 32,975.92 | 5.42 |
| 15061 | 26,783.70 | 19.43 |
| 17949 | 24,046.20 | 22.03 |

**Interpretation:** On average, the top 3 products account for only **7.69%** of a top-20 customer's total spend. Dependency risk is low overall — most top customers are not concentrated on a handful of products, though a couple of individual outliers (100%, 99.52%) are worth reviewing separately since a single-product relationship carries more risk.

---

## Q9: Do at-risk customers show higher cancellation rates before disappearing?

**Query:** See `03_analysis_questions.sql` — Q9 section

**Result:**

| period | cancellations | total_transactions | cancellation_rate |
|---|---|---|---|
| past | 321 | 13,992 | 2.29 |
| recent | 52 | 1,125 | 4.62 |

**Interpretation:** Cancellation rate roughly doubled for at-risk customers, from 2.29% in the past period to 4.62% recently. This is a secondary supporting signal of dissatisfaction, though not the primary driver of churn (see Q5).

---

## Q10: What specific action per segment, and what revenue impact from retaining at-risk customers?

**Query:** N/A — synthesis question, no SQL. Full write-up in `Q10_final_summary.md`.

**Interpretation:** Recommended actions vary by segment (protect Champions, nurture New customers, direct outreach for At Risk given the ruled-out product/price causes, use Lost customers as a reference pattern). Retaining the 76 at-risk customers would **preserve** £263,559.73 (1.58% of total revenue) that would otherwise be lost — not new growth, but avoided loss. Including the fully-silent tier, total exposure reaches £1,084,450.39.

---

## Overall Conclusion

The analysis shows that revenue is highly concentrated among Champions and a small group of high-value customers. The largest business opportunity is not acquiring new customers, but protecting existing high-value relationships.

At-risk customers represent a measurable retention opportunity of £263,559.73, while fully silent customers highlight a larger historical revenue exposure of £820,890.66. Since product availability and pricing were ruled out as causes, retention efforts should focus on customer engagement, relationship management, and early churn detection.
