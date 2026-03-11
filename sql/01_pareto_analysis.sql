
-----------------------------------
--Pareto Revenue
-----------------------------------
/*
Pareto için şu 3 şey gerekir:

1️⃣ Her müşterinin toplam revenue'su
2️⃣ Revenue'ya göre sıralama
3️⃣ Kümülatif revenue yüzdesi

--1 için :
         SELECT
          customer_id,
          SUM(total_amount) AS revenue
          FROM `goit-exercises.GOITexercises.sales`
          WHERE customer_id IS NOT NULL
          GROUP BY 1
-----/-----------/-------------/-----------/----------

Soru :
Şu sorgunun ??? kısmına ne yazmamız gerekir?
SELECT
customer_id,
SUM(total_amount) AS revenue,
??? OVER (ORDER BY SUM(total_amount) DESC) AS revenue_rank
FROM `goit-exercises.GOITexercises.sales`
WHERE customer_id IS NOT NULL
GROUP BY 1
Seçenekler:

1️⃣ ROW_NUMBER()
2️⃣ RANK()
3️⃣ DENSE_RANK()

Hangisini kullanırdın ve neden?
--Cevabım :
dense_rank() kullanırdım cunku farklı musteriler aynı revenue ya sahip olabilir sıra atlamadan bır sonraki en yuksek revenue getıren musteriye mesela bir onceki 44. sıradaysa ve o sırada 3 musteri varsa 45. sıradan devam etmesını saglardım
-----/-----------/-------------/-----------/----------
Şimdi Pareto’nun kalbi: kümülatif revenue payı

Bir sonraki hedefimiz şu kolonları üretmek:

revenue_share = revenue / total_revenue

cum_revenue_share = revenue_share’ın kümülatifi (büyükten küçüğe)

Ve sonra “cum_revenue_share >= 0.80” noktasında kaç müşteri gerektiğine bakacağız.
*/
WITH customer_rev AS (
  SELECT
    customer_id,
    SUM(total_amount) AS revenue
  FROM `goit-exercises.GOITexercises.sales`
  WHERE customer_id IS NOT NULL
  GROUP BY 1
),
ranked AS (
  SELECT
    customer_id,
    revenue,
    DENSE_RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
    SUM(revenue) OVER () AS total_revenue
  FROM customer_rev
),
shares AS (
  SELECT
    customer_id,
    revenue,
    revenue_rank,
    SAFE_DIVIDE(revenue, total_revenue) AS revenue_share,
    SUM(SAFE_DIVIDE(revenue, total_revenue)) OVER (ORDER BY revenue DESC) AS cum_revenue_share
  FROM ranked
)
SELECT *
FROM shares
ORDER BY revenue DESC
LIMIT 200;
/*
Pareto sorusunu net cevaplamak için şu metrik lazım:

Gelirin %80’ine ulaşmak için kaç müşteri gerekiyor ve bu tüm müşterilerin yüzde kaçı?

Bunu hesaplamak için:

cum_revenue_share >= 0.80 olan ilk satırı bulacağız

o satırdaki müşteri sayısı = kaç müşteri

toplam müşteri sayısına böleceğiz

Soru :

“Gelirin %80’i müşterilerin %kaçından geliyor?”

*/
WITH customer_rev AS (
  SELECT
    customer_id,
    SUM(total_amount) AS revenue
  FROM `goit-exercises.GOITexercises.sales`
  WHERE customer_id IS NOT NULL
  GROUP BY 1
),
shares AS (
  SELECT
    customer_id,
    revenue,
    SUM(revenue) OVER () AS total_revenue,
    SAFE_DIVIDE(revenue, SUM(revenue) OVER ()) AS revenue_share
  FROM customer_rev
),
cum_shares AS (
  SELECT
    *,
    SUM(revenue_share) OVER (ORDER BY revenue DESC) AS cum_revenue_share,
    ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rn
  FROM shares
),
cutoff AS (
  SELECT *
  FROM cum_shares
  WHERE cum_revenue_share >= 0.80
  QUALIFY ROW_NUMBER() OVER (ORDER BY rn) = 1
),
tot AS (
  SELECT COUNT(*) AS total_customers
  FROM customer_rev
)
SELECT
  rn AS customers_needed_for_80pct_revenue,
  total_customers,
  SAFE_DIVIDE(rn, total_customers) AS pct_of_customers,
  cum_revenue_share AS reached_revenue_share
FROM cutoff
CROSS JOIN tot;
--153 müşterinin 22’si (~%14,4) gelirin ~%80,1’ini getiriyor. Bu net bir revenue concentration (gelir yoğunlaşması) bulgusu.

/*
Bu bulgunun “neden önemli” kısmı:

Bu 22 müşteriden birkaçının kaybı revenue’yu ciddi düşürür.

Bu segment için:

özel kampanya / sözleşme / müşteri temsilcisi

churn erken uyarı

sepet büyütme & cross-sell

memnuniyet (NPS vb.) gibi aksiyonlar mantıklı

*/
-- transaction bazında toplamı hesapla (line-item varsayımıyla)
-- total_amount transaction toplamı mı, line-item mı?

---------------------------------------------------------------
--Customer Pareto yaptık.Şimdi: 
--Gelirin %80’i işlemlerin (order) %kaçından geliyor?
---------------------------------------------------------------
--Adım 1: Transaction-level revenue üretelim
WITH tx AS (
  SELECT
    transaction_id,
    SUM(total_amount) AS txn_revenue
  FROM `goit-exercises.GOITexercises.sales`
  GROUP BY 1
)
SELECT *
FROM tx
LIMIT 10;
/*
Burada:

✔ Her transaction 1 satır
✔ txn_revenue = order value
*/
----------------------------------------
--Adım 2: Transaction Pareto datası
--Customer Pareto ile aynı mantığı uyguluyoruz ama transaction bazında:
WITH tx AS (
  SELECT
    transaction_id,
    SUM(total_amount) AS txn_revenue
  FROM `goit-exercises.GOITexercises.sales`
  GROUP BY 1
),

shares AS (
  SELECT
    transaction_id,
    txn_revenue,
    SUM(txn_revenue) OVER() AS total_revenue,
    SAFE_DIVIDE(txn_revenue, SUM(txn_revenue) OVER()) AS revenue_share
  FROM tx
),

cum_shares AS (
  SELECT
    *,
    SUM(revenue_share) OVER (ORDER BY txn_revenue DESC) AS cum_revenue_share,
    ROW_NUMBER() OVER (ORDER BY txn_revenue DESC) AS rn
  FROM shares
)

SELECT *
FROM cum_shares
ORDER BY txn_revenue DESC;
-------------------------------------------------------------------
--Adım 3: 80% cutoff
WITH tx AS (
  SELECT
    transaction_id,
    SUM(total_amount) AS txn_revenue
  FROM `goit-exercises.GOITexercises.sales`
  GROUP BY 1  
),
shares AS (
  SELECT
    transaction_id,
    txn_revenue,
    SUM(txn_revenue) OVER() AS total_revenue,
    SAFE_DIVIDE(txn_revenue, SUM(txn_revenue) OVER()) AS revenue_share
  FROM tx
),
cum_shares AS (
  SELECT
    *,
    SUM(revenue_share) OVER (ORDER BY txn_revenue DESC) AS cum_revenue_share,
    ROW_NUMBER() OVER (ORDER BY txn_revenue DESC) AS rn
  FROM shares
),
cutoff AS (
  SELECT *
  FROM cum_shares
  WHERE cum_revenue_share >= 0.80
  QUALIFY ROW_NUMBER() OVER (ORDER BY rn) = 1
),
tot AS (
  SELECT COUNT(*) AS total_orders
  FROM tx
)
SELECT
  rn AS orders_needed_for_80pct_revenue,
  tot.total_orders,
  SAFE_DIVIDE(rn, tot.total_orders) AS pct_of_orders,
  cum_revenue_share
FROM cutoff
CROSS JOIN tot;  
--------------------------------------------------------------------
--Elimizdeki Bulgular
--------------------------------------------------------------------
/*
Customer Pareto

22 müşteri

Toplam 153 müşteri

≈ %14 müşteri → %80 revenue
-------------------------------------
Order Pareto

12.766 order

124.756 total order

≈ %10 order → %80 revenue
---------------------------------------
Revenue daha çok büyük işlemlerden geliyor.
Çünkü:

Eğer revenue repeat frequency’den gelseydi
→ order yüzdesi customer yüzdesinden yüksek olurdu.

Ama burada:

Order concentration (%10)
Customer concentration (%14)

Order daha concentrated.

Bu ne demek?

👉 Herkes çok sık alışveriş yaptığı için değil
👉 Bazı işlemler çok büyük olduğu için revenue yoğunlaşıyor.
---------------------------------------------------------------
Eğer şu çıksaydı:

Customer %14
Order %30

Bu ne demek olurdu?

→ Az müşteri ama çok sık alışveriş yapıyorlar
→ Loyalty driven model

Ama bu verinde:

→ Big basket driven model

Bu çok farklı bir strateji gerektirir.

*/
----------------------------------------------------------------
/*
Gelirin %80’i işlemlerin sadece %10’undan geliyor ya
Bu büyük işlemler hangi kategoriden geliyor onu bulalım ve
bazı kavramları inceleyelim.
*/
----------------------------------------------------------------
/*
Global AOV(ortalama siparis değeri) :
Toplam Revenue / Toplam Order

Customer-level AOV :
Müşterinin toplam harcaması / yaptığı order sayısı

High AOV customer :
Sık alışveriş yapmasa bile
Her sepeti büyük olan müşteri

Bu Pareto sonucu ile bağlantılı çünkü:

Revenue few large baskets’ten geliyorsa
→ High AOV customers önemlidir.
*/
----------------------------------------------------------------
--Analiz 1: Revenue hangi kategoriden geliyor?
----------------------------------------------------------------
/*
Mantık:

Category bazında revenue hesapla

Revenue share çıkar

Pareto mantığı uygula
*/
----------------------------------------
--Step 1 — Category revenue
WITH cat_rev AS (
  SELECT
    p.category_name,
    ROUND(SUM(s.total_amount),2) AS revenue
  FROM `goit-exercises.GOITexercises.sales` s
  JOIN `goit-exercises.GOITexercises.products` p
    USING (product_id)
  GROUP BY 1
)
SELECT *
FROM cat_rev
ORDER BY revenue DESC;
-----------------------------------
--Step 2 — Yüzde paylarını hesaplayalım
WITH cat_rev AS (
  SELECT
    p.category_name,
    ROUND(SUM(s.total_amount),2) AS revenue
  FROM `goit-exercises.GOITexercises.sales` s
  JOIN `goit-exercises.GOITexercises.products` p
    USING (product_id)
  GROUP BY 1
),

shares AS (
  SELECT
    category_name,
    revenue,
    SUM(revenue) OVER() AS total_revenue,
    ROUND(SAFE_DIVIDE(revenue, SUM(revenue) OVER()),2) AS revenue_share
  FROM cat_rev
),

cum_shares AS (
  SELECT
    *,
    ROUND(SUM(revenue_share) OVER (ORDER BY revenue DESC),3) AS cum_revenue_share
  FROM shares
)

SELECT *
FROM cum_shares
ORDER BY revenue DESC;
------------------------------------------------------------------
/*
Analiz Sonucu :
Gelir kategoriler arasında eşit dağılmamaktadır. Vaccine ve Care kategorileri toplam gelirin yaklaşık %73’ünü oluşturmaktadır. Bu durum bu iki kategorinin gelir yaratımında stratejik öneme sahip olduğunu göstermektedir.

Vaccine ve Care yüksek revenue getiriyor, peki bu neden?
İki temel ihtimal var:

Çok satılıyorlar → volume driven

Sepet başına / birim başına daha değerli → price / AOV driven

Bunu görmek için category bazında şu metriklere bakalım:

total units
total orders
revenue
revenue per unit
average order value by category
*/
WITH cat_metrics AS (
  SELECT
    p.category_name,
    COUNT(DISTINCT s.transaction_id) AS orders,
    SUM(s.quantity) AS units,
    ROUND(SUM(s.total_amount),2) AS revenue
  FROM `goit-exercises.GOITexercises.sales` s
  JOIN `goit-exercises.GOITexercises.products` p
    USING (product_id)
  GROUP BY 1
)
SELECT
  category_name,
  orders,
  units,
  revenue,
  ROUND(SAFE_DIVIDE(revenue, units), 2) AS revenue_per_unit,
  ROUND(SAFE_DIVIDE(revenue, orders), 2) AS revenue_per_order
FROM cat_metrics
ORDER BY revenue DESC;
/*
Vaccine neden 1 numara?
Çok order mı var?
Hayır.30 bin ile 3. sırada aslında.Care ve Supplement daha fazla order’a sahip.
Peki neden revenue lideri?

=> Çünkü price driven.
Revenue per unit: 38.29
Revenue per order: 4,937
Bu açık ara en yüksek.
-----------------------------------------
Diğerleri de benzer şekilde yorumlanabilir.
*/
------------------------------------------------------------------------------
--Peki bir kategoriden ürün alan kişi başka bir kategoriden de ürün alıyor mu
--yani siparişler genelde başka ürünlerle birlikte mi alınıyor?
-------------------------------------------------------------------------------
WITH tx AS (
  SELECT
    s.transaction_id,
    SUM(s.total_amount) AS txn_revenue,
    COUNT(DISTINCT p.category_name) AS category_count,
    MAX(CASE WHEN p.category_name = 'Vaccine' THEN 1 ELSE 0 END) AS has_vaccine,
    MAX(CASE WHEN p.category_name = 'Care' THEN 1 ELSE 0 END) AS has_care,
    MAX(CASE WHEN p.category_name = 'Supplement' THEN 1 ELSE 0 END) AS has_supplement,
    MAX(CASE WHEN p.category_name = 'Accessories' THEN 1 ELSE 0 END) AS has_accessories
  FROM `goit-exercises.GOITexercises.sales` s
  JOIN `goit-exercises.GOITexercises.products` p
    USING (product_id)
  GROUP BY 1
),

category_expanded AS (
  SELECT transaction_id, txn_revenue, category_count, 'Vaccine' AS category
  FROM tx WHERE has_vaccine = 1

  UNION ALL

  SELECT transaction_id, txn_revenue, category_count, 'Care'
  FROM tx WHERE has_care = 1

  UNION ALL

  SELECT transaction_id, txn_revenue, category_count, 'Supplement'
  FROM tx WHERE has_supplement = 1

  UNION ALL

  SELECT transaction_id, txn_revenue, category_count, 'Accessories'
  FROM tx WHERE has_accessories = 1
)

SELECT
  category,
  COUNT(*) AS orders,
  ROUND(AVG(txn_revenue),2) AS avg_order_value,
  ROUND(AVG(category_count),2) AS avg_categories_per_order
FROM category_expanded
GROUP BY 1
ORDER BY avg_order_value DESC;
---------------------------------------------------------------------------
/*
Önce metrik neyi ölçüyor?
avg_categories_per_order--------<--------<----------------<---------
Bir siparişte ortalama kaç farklı kategori var.
Yani:

1.00 → tek kategori

2.00 → iki kategori

3.00 → üç kategori

Bizde 1.97 - 1.69 arası değişen rakamlar var yani ortalama bir sipraiste 2 kategoriden
birden alışveriş yapılıyor.
İstersek Category cross-sell matrix sorgusu ile hangi kategori hangi kategori ile
daha cok birlikte sirapiiş veriliyor bunu görelim.
*/
WITH order_categories AS (
  SELECT DISTINCT
    s.transaction_id,
    p.category_name
  FROM `goit-exercises.GOITexercises.sales` s
  JOIN `goit-exercises.GOITexercises.products` p
    USING (product_id)
),

pairs AS (
  SELECT
    a.category_name AS category_a,
    b.category_name AS category_b,
    COUNT(DISTINCT a.transaction_id) AS pair_orders
  FROM order_categories a
  JOIN order_categories b
    ON a.transaction_id = b.transaction_id
   AND a.category_name < b.category_name   -- duplicate & self pair önleme
  GROUP BY 1,2
),

category_orders AS (
  SELECT
    category_name,
    COUNT(DISTINCT transaction_id) AS orders
  FROM order_categories
  GROUP BY 1
),

total_orders AS (
  SELECT COUNT(DISTINCT transaction_id) AS total_orders
  FROM order_categories
)

SELECT
  p.category_a,
  p.category_b,
  p.pair_orders,

  -- support
  ROUND(SAFE_DIVIDE(p.pair_orders, t.total_orders),3) AS support,

  -- confidence A -> B
  ROUND(SAFE_DIVIDE(p.pair_orders, ca.orders),3) AS confidence_a_to_b,

  -- confidence B -> A
  ROUND(SAFE_DIVIDE(p.pair_orders, cb.orders),3) AS confidence_b_to_a,

  -- lift
  ROUND(SAFE_DIVIDE(
    SAFE_DIVIDE(p.pair_orders, t.total_orders),
    SAFE_MULTIPLY(
      SAFE_DIVIDE(ca.orders, t.total_orders),
      SAFE_DIVIDE(cb.orders, t.total_orders)
    )
  ),3) AS lift

FROM pairs p
JOIN category_orders ca ON p.category_a = ca.category_name
JOIN category_orders cb ON p.category_b = cb.category_name
CROSS JOIN total_orders t
ORDER BY lift DESC;

/*
Analiz Sonucları :

pair_orders : Bu iki kategori aynı siparişte kaç kez birlikte görülmüş?
support : Bu iki kategori tüm siparişlerin yüzde kaçında birlikte?
confidence_a_to_b : A kategorisi varsa, B olma ihtimali nedir?
confidence_b_to_a : B varsa, A olma ihtimali nedir?
lift : Lift=P(A)×P(B)P(A∩B)​
> 1	Beklenenden güçlü ilişki
= 1	Bağımsız
< 1	Negatif ilişki

lift hepsinde 1 den kucuk, kategoriler birlikte beklenenden daha az alınıyor.
Cross-sell doğal olarak güçlü değil.

Bu dataset’te kategori davranışı:

→ Büyük ölçüde bağımsız.

Şu satır:

Care + Supplement
support = 0.183
confidence_a_to_b = 0.393
lift = 0.734

En yüksek support burada.

Ama lift düşük.

Yani:

Çok birlikte alınıyor
Ama zaten ayrı ayrı da çok alınıyor.

Bu klasik analyst tuzağıdır:

Yüksek hacim ≠ güçlü ilişki
*/
------------------------------------------------------------------------------------------
--Product bazında da aynı analiz yapılabilir.




/* Extra Bilgi : Sales Tablosu
217,107 satır
124,756 transaction
Her transaction ortalama 1.7 üründen oluşuyor.Sepet Büyüklüğü.
*/











