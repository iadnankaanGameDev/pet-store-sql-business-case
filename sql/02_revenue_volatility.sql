SELECT 1;
/*
-------------------------------------------------------
REVENUE VOLATILITY ANALİZİ (ÜRÜN BAZLI)
-------------------------------------------------------

Amaç:
Revenue’nun ürün bazında ne kadar yoğunlaştığını ölçmek
ve business’ın birkaç ürüne bağımlı olup olmadığını analiz etmek.

Bu analiz şu sorulara cevap verir:
- Revenue birkaç ürüne mi bağımlı?
- Toplam revenue’nun %80’i kaç üründen geliyor?
- En yüksek revenue üreten ürünlerde risk var mı?

-------------------------------------------------------
*/

-- 1) Ürün bazında toplam revenue
WITH product_rev AS (
  SELECT
    product_id,
    SUM(total_amount) AS revenue
  FROM `goit-exercises.GOITExercises.sales`
  GROUP BY 1
)

SELECT
  product_id,
  revenue
FROM product_rev
ORDER BY revenue DESC;

-------------------------------------------------------

-- 2) Revenue share ve kümülatif pay
WITH product_rev AS (
  SELECT
    product_id,
    SUM(total_amount) AS revenue
  FROM `goit-exercises.GOITExercises.sales`
  GROUP BY 1
),

shares AS (
  SELECT
    product_id,
    revenue,
    SAFE_DIVIDE(revenue, SUM(revenue) OVER()) AS revenue_share
  FROM product_rev
),

cum_shares AS (
  SELECT
    *,
    SUM(revenue_share) OVER (ORDER BY revenue DESC) AS cum_revenue_share
  FROM shares
)

SELECT *
FROM cum_shares
ORDER BY revenue DESC;

-------------------------------------------------------

-- 3) Toplam revenue’nun %80’i kaç üründen geliyor?
WITH product_rev AS (
  SELECT
    product_id,
    SUM(total_amount) AS revenue
  FROM `goit-exercises.GOITExercises.sales`
  GROUP BY 1
),

shares AS (
  SELECT
    product_id,
    revenue,
    SAFE_DIVIDE(revenue, SUM(revenue) OVER()) AS revenue_share
  FROM product_rev
),

cum_shares AS (
  SELECT
    *,
    SUM(revenue_share) OVER (ORDER BY revenue DESC) AS cum_revenue_share,
    ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rn
  FROM shares
)

SELECT
  COUNT(*) AS revenue_80_icin_gereken_urun_sayisi,
  MAX(cum_revenue_share) AS ulasilan_oran
FROM cum_shares
WHERE cum_revenue_share <= 0.80;

-------------------------------------------------------

-- 4) Ürün adı ve kategori ile detaylı görünüm
WITH product_rev AS (
  SELECT
    s.product_id,
    p.product_name,
    p.category_name,
    SUM(s.total_amount) AS revenue
  FROM `goit-exercises.GOITExercises.sales` s
  JOIN `goit-exercises.GOITExercises.products` p
    ON s.product_id = p.product_id
  GROUP BY 1,2,3
),

shares AS (
  SELECT
    *,
    SAFE_DIVIDE(revenue, SUM(revenue) OVER()) AS revenue_share
  FROM product_rev
),

cum_shares AS (
  SELECT
    *,
    SUM(revenue_share) OVER (ORDER BY revenue DESC) AS cum_revenue_share,
    ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rn
  FROM shares
)

SELECT
  product_id,
  product_name,
  category_name,
  revenue,
  ROUND(revenue_share,4) AS revenue_share,
  ROUND(cum_revenue_share,4) AS cum_revenue_share,
  rn
FROM cum_shares
ORDER BY revenue DESC;

/*
ANALİZ YORUMU:

Top 3 ürün toplam revenue’nun yaklaşık %54’ünü oluşturmaktadır.
Top 10 ürün toplam revenue’nun yaklaşık %80’ini üretmektedir.

Bu yapı orta-yüksek seviyede ürün bağımlılığına işaret eder.

Risk Senaryosu:
En yüksek revenue payına sahip ürünlerde yaşanacak talep düşüşü,
stok sorunu veya rekabet artışı toplam revenue üzerinde
orantısız etki yaratabilir.

Öneri:
- Ürün portföyünün çeşitlendirilmesi
- Yüksek revenue üreten ürünlerde stok güvenliği
- Alternatif ürün geliştirme stratejisi
*/
