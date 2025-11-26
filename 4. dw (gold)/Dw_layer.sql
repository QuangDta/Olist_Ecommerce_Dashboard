USE olist_ecom;

CREATE SCHEMA DW;

-- Star schema
-- Dim tables
-- customers
CREATE TABLE DW.dim_customers (
    customer_key INT IDENTITY(1,1) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(255),
    customer_state VARCHAR(2)
);

CREATE TABLE DW.dim_sellers (
    seller_key INT IDENTITY(1,1) PRIMARY KEY,
    seller_id VARCHAR(50) NOT NULL,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(255),
    seller_state VARCHAR(2)
);

CREATE TABLE DW.dim_products (
    product_key INT IDENTITY(1,1) PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL,
    product_category_name VARCHAR(255),
    product_weight_g DECIMAL(10,2),
    product_length_cm DECIMAL(10,2),
    product_height_cm DECIMAL(10,2),
    product_width_cm DECIMAL(10,2)
);

CREATE TABLE DW.dim_date (
    date_key INT PRIMARY KEY,      -- yyyymmdd
    date_value DATE,
    year INT,
    month INT,
    day INT,
    quarter INT,
    week_of_year INT,
    weekday INT
);

-- fact tables
CREATE TABLE DW.fact_orders (
    order_key INT IDENTITY PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    customer_key INT,
    order_status VARCHAR(50),

    -- date foreign keys
    order_purchase_date_key INT,
    order_approved_date_key INT,
    order_carrier_date_key INT,
    order_delivered_date_key INT,
    order_estimated_delivery_date_key INT,

    -- metrics
    delivery_delay_days INT,
    actual_delivery_time_days INT,

    FOREIGN KEY (customer_key) REFERENCES DW.dim_customers(customer_key),
    FOREIGN KEY (order_purchase_date_key) REFERENCES DW.dim_date(date_key),
    FOREIGN KEY (order_approved_date_key) REFERENCES DW.dim_date(date_key),
    FOREIGN KEY (order_carrier_date_key) REFERENCES DW.dim_date(date_key),
    FOREIGN KEY (order_delivered_date_key) REFERENCES DW.dim_date(date_key),
    FOREIGN KEY (order_estimated_delivery_date_key) REFERENCES DW.dim_date(date_key)
);

CREATE TABLE DW.fact_order_items (
    order_item_key INT IDENTITY(1,1) PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    order_item_id INT NOT NULL,

    product_key INT,
    seller_key INT,

    shipping_limit_date_key INT,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),

    FOREIGN KEY (product_key) REFERENCES DW.dim_products(product_key),
    FOREIGN KEY (seller_key) REFERENCES DW.dim_sellers(seller_key),
    FOREIGN KEY (shipping_limit_date_key) REFERENCES DW.dim_date(date_key)
);

CREATE TABLE DW.fact_payments (
    payment_key INT IDENTITY(1,1) PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,

    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(12,2)
);


-- Insert data
-- customers
INSERT INTO DW.dim_customers (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM STG.customers;

-- sellers
INSERT INTO DW.dim_sellers (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM STG.sellers;

-- products
INSERT INTO DW.dim_products (
    product_id,
    product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT
    product_id,
    product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM STG.products;

-- date
;WITH DateRange AS (
    SELECT CAST('2016-01-01' AS DATE) AS dt
    UNION ALL
    SELECT DATEADD(DAY, 1, dt) FROM DateRange WHERE dt < '2018-12-31'
)
INSERT INTO DW.dim_date (
    date_key,
    date_value,
    year, month, day,
    quarter,
    week_of_year,
    weekday
)
SELECT
    CONVERT(INT, FORMAT(dt, 'yyyyMMdd')),
    dt,
    YEAR(dt),
    MONTH(dt),
    DAY(dt),
    DATEPART(QUARTER, dt),
    DATEPART(WEEK, dt),
    DATEPART(WEEKDAY, dt)
FROM DateRange OPTION (MAXRECURSION 0);

CREATE FUNCTION DW.get_date_key (@d DATETIME)
RETURNS INT
AS
BEGIN
    DECLARE @min_date DATE = '2016-01-01';
    DECLARE @max_date DATE = '2018-12-31';

    IF @d IS NULL 
        RETURN NULL;

    -- Nếu ngoài phạm vi, trả về NULL
    IF @d < @min_date OR @d > @max_date
        RETURN NULL;

    RETURN CONVERT(INT, FORMAT(@d, 'yyyyMMdd'));
END;


-- orders
INSERT INTO DW.fact_orders (
    order_id,
    customer_key,
    order_status,
    order_purchase_date_key,
    order_approved_date_key,
    order_carrier_date_key,
    order_delivered_date_key,
    order_estimated_delivery_date_key,
    delivery_delay_days,
    actual_delivery_time_days
)
SELECT
    o.order_id,
    dc.customer_key,
    o.order_status,

    DW.get_date_key(o.order_purchase_timestamp),
    DW.get_date_key(o.order_approved_at),
    DW.get_date_key(o.order_delivered_carrier_date),
    DW.get_date_key(o.order_delivered_customer_date),
    DW.get_date_key(o.order_estimated_delivery_date),

    CASE 
        WHEN o.order_delivered_customer_date IS NULL THEN NULL
        ELSE DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date)
    END AS delivery_delay_days,

    CASE 
        WHEN o.order_delivered_customer_date IS NULL THEN NULL
        ELSE DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)
    END AS actual_delivery_time_days

FROM STG.orders o
LEFT JOIN DW.dim_customers dc 
    ON o.customer_id = dc.customer_id;

-- order_items
INSERT INTO DW.fact_order_items (
    order_id,
    order_item_id,
    product_key,
    seller_key,
    shipping_limit_date_key,
    price,
    freight_value
)
SELECT
    i.order_id,
    i.order_item_id,

    dp.product_key,
    ds.seller_key,

    DW.get_date_key(i.shipping_limit_date),
    i.price,
    i.freight_value
FROM STG.order_items i
LEFT JOIN DW.dim_products dp 
    ON i.product_id = dp.product_id
LEFT JOIN DW.dim_sellers ds 
    ON i.seller_id = ds.seller_id;
    
-- payments
    
INSERT INTO DW.fact_payments (
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM STG.order_payments;

