--Satışlarda duplicate transaction_id var mı?
SELECT
  transaction_id,
  COUNT(*) AS cnt
FROM `goit-exercises.GOITexercises.sales`
GROUP BY 1
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

----------------------------------------------------------

--Null / eksik join anahtarları var mı?
SELECT
  COUNTIF(customer_id IS NULL) AS null_customer_id,
  COUNTIF(product_id IS NULL)  AS null_product_id
FROM `goit-exercises.GOITexercises.sales`;

-----------------------------------------------------------

--Gelir (Revenue) ve sipariş (Order) trendi (MoM) + büyüme
WITH m AS (
  SELECT
    DATE_TRUNC(transaction_date, MONTH) AS month,
    COUNT(DISTINCT transaction_id) AS orders,
    SUM(total_amount) AS revenue
  FROM `goit-exercises.GOITexercises.sales`
  GROUP BY 1
)
SELECT
  month,
  orders,
  revenue,
  LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
  SAFE_DIVIDE(revenue - LAG(revenue) OVER (ORDER BY month),
              LAG(revenue) OVER (ORDER BY month)) AS revenue_mom_growth
FROM m
ORDER BY month;

--------------------------------------------------------------------------

--AOV (Average Order Value) + müşteri başı gelir (ARPC)

WITH base AS (
  SELECT
    transaction_id,
    customer_id,
    total_amount
  FROM `goit-exercises.GOITexercises.sales`
)
SELECT
  AVG(order_total) AS aov,
  AVG(customer_revenue) AS arpc
FROM (
  SELECT
    transaction_id,
    SUM(total_amount) AS order_total,
    NULL AS customer_revenue
  FROM base
  GROUP BY 1

  UNION ALL

  SELECT
    NULL AS transaction_id,
    NULL AS order_total,
    SUM(total_amount) AS customer_revenue
  FROM base
  GROUP BY customer_id
);

----------------------------------------------------------------------

--VIP vs Non-VIP: gelir, sipariş, AOV kıyas
WITH joined AS (
  SELECT
    c.vip_customer_flag,
    s.transaction_id,
    s.total_amount
  FROM `goit-exercises.GOITexercises.sales` s
  JOIN `goit-exercises.GOITexercises.customers` c
  USING (customer_id)
),
per_order AS (
  SELECT
    vip_customer_flag,
    transaction_id,
    SUM(total_amount) AS order_total
  FROM joined
  GROUP BY 1,2
)
SELECT
  vip_customer_flag,
  COUNT(DISTINCT transaction_id) AS orders,
  SUM(order_total) AS revenue,
  AVG(order_total) AS aov
FROM per_order
GROUP BY 1
ORDER BY revenue DESC;

---------------------------------------------------------

--Ürün kârlılık proxy’si: “liste fiyatı” ile karşılaştırma (discount etkisi)
WITH sales_items AS (
  SELECT
    s.product_id,
    SUM(s.quantity) AS units,
    SUM(s.total_amount) AS revenue
  FROM `goit-exercises.GOITexercises.sales` s
  GROUP BY 1
),
prod AS (
  SELECT
    product_id,
    product_name,
    category_name,
    retail_price,
    wholesale_discount_percentage,
    -- proxy: wholesale cost = retail_price * (1 - discount%)
    retail_price * (1 - wholesale_discount_percentage / 100.0) AS wholesale_cost_proxy
  FROM `goit-exercises.GOITexercises.products`
)
SELECT
  p.category_name,
  p.product_id,
  p.product_name,
  si.units,
  si.revenue,
  -- proxy gross profit
  (si.revenue - si.units * p.wholesale_cost_proxy) AS gross_profit_proxy,
  SAFE_DIVIDE((si.revenue - si.units * p.wholesale_cost_proxy), si.revenue) AS gross_margin_proxy
FROM sales_items si
JOIN prod p USING (product_id)
ORDER BY gross_profit_proxy DESC;

-------------------------------------------------------------------------------------------------

--Pareto (80/20): gelirin %80’i hangi ürünlerden geliyor?
WITH prod_rev AS (
  SELECT
    s.product_id,
    SUM(s.total_amount) AS revenue
  FROM `goit-exercises.GOITexercises.sales` s
  GROUP BY 1
),
ranked AS (
  SELECT
    product_id,
    revenue,
    SUM(revenue) OVER () AS total_revenue,
    SUM(revenue) OVER (ORDER BY revenue DESC) AS cum_revenue
  FROM prod_rev
)
SELECT
  product_id,
  revenue,
  SAFE_DIVIDE(cum_revenue, total_revenue) AS cum_share
FROM ranked
WHERE SAFE_DIVIDE(cum_revenue, total_revenue) <= 0.80
ORDER BY revenue DESC;

------------------------------------------------------------------

--Cohort analizi: ilk alışveriş ayına göre retention (müşteri geri dönüşü)
WITH first_purchase AS (
  SELECT
    customer_id,
    DATE_TRUNC(MIN(transaction_date), MONTH) AS cohort_month
  FROM `goit-exercises.GOITexercises.sales`
  GROUP BY 1
),
activity AS (
  SELECT
    s.customer_id,
    fp.cohort_month,
    DATE_TRUNC(s.transaction_date, MONTH) AS activity_month
  FROM `goit-exercises.GOITexercises.sales` s
  JOIN first_purchase fp USING (customer_id)
  GROUP BY 1,2,3
),
cohort AS (
  SELECT
    cohort_month,
    DATE_DIFF(activity_month, cohort_month, MONTH) AS month_n,
    COUNT(DISTINCT customer_id) AS active_customers
  FROM activity
  GROUP BY 1,2
),
cohort_size AS (
  SELECT
    cohort_month,
    COUNT(DISTINCT customer_id) AS cohort_customers
  FROM first_purchase
  GROUP BY 1
)
SELECT
  c.cohort_month,
  c.month_n,
  c.active_customers,
  cs.cohort_customers,
  SAFE_DIVIDE(c.active_customers, cs.cohort_customers) AS retention_rate
FROM cohort c
JOIN cohort_size cs USING (cohort_month)
ORDER BY cohort_month, month_n;

-----------------------------------------------------------------------------

--RFM segmentasyonu (ileri ama çok öğretici)
WITH base AS (
  SELECT
    customer_id,
    MAX(transaction_date) AS last_purchase_date,
    COUNT(DISTINCT transaction_id) AS frequency,
    SUM(total_amount) AS monetary
  FROM `goit-exercises.GOITexercises.sales`
  GROUP BY 1
),
scored AS (
  SELECT
    customer_id,
    DATE_DIFF(CURRENT_DATE(), last_purchase_date, DAY) AS recency_days,
    frequency,
    monetary,
    NTILE(5) OVER (ORDER BY DATE_DIFF(CURRENT_DATE(), last_purchase_date, DAY) DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency) AS f_score,
    NTILE(5) OVER (ORDER BY monetary) AS m_score
  FROM base
)
SELECT
  *,
  CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) AS rfm_code
FROM scored
ORDER BY monetary DESC;

------------------------------------------------------------------------------------------------

--RFM segmentasyonu (ileri ama çok öğretici)
WITH base AS (
  SELECT
    customer_id,
    MAX(transaction_date) AS last_purchase_date,
    COUNT(DISTINCT transaction_id) AS frequency,
    SUM(total_amount) AS monetary
  FROM `goit-exercises.GOITexercises.sales`
  GROUP BY 1
),
scored AS (
  SELECT
    customer_id,
    DATE_DIFF(CURRENT_DATE(), last_purchase_date, DAY) AS recency_days,
    frequency,
    monetary,
    NTILE(5) OVER (ORDER BY DATE_DIFF(CURRENT_DATE(), last_purchase_date, DAY) DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency) AS f_score,
    NTILE(5) OVER (ORDER BY monetary) AS m_score
  FROM base
)
SELECT
  *,
  CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) AS rfm_code
FROM scored
ORDER BY monetary DESC;
---------------------------------------------------------------------------------------------------

--Sepet analizi (market basket): birlikte alınan ürün çiftleri
WITH items AS (
  SELECT DISTINCT transaction_id, product_id
  FROM `goit-exercises.GOITexercises.sales`
),
pairs AS (
  SELECT
    a.product_id AS product_a,
    b.product_id AS product_b,
    COUNT(*) AS pair_orders
  FROM items a
  JOIN items b
    ON a.transaction_id = b.transaction_id
   AND a.product_id < b.product_id
  GROUP BY 1,2
)
SELECT
  pa.product_name AS product_a_name,
  pb.product_name AS product_b_name,
  pair_orders
FROM pairs
JOIN `goit-exercises.GOITexercises.products` pa ON pa.product_id = pairs.product_a
JOIN `goit-exercises.GOITexercises.products` pb ON pb.product_id = pairs.product_b
ORDER BY pair_orders DESC
LIMIT 50;

-------------------------------------------------------------------------------------

--Anomali: “müşteri bazında normalin üstünde harcama” tespiti (z-score)
WITH per_customer AS (
  SELECT
    customer_id,
    SUM(total_amount) AS revenue
  FROM `goit-exercises.GOITexercises.sales`
  GROUP BY 1
),
stats AS (
  SELECT
    AVG(revenue) AS mean_rev,
    STDDEV_POP(revenue) AS std_rev
  FROM per_customer
)
SELECT
  pc.customer_id,
  pc.revenue,
  SAFE_DIVIDE(pc.revenue - s.mean_rev, s.std_rev) AS z_score
FROM per_customer pc
CROSS JOIN stats s
WHERE SAFE_DIVIDE(pc.revenue - s.mean_rev, s.std_rev) >= 3
ORDER BY z_score DESC;

---------------------------------------------------------------------------

--“Fiyat değişimi / discount” kategoride satışa nasıl yansımış? (kategori kırılım)
WITH enriched AS (
  SELECT
    p.category_name,
    p.wholesale_discount_percentage AS discount_pct,
    s.total_amount,
    s.quantity
  FROM `goit-exercises.GOITexercises.sales` s
  JOIN `goit-exercises.GOITexercises.products` p USING (product_id)
)
SELECT
  category_name,
  discount_pct,
  SUM(quantity) AS units,
  SUM(total_amount) AS revenue,
  SAFE_DIVIDE(SUM(total_amount), SUM(quantity)) AS avg_price_per_unit
FROM enriched
GROUP BY 1,2
ORDER BY category_name, discount_pct;

--------------------------------------------------------------------------------
