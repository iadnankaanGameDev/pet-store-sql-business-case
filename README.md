# 🐾 Pet Store SQL İş Analizi Case Study

Bu proje, bir pet store şirketi için uçtan uca SQL tabanlı iş analizi çalışmasını içermektedir.

Amaç; gelir yapısını, müşteri değer dağılımını ve ürün/kategori bazlı bağımlılık risklerini analiz ederek stratejik içgörüler üretmektir.

---

## 📊 İş Problemi

Bu analiz aşağıdaki temel sorulara cevap aramaktadır:

- Gelir birkaç ürüne mi bağımlı?
- Gelir birkaç kategoriye mi yoğunlaşmış durumda?
- En yüksek değeri hangi müşteri segmentleri yaratıyor?
- İş modeli ürün bazlı mı yoksa kategori bazlı mı risk taşıyor?

---

## 🔎 Yapılan Analizler

### 1️⃣ Veri Kalite Kontrolleri
- Duplicate transaction kontrolü  
- Null join anahtarı analizi  
- Aylık revenue ve sipariş trendi  

---

### 2️⃣ Pareto Analizi (Ürün Bazlı)

- Top 3 ürün toplam gelirin **%54’ünü** üretmektedir.
- Top 10 ürün (ürün portföyünün ~%48’i) toplam gelirin **~%80’ini** oluşturmaktadır.

Bu durum orta seviyede ürün bağımlılığına işaret etmektedir.

---

### 3️⃣ Revenue Volatility (Ürün Yoğunlaşma Analizi)

Ürün bazında gelir payı ve kümülatif dağılım incelenmiştir.

- Gelirin %80’i sınırlı sayıda üründen gelmektedir.
- Yüksek gelir üreten ürünler operasyonel açıdan kritik öneme sahiptir.

📌 Risk:
En yüksek paylı ürünlerde yaşanacak talep düşüşü veya stok problemi,
toplam geliri orantısız şekilde etkileyebilir.

---

### 4️⃣ Category Concentration Analizi

Kategori bazlı gelir dağılımı:

- Vaccine → %40+
- Care → %30+
- Supplement → %19+
- Accessories → %7+

Top 2 kategori toplam gelirin **%73’ünü** oluşturmaktadır.

Herfindahl-Hirschman Index (HHI) ≈ **0.31**

HHI > 0.25 olduğu için kategori bazında yüksek konsantrasyon mevcuttur.

📌 Sonuç:
Gelir yapısı ürün bazlı değil, kategori bazlı yoğunlaşmaktadır.
Business stratejik olarak belirli kategorilere bağımlıdır.

---

### 5️⃣ RFM Segmentasyonu

Müşteriler aşağıdaki metriklerle segmentlenmiştir:

- **Recency** – Son alışveriş zamanı
- **Frequency** – İşlem sayısı
- **Monetary** – Toplam harcama

En yüksek gelir “Champions” ve “Potential Loyalists” segmentlerinden gelmektedir.

---

### 6️⃣ Cohort Analizi

Müşterilerin ilk alışveriş ayına göre retention davranışları analiz edilmiştir.

Bu analiz:
- Müşteri yaşam süresi
- Aktivite devamlılığı
- Growth stratejileri

açısından önemli içgörüler sunmaktadır.

---

## 📈 Temel İçgörüler

- Gelir yapısı kategori odaklı yoğunlaşmaktadır.
- Vaccine ve Care kategorileri stratejik öneme sahiptir.
- Ürün bazlı bağımlılık orta seviyededir.
- Yüksek değerli müşteri segmentleri gelir performansını sürüklemektedir.
- İş modeli kategori riskine karşı hassastır.

---

## 🛠 Kullanılan SQL Teknikleri

- Window Functions  
- Cumulative Distribution  
- Pareto Analizi  
- Herfindahl-Hirschman Index (HHI)  
- RFM Skorlama Modeli  
- Cohort Retention Analizi  
- Revenue Risk Senaryo Modelleme  

---

## 🎯 Stratejik Öneriler

- Kategori portföy çeşitlendirilmesi  
- Kritik kategoriler için risk azaltma planı  
- Yüksek değerli müşteri segmentlerine özel kampanyalar  
- Düşük paylı kategorilerde büyüme stratejisi  
- Top revenue ürünler için talep ve stok optimizasyonu  

---

## 📁 Proje Yapısı
