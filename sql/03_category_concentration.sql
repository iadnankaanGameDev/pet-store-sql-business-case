SELECT 1;
/*
-------------------------------------------------------
CATEGORY CONCENTRATION ANALYSIS
-------------------------------------------------------

Objective:
Measure revenue dependency at category level and evaluate
strategic concentration risk.

-------------------------------------------------------
*/

-- Category revenue distribution
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

-------------------------------------------------------

-- Herfindahl-Hirschman Index (HHI)
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
CATEGORY CONCENTRATION ANALYSIS

Category revenue dağılımı:

Vaccine      → %40.5
Care         → %32.7
Supplement   → %19.6
Accessories  → %7.2

Top 2 kategori toplam revenue’nun %73’ünü oluşturmaktadır.

Herfindahl-Hirschman Index (HHI) = 0.314

HHI > 0.25 olduğundan, kategori bazında yüksek revenue concentration bulunmaktadır.

Yorum:
Revenue birkaç kategoriye bağımlıdır.
Özellikle Vaccine ve Care kategorileri business için kritik öneme sahiptir.

Stratejik risk:
Bu kategorilerde talep düşüşü, regülasyon değişikliği veya rekabet artışı olması durumunda
toplam revenue ciddi şekilde etkilenebilir.

Öneri:
- Kategori portföy çeşitlendirmesi
- Düşük paylı kategorilerde (Accessories gibi) büyüme stratejisi
- Yüksek paylı kategoriler için risk azaltma planı
*/
