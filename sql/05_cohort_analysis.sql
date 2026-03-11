SELECT 1;
/*
Temel Cohort Sorusu (Retention)
Bir müşteri ilk alışveriş yaptığı aydan sonra kaç ay aktif kalıyor?

Revenue Cohort
İlk alışveriş yapılan cohort zamanla ne kadar revenue üretiyor?
Bu LTV trend gösterir.

Order Frequency Cohort
Cohort zamanla daha sık mı alışveriş yapıyor, azalıyor mu?

İlk teknik adım :
Cohort analizi için şunları üretmemiz gerekiyor:

Her müşterinin first_purchase_month
Her işlemin transaction_month
Aradaki ay farkı → cohort_index

*/
--Step 1 — Müşteri İlk Alışveriş Ayı
WITH customer_first_purchase AS (
  SELECT
    customer_id,
    DATE_TRUNC(MIN(transaction_date), MONTH) AS cohort_month
  FROM `goit-exercises.GOITexercises.sales`
  WHERE customer_id IS NOT NULL
  GROUP BY 1
)

SELECT *
FROM customer_first_purchase
LIMIT 20;
------------------------------------------------------------------
--Kaç farklı cohort ayı var?
SELECT
  cohort_month,
  COUNT(*) AS customers
FROM (
  SELECT
    customer_id,
    DATE_TRUNC(MIN(transaction_date), MONTH) AS cohort_month
  FROM `goit-exercises.GOITexercises.sales`
  WHERE customer_id IS NOT NULL
  GROUP BY 1
)
GROUP BY 1
ORDER BY 1;
--------------------------------------------------------------------
WITH customer_first_purchase AS (
  SELECT
    customer_id,
    DATE_TRUNC(MIN(transaction_date), MONTH) AS cohort_month
  FROM `goit-exercises.GOITexercises.sales`
  WHERE customer_id IS NOT NULL
  GROUP BY 1
),

customer_activity AS (
  SELECT
    s.customer_id,
    DATE_TRUNC(s.transaction_date, MONTH) AS activity_month
  FROM `goit-exercises.GOITexercises.sales` s
  WHERE s.customer_id IS NOT NULL
),

cohort_data AS (
  SELECT
    cfp.customer_id,
    cfp.cohort_month,
    ca.activity_month,
    DATE_DIFF(ca.activity_month, cfp.cohort_month, MONTH) AS cohort_index
  FROM customer_first_purchase cfp
  JOIN customer_activity ca
    ON cfp.customer_id = ca.customer_id
)

SELECT
  cohort_month,
  cohort_index,
  COUNT(DISTINCT customer_id) AS active_customers
FROM cohort_data
GROUP BY 1,2
ORDER BY 1,2;
--------------------------------------------------------------------------------------
/*
Yorum :
Cohort analizi sonucunda 2019-01 cohort’unda 100, 2020-01 cohort’unda 53 müşteri bulunduğu görülmüştür.
Ancak her iki cohort’ta da tüm aylarda aktif müşteri sayısı cohort büyüklüğüne eşit kalmaktadır.
Bu durum retention’ın %100 göründüğünü ve veri setinin sentetik ya da eğitim amaçlı tasarlanmış olabileceğini düşündürmektedir.
*/
