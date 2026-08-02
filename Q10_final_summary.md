
Customer Segmentation Analysis — Executive Summary & Recommendations

Dataset: UCI Online Retail II (2009–2011) | Tools: PostgreSQL, pgAdmin


---

Business Question

> "Our online retail revenue has been inconsistent, and I'm worried we're losing good customers without noticing. I need to understand who our best customers are, who's at risk of leaving, and what we should actually do about it before next quarter."




---

Overall Business Context

Metric	Value

Total company revenue (analysis period)	£16,709,814.41
Total customer count	~5,864



---

1. Who Are Our Best Customers?

Customers were segmented using RFM analysis (Recency, Frequency, Monetary), each scored on a 1–5 scale. Three groups stand out as our top-tier customers, each valuable for a different reason:

Segment	Why They Matter	Key Metric

Champions	Score highest across all three RFM dimensions — recent, frequent, and high-spending. Our most reliable, highest-value relationship customers.	£11,930,519.42 — 68.41% of total revenue (1,299 customers)
Loyal Customers	Strong recency and frequency with solid spend — consistent, dependable revenue over time. Lower risk to retain than to replace.	£1,795,401.58 — 10.30% of total revenue (558 customers)
Big Spenders	High monetary value, though less frequent purchasing — significant revenue contributors in their own right.	£1,486,432.35 — 8.52% of total revenue (546 customers)
Top 20 Customers (by revenue)	The 20 highest-spending customers company-wide, regardless of purchase frequency. A concrete measure of revenue concentration.	£3,815,486.59 — 21.88% of total company revenue


Takeaway: Revenue is meaningfully concentrated in a small group of customers. Protecting Champions and Loyal customers — and closely monitoring the top-20 revenue group — should be a standing priority, not a one-time action.

Note: Champions is defined as the top 40% on each RFM dimension (scores 4–5), rather than the top 20% on each. Since recency, frequency, and spending are naturally correlated in real purchase behavior, this threshold captures a larger group (1,299 customers) than three independent 20% cutoffs would. The resulting revenue concentration (68.41% in Champions) is more pronounced than a typical 80/20 pattern, but consistent with known behavior in wholesale-leaning retail datasets like this one.


---

2. Who Is At Risk of Leaving?

At-risk customers were defined precisely as: customers who were high-value in an earlier period (top RFM scores) but whose activity collapsed in the most recent 3 months.

Metric	Value

At-risk customers identified	76
Revenue directly at stake	£263,559.73
% of total company revenue	1.58%
Fully silent customers (zero recent activity)	232 customers
Revenue tied to fully silent group	£820,890.66


Two distinct churn tiers were found:

Tier 1 — Collapsed but present: Dropped from dozens/hundreds of past orders to just 1 recent order. Still technically active — the more reachable group.

Tier 2 — Fully silent: No activity at all in the recent period. Higher-severity churn, harder to win back.


Root Cause Investigation

Before recommending action, the drop was tested against two supply-side explanations:

Product availability: At-risk customers' top past products were still being purchased by other customers in the recent period, suggesting they were not discontinued or unavailable. ✗ Not the cause.

Pricing: Average prices on those same products showed no meaningful change between the past and recent periods. ✗ Not the cause.

Cancellations: Cancellation rate for at-risk customers roughly doubled (2.29% → 4.62%) — a secondary warning signal, though not the primary driver.

Geography: Revenue declined broadly across nearly all countries (65–85%, including the UK at -75.30%), suggesting a broader market/customer behavior pattern rather than a problem isolated to one region.


Conclusion: This is genuine customer churn, not something explainable by our product catalog or pricing. The cause most likely lies outside this dataset — shifting customer needs, competitor activity, or external financial pressures.

Because the dataset contains transactional history but no customer feedback, marketing activity, or competitor data, the exact reason behind churn cannot be directly identified.


---

3. Recommended Actions by Segment

Segment	Recommended Action

Champions	Protect and reward — loyalty perks, early access, VIP treatment to prevent poaching by competitors.
Loyal Customers	Targeted marketing to increase frequency/spend and move them toward Champion status.
Potential Loyalist	Engagement campaigns to build purchase consistency and recency.
New	High-priority nurture group — strong onboarding, quality follow-up, and early incentives to convert them into Loyal/Champion customers.
Big Spenders	Offer premium/higher-value products; encourage more frequent purchasing.
Frequent Spenders	Encourage higher basket value through bundling or upsell offers.
Needs Attention	Immediate engagement — this segment is one step from becoming At Risk or Lost.
At Risk	Since the cause is external (not price/product), recommend direct outreach, customer feedback/surveys, and competitive analysis rather than catalog or pricing changes.
Lost	Not a recovery priority — instead, use as a reference pattern to identify early warning signs and prevent other segments from reaching this stage.


Note: "At Risk" in this table refers to the Q1 RFM segment (74 customers, single-snapshot definition). Section 2 above uses a more precise, separate "at risk" definition (76 customers) based on each customer's own past-vs-recent activity — used for the revenue impact figures below.


---

4. Revenue Impact of Retention

If at-risk customers are not retained and churn completely, the company stands to lose £263,559.73 — 1.58% of total revenue. Successful retention would preserve this revenue rather than generate new growth, making proactive outreach a cost-effective priority relative to the risk of losing it outright.

Including the fully silent tier, total revenue exposure across both churn groups reaches £1,084,450.39 — underscoring that retention efforts, even if only partially successful, could meaningfully protect existing revenue ahead of next quarter.


---

Summary

Our best customers (Champions, Loyal, and Top 20 by revenue) drive a disproportionate share of company revenue and should be actively protected. A clearly defined at-risk group — worth 1.58% of revenue, with an additional 820K+ in fully silent customer revenue — shows early signs of churn that our data confirms is not rooted in product or pricing issues. The highest-return action is not broad customer acquisition, but targeted retention of high-value customers before they become fully inactive.

Is this summary okay now
