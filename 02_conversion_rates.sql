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
