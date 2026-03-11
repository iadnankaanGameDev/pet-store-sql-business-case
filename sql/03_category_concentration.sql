SELECT 1;
/*
-------------------------------------------------------
CATEGORY CONCENTRATION ANALİZİ
-------------------------------------------------------

Amaç:
Revenue’nun kategori bazında ne kadar yoğunlaştığını ölçmek
ve stratejik bağımlılık riskini değerlendirmek.

Bu analiz şu soruya cevap verir:
Revenue birkaç kategoriye mi bağımlı?

-------------------------------------------------------
*/

-- 1) Kategori bazında revenue dağılımı
WITH category_rev AS (
  SELECT
    p.category_name,
    SUM(s.total_amount) AS revenue
  FROM `goit-exercises.GOITExercises.sales` s
  JOIN `goit-exercises.GOITExercises.products` p
    ON s.product_id = p.product_id
  GROUP BY 1
),

shares AS (
  SELECT
    category_name,
    revenue,
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

-------------------------------------------------------

-- 2) Herfindahl-Hirschman Index (HHI) hesaplama
WITH category_rev AS (
  SELECT
    p.category_name,
    SUM(s.total_amount) AS revenue
  FROM `goit-exercises.GOITExercises.sales` s
  JOIN `goit-exercises.GOITExercises.products` p
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
ANALİZ YORUMU:

Kategori revenue dağılımı yaklaşık olarak:

Vaccine      → %40+
Care         → %30+
Supplement   → %20 civarı
Accessories  → %7 civarı

Top 2 kategori toplam revenue’nun yaklaşık %73’ünü oluşturmaktadır.

Herfindahl-Hirschman Index (HHI) ≈ 0.31

HHI > 0.25 olduğu için kategori bazında yüksek revenue yoğunlaşması vardır.

Yorum:
Revenue ürün bazlı değil, daha çok kategori bazlı yoğunlaşmıştır.
Özellikle Vaccine ve Care kategorileri business için kritik öneme sahiptir.

Stratejik Risk:
Bu kategorilerde yaşanacak regülasyon, talep düşüşü veya rekabet artışı
toplam revenue’yu ciddi şekilde etkileyebilir.

Öneri:
- Kategori portföy çeşitlendirmesi
- Düşük paylı kategorilerde büyüme stratejisi
- Kritik kategoriler için risk azaltma planı
*/
