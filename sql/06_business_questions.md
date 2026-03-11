SELECT 1;
--Business impact odaklı analiz
/*
-----------------------------------
Pareto Revenue (80/20 kuralı)
-----------------------------------

İleri seviye analist sorusu:

Gelirin yüzde kaçı müşterilerin yüzde kaçından geliyor?

Örneğin:

müşterilerin %20’si

gelirin %75’ini getiriyor olabilir

Bu customer concentration risk analizidir.

Şirket bunu şunun için ister:

VIP müşteriler kim

churn riski

CRM stratejisi
*/
---------------------------------------------------------
--Cohort Analysis
---------------------------------------------------------
/*
Şirketlerin en sevdiği analizlerden biri.

Soru:

Bir müşteri ilk alışveriş yaptıktan sonra kaç ay aktif kalıyor?
Growth analyst’ler bunu sürekli yapar.
*/
------------------------------------------------------------------
--Revenue decomposition
------------------------------------------------------------------
/*
Şirket sorar:

Revenue artışı nereden geliyor?

3 kaynağı vardır:

Revenue =
customers
× orders_per_customer
× average_order_value

Yani:

yeni müşteri mi geliyor

müşteri daha sık mı alışveriş yapıyor

sepet büyüklüğü mü arttı
*/
------------------------------------------------------------------
--Customer segmentation (RFM)
------------------------------------------------------------------
/*
RFM çok klasik bir ileri analizdir.
Recency
Frequency
Monetary

Müşterileri segmentlersin:

segment
Champions
Loyal
At risk
Lost

CRM ve marketing bunu kullanır.
*/
-----------------------------------------------------------------
--Category dependency
-----------------------------------------------------------------
/*
Soru:

Hangi kategori diğer kategorileri tetikliyor?

Örneğin:

Vaccination → Medicine

Bu journey analysis.
*/
-----------------------------------------------------------------
--Revenue volatility (Product dependency)
-----------------------------------------------------------------
/*
Soru:

Revenue birkaç ürüne mi bağımlı?

Risk analizi.

Top 5 ürün revenue’nun % kaçını getiriyor?

Eğer 1 ürün düşerse revenue ne olur? gibi sorulara cevap aranabilir.
*/
-----------------------------------------------------------------
--Customer lifetime curve
-----------------------------------------------------------------
/*
Soru:

Müşteri ilk 30 gün içinde mi daha çok harcıyor yoksa zamanla mı?
*/
-----------------------------------------------------------------

-----------------------------------------------------------------
















