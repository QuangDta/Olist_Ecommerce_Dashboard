# PowerBI E-commerce analytics using Olist Dataset

[cite_start]This project demonstrates the construction of a complete (end-to-end) Data Platform pipeline, transforming raw data into actionable insights, utilizing the Olist Brazilian E-commerce dataset[cite: 1, 2].

## 1. Project Goals and Architecture

* [cite_start]**Project Name:** E-commerce Analytics Pipeline using Olist Dataset [cite: 1]
* [cite_start]**Objective:** To build an end-to-end ETL/ELT pipeline from RAW → STG → DIM/FACT → Power BI Dashboard, simulating a modern Data Platform architecture[cite: 1].
* [cite_start]**Tools Used:** SQL Server, DBeaver, Power BI[cite: 2].
* [cite_start]**Architecture:** CSV → RAW schema → STG schema → DIM / FACT → Power BI Dashboard[cite: 3].

## 2. Data Layers and Processing

### 2.1. RAW Layer

* [cite_start]**Purpose:** Stores the original data imported directly from CSV files[cite: 3].
* [cite_start]**Characteristics:** No PKs, FKs, or indexes[cite: 4]. [cite_start]Data is maintained as 100% original[cite: 4].
* [cite_start]**Key Tables:** `raw.orders` (99,441 rows), `raw.order_items` (112,650 rows), `raw.customers` (99,441 rows), `raw.products` (32,951 rows), `raw.geolocation` (1,000,163 rows)[cite: 5].

### 2.2. STAGING Layer (STG)

* [cite_start]**Purpose:** Data cleansing, standardization, and initial transformation[cite: 3].
* **Key Cleaning Tasks:**
    * [cite_start]**Geolocation:** Normalizing Latin characters (e.g., `são paulo` → `sao paulo`), reducing distinct city values from 8010 to 5931 after regex cleaning and accent normalization[cite: 6].
    * [cite_start]**Products:** Filling missing `product_category_name` records with 'others' (623 records)[cite: 6].
    * [cite_start]**Orders:** Identifying and documenting invalid transaction times (e.g., `invalid_order_delivered_customer_date_count`: 23)[cite: 6].

### 2.3. DW Layer (DIM + FACT)

[cite_start]The final Data Warehouse layer is structured as a Star Schema, optimized for querying and reporting[cite: 5].

#### DIMENSION Tables

| Table | Surrogate Key (SK) | Business Key (BK) | Grain | Description |
| :--- | :--- | :--- | :--- | :--- |
| `dim_customers` | `customer_key` | `customer_id` | [cite_start]1 row = 1 customer [cite: 7] | [cite_start]Includes clean city, zip code, and state information[cite: 7]. |
| `dim_products` | `product_key` | `product_id` | [cite_start]1 row = 1 unique product [cite: 8] | [cite_start]Contains descriptive information (dimensions, weight, category)[cite: 9]. |
| `dim_sellers` | `seller_key` | `seller_id` | [cite_start]1 row = 1 seller [cite: 10] | [cite_start]Includes seller address and location details[cite: 10]. |
| `dim_date` | `date_key` (YYYYMMDD) | `date_value` | [cite_start]1 row = 1 date [cite: 11] | [cite_start]Full calendar dimension (day, month, quarter, year, weekday, week-of-year)[cite: 11]. |

#### FACT Tables

| Table | Grain | PK | Purpose | Key Foreign Keys |
| :--- | :--- | :--- | :--- | :--- |
| `fact_orders` | [cite_start]1 row = 1 order [cite: 12] | `order_key` | [cite_start]Analyzing shipment time and order status[cite: 12]. | `customer_key`, `order_purchase_date_key`, etc. |
| `fact_order_items` | [cite_start]1 row = 1 item in 1 order [cite: 13] | `order_item_key` | [cite_start]Detailed transaction analysis (revenue by product, category, seller)[cite: 14]. | [cite_start]`product_key`, `seller_key`, `order_id`[cite: 13]. |
| `fact_payments` | [cite_start]1 row = 1 payment transaction [cite: 15] | `payment_key` | [cite_start]Analyzing payment types and revenue[cite: 15]. | [cite_start]`order_id`[cite: 15]. |

## 4. Power BI dashboard structure

The project culminates in three primary dashboards designed for specific business users:

* [cite_start]**Overview:** Provides overall performance and trends[cite: 16].
    * [cite_start]**Metrics:** Total revenue, Total profit, AOV (average order value), Total revenue/Order over time, Payment method distribution[cite: 16].
* [cite_start]**Products:** Focuses on merchandise performance and Cost analysis[cite: 17].
    * [cite_start]**Metrics:** Total products sold, Number of sellers, Top/Bottom categories, Revenue by Price Tier (Low, Mid, High, Premium), Freight cost vs. price ratio[cite: 18].
