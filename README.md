# E-Commerce-Funnel-Analysis

## Overview

This project analyzes user behavior across an e-commerce platform to understand how customers move through the purchase funnel. The analysis focuses on the **last 30 days of activity** (Jan 4 – Feb 3, 2026) and covers three key areas: funnel stage volumes, step-by-step conversion rates, and funnel performance broken down by traffic source.

The goal is to identify where users drop off and which acquisition channels drive the most efficient conversions.

---

## Tools & Platform

- **Google BigQuery** — querying and analysis
- **SQL (GoogleSQL dialect)** — all logic written in standard SQL with CTEs

---

## Dataset

The dataset contains raw user event logs from an e-commerce platform.

| Column | Description |
|---|---|
| `event_id` | Unique identifier for each event |
| `user_id` | Unique identifier for each user |
| `event_type` | The action taken (page_view, add_to_cart, checkout_start, payment_info, purchase) |
| `event_date` | Timestamp of the event |
| `product_id` | Product associated with the event |
| `amount` | Transaction amount (populated on purchase events) |
| `traffic_source` | Channel that brought the user (organic, paid_ads, social, email) |

**Total records:** 9,381 events  
**Date range:** Dec 30, 2025 – Feb 3, 2026  
**Analysis window:** Last 30 days (Jan 4 – Feb 3, 2026)

---

## Funnel Definition

The purchase funnel is defined as five sequential stages:

```
Page View → Add to Cart → Checkout Start → Payment Info → Purchase
```

Each stage is measured by **distinct users**, not total events — so a user who views a page multiple times is counted once.

> **Note on date logic:** Queries use `2026-02-03` as the anchor date (the last date in the dataset) rather than `CURRENT_DATE()`, since this is a historical dataset. The 30-day window is calculated by subtracting 30 days from that anchor.

---

## Analysis 1: Funnel Stage Volumes

Counts distinct users who reached each stage of the funnel within the last 30 days.

```sql
WITH funnel_stages AS (
    SELECT 
        COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS stage_1_view,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS stage_2_cart,
        COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage_3_checkout,
        COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS stage_4_payment,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS stage_5_purchase
    FROM `stoked-dominion-474315-t1.SqlPractice.SqlPractice`
    WHERE event_date >= TIMESTAMP(DATE_SUB(('2026-02-03'), INTERVAL '30' DAY))
)
SELECT * FROM funnel_stages
```

**Results:**

| Stage | Users |
|---|---|
| Page View | 4,291 |
| Add to Cart | 1,338 |
| Checkout Start | 954 |
| Payment Info | 770 |
| Purchase | 709 |

---

## Analysis 2: Conversion Rate Through the Funnel

Extends the funnel CTE to calculate step-by-step drop-off rates and the overall end-to-end conversion rate.

```sql
WITH funnel_stages AS (
    SELECT 
        COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS stage_1_view,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS stage_2_cart,
        COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage_3_checkout,
        COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS stage_4_payment,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS stage_5_purchase
    FROM `stoked-dominion-474315-t1.SqlPractice.SqlPractice`
    WHERE event_date >= TIMESTAMP(DATE_SUB(('2026-02-03'), INTERVAL '30' DAY))
)
SELECT 
    stage_1_view,
    stage_2_cart,
    ROUND(stage_2_cart * 100 / stage_1_view) AS view_to_cart_rate,
    stage_3_checkout,
    ROUND(stage_3_checkout * 100 / stage_2_cart) AS cart_to_checkout_rate,
    stage_4_payment,
    ROUND(stage_4_payment * 100 / stage_3_checkout) AS checkout_to_payment_rate,
    stage_5_purchase,
    ROUND(stage_5_purchase * 100 / stage_4_payment) AS payment_to_purchase_rate,
    ROUND(stage_5_purchase * 100 / stage_1_view) AS overall_rate
FROM funnel_stages
```

**Results:**

| Transition | Conversion Rate |
|---|---|
| View → Cart | 31% |
| Cart → Checkout | 71% |
| Checkout → Payment | 81% |
| Payment → Purchase | 92% |
| **Overall (View → Purchase)** | **17%** |

**Key finding:** The biggest drop-off happens at the very first step — only 31% of users who view a product add it to their cart. Once a user starts checkout, they are very likely to complete the purchase (92% make it from payment info to purchase). This suggests the friction point is in **product discovery and initial interest**, not in the checkout experience itself.

---

## Analysis 3: Funnel by Traffic Source

Breaks down funnel performance by acquisition channel to identify which sources drive the most efficient conversions.

```sql
WITH source_funnel AS (
    SELECT 
        traffic_source,
        COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS views,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS carts,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchases
    FROM `stoked-dominion-474315-t1.SqlPractice.SqlPractice`
    WHERE event_date >= TIMESTAMP(DATE_SUB(('2026-02-03'), INTERVAL '30' DAY))
    GROUP BY traffic_source
)
SELECT 
    traffic_source,
    views,
    carts,
    purchases,
    ROUND(carts * 100 / views) AS cart_conversion_rate,
    ROUND(purchases * 100 / views) AS purchase_conversion_rate,
    ROUND(purchases * 100 / carts) AS cart_to_purchase_conversion_rate
FROM source_funnel
ORDER BY purchases DESC
```

**Results:**

| Source | Views | Carts | Purchases | Cart Rate | Purchase Rate | Cart → Purchase |
|---|---|---|---|---|---|---|
| Organic | 1,757 | 578 | 300 | 33% | 17% | 52% |
| Paid Ads | 824 | 306 | 173 | 37% | 21% | 57% |
| Email | 449 | 283 | 152 | 63% | 34% | 54% |
| Social | 1,261 | 171 | 84 | 14% | 7% | 49% |

**Key findings:**
- **Email** is the highest-converting channel by far — 63% of email users add to cart and 34% make a purchase, despite having the smallest audience. Email users arrive with clear intent.
- **Paid Ads** delivers strong efficiency — 21% purchase rate, better than organic despite fewer views.
- **Social** brings in significant traffic (second-highest views) but converts very poorly — only 7% of social visitors make a purchase. This channel may need creative or targeting review.
- **Organic** is the volume leader for purchases in absolute numbers (300) but performs at average rates, suggesting room to improve product page quality or SEO targeting.

---

## How to Reproduce

1. Load the dataset into a BigQuery project
2. Update the project and table reference in each query: `your-project.your_dataset.your_table`
3. Run queries in the order listed above (Analysis 1 → 2 → 3)
4. The anchor date (`2026-02-03`) can be replaced with `CURRENT_DATE()` if working with a live dataset
