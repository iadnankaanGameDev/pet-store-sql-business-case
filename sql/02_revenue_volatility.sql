select 1;
/*
Revenue volatility ürün bazında yapılır ve şuna cevap verir:

Revenue birkaç ürüne mi bağımlı?
*/
--Adım 1 – Ürün bazında revenue
WITH product_rev AS (
  SELECT
    product_id,
    SUM(total_amount) AS revenue
  FROM `goit-exercises.GOITexercises.sales`
  GROUP BY 1
)

SELECT
  product_id,
  revenue
FROM product_rev
ORDER BY revenue DESC;
-----------------------------------------------------------
--Adım 2 – Revenue share ve cumulative share
WITH product_rev AS (
  SELECT
    product_id,
    SUM(total_amount) AS revenue
  FROM `goit-exercises.GOITexercises.sales`
  GROUP BY 1
),
shares AS (
  SELECT
    product_id,
    revenue,
    SUM(revenue) OVER() AS total_revenue,
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

/*
Revenue oldukça concentrated.

Top 3 ürün → %54
Top 5 ürün → %63
Top 8 ürün → %73

Bu yüksek dependency demektir.
*/
------------------------------------------------------------------------
WITH product_rev AS (
  SELECT
    product_id,
    SUM(total_amount) AS revenue
  FROM `goit-exercises.GOITexercises.sales`
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
  COUNT(*) AS products_needed_for_80pct,
  MAX(cum_revenue_share) AS reached_share
FROM cum_shares
WHERE cum_revenue_share <= 0.80;

/*
Revenue volatility analizi sonucu:

Top 10 ürün toplam revenue’nun %80’ini oluşturmaktadır.
Top 3 ürün ise tek başına %54 revenue üretmektedir.

Bu yapı orta seviyede product concentration riskine işaret eder.

Risk senaryosu:
Top 3 üründen birinde tedarik sorunu yaşanması durumunda
toplam revenue’da ciddi düşüş gözlemlenebilir.

Bu nedenle:
- Ürün portföy çeşitlendirmesi
- Alternatif ürün geliştirme
- High revenue ürünler için stok güvenliği
önerilmektedir.
*/
-------------------------------------------------------------------------------
--Güncellenmiş Revenue Volatility Sorgusu (Join’li)

-----------------------------------------------------------------
WITH product_rev AS (
  SELECT
    s.product_id,
    p.product_name,
    p.category_name,
    SUM(s.total_amount) AS revenue
  FROM `goit-exercises.GOITexercises.sales` s
  JOIN `goit-exercises.GOITexercises.products` p
    ON s.product_id = p.product_id
  GROUP BY 1,2,3
),

shares AS (
  SELECT
    *,
    SUM(revenue) OVER() AS total_revenue,
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
Revenue volatility analizi sonucu:

Top 3 ürün toplam revenue’nun %54’ünü oluşturmaktadır.
En büyük ürün (Dog Vaccination Package) tek başına %20.5 revenue üretmektedir.

What-if senaryo:
Bu ürün satışlarında %15 düşüş olması durumunda
toplam revenue yaklaşık %3 düşecektir.

Bu nedenle yüksek revenue payına sahip ürünler için
stok, fiyat ve talep yönetimi kritik önemdedir.

*/
----------------------------------------------------------------------------------
/*
Daha riskli olan hangisi?

A) Revenue birkaç ürüne bağımlı olması
B) Revenue birkaç kategoriye bağımlı olması

Yani product concentration mı
yoksa category concentration mı daha kritik?
*/
--Category Revenue Distribution
WITH category_rev AS (
  SELECT
    p.category_name,
    SUM(s.total_amount) AS revenue
  FROM `goit-exercises.GOITexercises.sales` s
  JOIN `goit-exercises.GOITexercises.products` p
    ON s.product_id = p.product_id
  GROUP BY 1
),

shares AS (
  SELECT
    category_name,
    revenue,
    SUM(revenue) OVER() AS total_revenue,
    SAFE_DIVIDE(revenue, SUM(revenue) OVER()) AS revenue_share
  FROM category_rev
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
-------------------------------------------------------------------------------
--Daha Akademik Ölçüm (Herfindahl Index)
WITH category_rev AS (
  SELECT
    p.category_name,
    SUM(s.total_amount) AS revenue
  FROM `goit-exercises.GOITexercises.sales` s
  JOIN `goit-exercises.GOITexercises.products` p
    ON s.product_id = p.product_id
  GROUP BY 1
),

shares AS (
  SELECT
    SAFE_DIVIDE(revenue, SUM(revenue) OVER()) AS revenue_share
  FROM category_rev
)

SELECT
  SUM(POWER(revenue_share,2)) AS hhi_index
FROM shares;

/*
CATEGORY CONCENTRATION ANALYSIS

Category revenue dağılımı:

Vaccine      → %40.5
Care         → %32.7
Supplement   → %19.6
Accessories  → %7.2

Top 2 kategori toplam revenue’nun %73’ünü oluşturmaktadır.

Herfindahl-Hirschman Index (HHI) = 0.314

HHI > 0.25 olduğundan, kategori bazında yüksek revenue concentration
bulunmaktadır.

Yorum:

Revenue birkaç kategoriye bağımlıdır.
Özellikle Vaccine ve Care kategorileri business için kritik öneme sahiptir.

Stratejik risk:

Bu kategorilerde talep düşüşü, regülasyon değişikliği veya
rekabet artışı olması durumunda toplam revenue ciddi şekilde etkilenebilir.

Öneri:

- Kategori portföy çeşitlendirmesi
- Düşük paylı kategorilerde (Accessories gibi) büyüme stratejisi
- Yüksek paylı kategoriler için risk azaltma planı
*/

----------------------------------------------------------------------------------




