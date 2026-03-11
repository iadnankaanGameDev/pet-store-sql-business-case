# pet-store-sql-business-case
End-to-end SQL business analysis including Pareto, RFM segmentation, revenue volatility and concentration risk modeling.

# 🐾 Pet Store SQL Business Case

End-to-end SQL business analysis including Pareto analysis, RFM segmentation, revenue volatility and category concentration modeling.

---

## 📊 Business Problem

The objective of this analysis is to understand:

- Revenue concentration risk  
- Customer value distribution  
- Product and category dependency  
- Strategic revenue structure  

---

## 🔎 Analysis Performed

### 1️⃣ Pareto Analysis (Product Level)

- Top 3 products generate **54% of total revenue**
- Top 10 products (~48% of product portfolio) generate **~80% of revenue**

This indicates moderate product concentration risk.

---

### 2️⃣ Category Concentration

Revenue distribution by category:

- Vaccine → 40.5%
- Care → 32.7%
- Supplement → 19.6%
- Accessories → 7.2%

Top 2 categories generate **73% of total revenue**.

Herfindahl-Hirschman Index (HHI) = **0.314**

Since HHI > 0.25, category-level concentration is high, indicating strategic dependency on specific categories.

---

### 3️⃣ RFM Segmentation

Customers were segmented using:

- **Recency** – How recently did the customer purchase?
- **Frequency** – How many transactions?
- **Monetary** – Total revenue generated

Revenue is primarily driven by Champions and Potential Loyalists segments.

---

## 📈 Key Insights

- Revenue structure is category-driven rather than product-driven.
- High dependency on Vaccine and Care categories.
- Top products have significant but not extreme dominance.
- Business faces strategic risk from category concentration.

---

## 🛠 SQL Techniques Used

- Window Functions
- Cumulative Distribution
- Pareto Logic
- Herfindahl Index (HHI)
- RFM Scoring Model
- Revenue Risk Simulation

---

## 🎯 Business Recommendations

- Diversify category portfolio
- Protect high-revenue categories operationally
- Strengthen retention strategies for high-value customers
- Conduct elasticity analysis on top revenue products

---

## 📁 Project Structure

