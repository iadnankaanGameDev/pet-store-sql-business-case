SELECT 1;
/*
RFM:

R = Recency → müşteri en son ne zaman alışveriş yaptı?

F = Frequency → kaç işlem yaptı?

M = Monetary → toplam ne kadar harcadı?

Ama direkt segment yazmadan önce, Pareto’daki gibi bunu da parçalayıp kuracağız.
-----------------------------------------------------------------------

Adım 1 — Ham müşteri metriklerini

Önce her müşteri için şu 3 metriği çıkaracağız:
last_purchase_date
frequency
monetary

Soru : 
Sales tablosundan her müşteri için
son alışveriş tarihi,
farklı işlem sayısı,
toplam revenue
çıkarmak için aşağıdaki iskelette boş yerlere ne yazardın?

SELECT
  customer_id,
  ??? AS last_purchase_date,
  ??? AS frequency,
  ??? AS monetary
FROM `goit-exercises.GOITexercises.sales`
WHERE customer_id IS NOT NULL
GROUP BY 1
*/
SELECT
  customer_id,
  MAX(transaction_date) AS last_purchase_date,
  COUNT(DISTINCT transaction_id) AS frequency,
  ROUND(SUM(total_amount),2) AS monetary
FROM `goit-exercises.GOITexercises.sales`
WHERE customer_id IS NOT NULL
GROUP BY 1;

/*
Her müşteri için:
Son alışveriş tarihi
Kaç işlem yaptığı
Toplam harcaması

Ama RFM’in “R” kısmı tamamlanmadı.
Recency aslında:
Bugünden itibaren kaç gün geçmiş?
Yani last_purchase_date tek başına yetmez.

DATE_DIFF(CURRENT_DATE(), last_purchase_date, DAY) ile
“bugünden itibaren kaç gün geçti” hesaplıyoruz.
Çünkü RFM’de Recency şu soruya cevap verir:

Müşteri bize en son ne zaman para bıraktı?
Bu churn sinyalidir.
*/
---------------------------------------------------------------

WITH base AS (
  SELECT
    customer_id,
    MAX(transaction_date) AS last_purchase_date,
    COUNT(DISTINCT transaction_id) AS frequency,
    SUM(total_amount) AS monetary
  FROM `goit-exercises.GOITexercises.sales`
  WHERE customer_id IS NOT NULL
  GROUP BY 1
),

max_date AS (
  SELECT MAX(transaction_date) AS max_txn_date
  FROM `goit-exercises.GOITexercises.sales`
)

SELECT
  b.*,
  DATE_DIFF(m.max_txn_date, b.last_purchase_date, DAY) AS recency_days
FROM base b
CROSS JOIN max_date m;

/*
recency_days:

Bu metrik, müşterinin son alışverişinden itibaren kaç gün geçtiğini gösterir.
Dataset içindeki en güncel işlem tarihi referans alınarak hesaplanmıştır.

Interpretation:

- Küçük recency_days değeri → müşteri yakın zamanda alışveriş yapmış (aktif / sıcak müşteri)
- Büyük recency_days değeri → müşteri uzun süredir alışveriş yapmamış (soğuyan / churn riski)

Bu metrik RFM analizindeki "Recency" bileşenini temsil eder ve
müşterinin yeniden alışveriş yapma olasılığına dair sinyal üretir.
*/
--------------------------------------------------------------------------------
/*
Recency:

0 → en sıcak müşteri

1–5 → hala sıcak

30+ → soğumaya başlamış

90+ → riskli

Yani:

Recency küçükse müşteri daha değerlidir.
-------------------------------------------------------

Ama scoring’de dikkat:

Genelde RFM scoring şöyle yapılır:

Büyük değer = yüksek skor (5)

Küçük değer = düşük skor (1)
*/
--Ham RFM + skorlar
WITH base AS (
  SELECT
    customer_id,
    MAX(transaction_date) AS last_purchase_date,
    COUNT(DISTINCT transaction_id) AS frequency,
    SUM(total_amount) AS monetary
  FROM `goit-exercises.GOITexercises.sales`
  WHERE customer_id IS NOT NULL
  GROUP BY 1
),
max_date AS (
  SELECT
    MAX(transaction_date) AS max_txn_date
  FROM `goit-exercises.GOITexercises.sales`
),
rfm_base AS (
  SELECT
    b.customer_id,
    b.last_purchase_date,
    DATE_DIFF(m.max_txn_date, b.last_purchase_date, DAY) AS recency_days,
    b.frequency,
    b.monetary
  FROM base b
  CROSS JOIN max_date m
),
rfm_scores AS (
  SELECT
    *,
    NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score_raw,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
  FROM rfm_base
)
SELECT
  customer_id,
  recency_days,
  frequency,
  monetary,
  (6 - r_score_raw) AS r_score,
  f_score,
  m_score
FROM rfm_scores
ORDER BY monetary DESC;
-----------------------------------------------------------------
/*
RFM Scoring Logic

Amaç:
Müşterileri Recency, Frequency ve Monetary boyutlarında puanlayarak segmentlere ayırmak.

Metrikler:
- Recency: Müşterinin son alışverişinden itibaren geçen gün sayısı
- Frequency: Toplam farklı işlem sayısı
- Monetary: Toplam harcama tutarı

Scoring:
- Her metrik NTILE(5) ile 1–5 arasında puanlanır
- Frequency ve Monetary için yüksek değerler daha iyi kabul edilir
- Recency için ise düşük değerler daha iyi olduğu için skor ters çevrilir

rfm_code:
- R, F ve M skorları birleştirilerek üç haneli bir kod üretilir
- Örn: 545 = recency güçlü, frequency orta, monetary güçlü

Not:
Teknik olarak rfm_code üretilebilir; ancak business yorumlama ve raporlama için
müşterileri doğrudan segment isimleriyle etiketlemek daha açıklayıcıdır.
Bu nedenle son aşamada CASE WHEN ile mantıksal segment mapping yapılacaktır.

-------------------------------------------------------------

Mapping Tasarımı : rule-based mapping

r>=4 and f>=4 and m>=4 → Champions

r>=3 and f>=3 and m>=3 → Loyal

r<=2 and f>=3 and m>=3 → At Risk

r<=2 and f<=2 and m<=2 → Lost

diğerleri → Potential Loyalists

-----------------------------------------------------------

RFM Segment Mapping Design

Bu segment yapısı rule-based olarak tasarlanmıştır.
Amaç, teknik RFM skorlarını business açısından anlaşılır müşteri segmentlerine çevirmektir.

Not:
RFM segmentleri her veri seti için sabit değildir.
Gerçek projelerde segment eşikleri şu yöntemlerle belirlenebilir:

1. Quantile / percentile tabanlı eşikler
2. Weighted RFM score yaklaşımı
3. Clustering (ör. KMeans) ile doğal müşteri kümeleri
4. Churn / conversion hedeflerine göre supervised modeling

Bu çalışmada açıklanabilirlik ve öğrenme amacı nedeniyle
NTILE(5) + CASE WHEN tabanlı yorumlanabilir bir segment tasarımı tercih edilmiştir.

*/
WITH base AS (
  SELECT
    customer_id,
    MAX(transaction_date) AS last_purchase_date,
    COUNT(DISTINCT transaction_id) AS frequency,
    SUM(total_amount) AS monetary
  FROM `goit-exercises.GOITexercises.sales`
  WHERE customer_id IS NOT NULL
  GROUP BY 1
),
max_date AS (
  SELECT
    MAX(transaction_date) AS max_txn_date
  FROM `goit-exercises.GOITexercises.sales`
),
rfm_base AS (
  SELECT
    b.customer_id,
    b.last_purchase_date,
    DATE_DIFF(m.max_txn_date, b.last_purchase_date, DAY) AS recency_days,
    b.frequency,
    b.monetary
  FROM base b
  CROSS JOIN max_date m
),
rfm_scores_raw AS (
  SELECT
    *,
    NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score_raw,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
  FROM rfm_base
),
rfm_scores AS (
  SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    (6 - r_score_raw) AS r_score,
    f_score,
    m_score
  FROM rfm_scores_raw
)
SELECT
  *,
  CONCAT(
    CAST(r_score AS STRING),
    CAST(f_score AS STRING),
    CAST(m_score AS STRING)
  ) AS rfm_code,
  CASE
    WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
    WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal'
    WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk'
    WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
    ELSE 'Potential Loyalists'
  END AS segment_name
FROM rfm_scores
ORDER BY monetary DESC;
-------------------------------------------------------------------------------------

/*
Şu an elimizde ne var?

Her müşteri için:

recency_days
frequency
monetary
r_score
f_score
m_score
rfm_code

Bu ne demek?
445 → Recency iyi, Frequency iyi, Monetary çok iyi
245 → Recency zayıf, Frequency iyi, Monetary çok iyi
Yani bazı yüksek gelirli müşteriler bile recency’de düşmüş olabilir → bu “At Risk High Value” sinyali olabilir.
------------------------------------------------------------------------------
Şimdi şu soruyu cevaplayalım:

Hangi segment revenue’nun büyük kısmını getiriyor?
*/
-----------------------------------------------------------------
WITH base AS (
  SELECT
    customer_id,
    MAX(transaction_date) AS last_purchase_date,
    COUNT(DISTINCT transaction_id) AS frequency,
    SUM(total_amount) AS monetary
  FROM `goit-exercises.GOITexercises.sales`
  WHERE customer_id IS NOT NULL
  GROUP BY 1
),
max_date AS (
  SELECT
    MAX(transaction_date) AS max_txn_date
  FROM `goit-exercises.GOITexercises.sales`
),
rfm_base AS (
  SELECT
    b.customer_id,
    DATE_DIFF(m.max_txn_date, b.last_purchase_date, DAY) AS recency_days,
    b.frequency,
    b.monetary
  FROM base b
  CROSS JOIN max_date m
),
rfm_scores_raw AS (
  SELECT
    *,
    NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score_raw,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
  FROM rfm_base
),
rfm_final AS (
  SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    (6 - r_score_raw) AS r_score,
    f_score,
    m_score,
    CONCAT(
      CAST((6 - r_score_raw) AS STRING),
      CAST(f_score AS STRING),
      CAST(m_score AS STRING)
    ) AS rfm_code,
    CASE
      WHEN (6 - r_score_raw) >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
      WHEN (6 - r_score_raw) >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal'
      WHEN (6 - r_score_raw) <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk'
      WHEN (6 - r_score_raw) <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
      ELSE 'Potential Loyalists'
    END AS segment_name
  FROM rfm_scores_raw
)

SELECT
  segment_name,
  COUNT(*) AS customers,
  SUM(monetary) AS total_revenue,
  ROUND(AVG(monetary), 2) AS avg_customer_value,
  ROUND(AVG(frequency), 2) AS avg_frequency,
  ROUND(AVG(recency_days), 2) AS avg_recency
FROM rfm_final
GROUP BY 1
ORDER BY total_revenue DESC;
-------------------------------------------------------------------------------------------
/*
Analiz :
Revenue Concentration

Champions: 20 müşteri ~25M revenue

Toplam revenue yaklaşık 37M civarı.

Yani: Revenue’nin yaklaşık %67’si sadece 20 müşteriden geliyor.
-----------------------------------------------------------------
Champions Profili :

Recency = 0 → aşırı aktif  Frequency yüksek  Monetary çok yüksek

Yani:

Hem sık alıyorlar
Hem pahalı alıyorlar
Hem şu an aktifler

Bu segmenti kaybetmek şirket için büyük risk.
-----------------------------------------------------------------
At Risk Segment Çok Kritik :

5 müşteri ama: 2.2M revenue Avg value 446K
Recency 4 (diğerlerine göre daha yüksek)

Bu ne demek?
Yüksek değerli ama soğumaya başlayan müşteriler var.
Bu CRM aksiyonu gerektirir.
-----------------------------------------------------------------
Loyal Segment İlginç :

28 müşteri
Avg frequency çok yüksek (1291)
Ama avg revenue düşük (37K)

Demek ki:
Çok sık ama küçük sepetli alım yapıyorlar.
Bu “upsell fırsatı” olabilir.
-----------------------------------------------------------------
Lost Segment :

Küçük revenue
Küçük avg value
Recency yüksek
-----------------------------------------------------------------
*/










