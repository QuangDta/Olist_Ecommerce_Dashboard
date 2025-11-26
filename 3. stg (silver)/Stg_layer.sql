USE olist_ecom;

-- Copy tables from "raw" layer to "stg" layer

CREATE SCHEMA stg;

-- Copy customers table
SELECT * INTO olist_ecom.STG.customers
FROM olist_ecom.raw.customers;

-- Copy geolocation table
SELECT * INTO olist_ecom.STG.geolocation
FROM olist_ecom.raw.geolocation;

-- Copy order_items table
SELECT * INTO olist_ecom.STG.order_items
FROM olist_ecom.raw.order_items;

-- Copy order_payments table
SELECT * INTO olist_ecom.STG.order_payments
FROM olist_ecom.raw.order_payments;

-- Copy order_reviews table
SELECT * INTO olist_ecom.STG.order_reviews
FROM olist_ecom.raw.order_reviews;

-- Copy orders table
SELECT * INTO olist_ecom.STG.orders
FROM olist_ecom.raw.orders;

-- Copy products table
SELECT * INTO olist_ecom.STG.products
FROM olist_ecom.raw.products;

-- Copy sellers table
SELECT * INTO olist_ecom.STG.sellers
FROM olist_ecom.raw.sellers;



-- Data cleaning

-- Check for nulls or empty strings in each column of each table in the `STG` schema
DECLARE @sql NVARCHAR(MAX) = N'';

-- Loop through each table in the STG schema
SELECT @sql = @sql + 
    'SELECT ''' + TABLE_NAME + ''' AS table_name, ''' + COLUMN_NAME + ''' AS column_name, ' +
    'COUNT(*) AS total_rows, ' +
    'SUM(CASE WHEN [' + COLUMN_NAME + '] IS NULL OR [' + COLUMN_NAME + '] = '''' THEN 1 ELSE 0 END) AS missing_count ' +
    'FROM [olist_ecom].[STG].[' + TABLE_NAME + '] UNION ALL '
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'STG';

-- Remove the trailing UNION ALL
SET @sql = LEFT(@sql, LEN(@sql) - 10);

-- Execute the dynamically generated SQL
EXEC sp_executesql @sql;

-- RESULTS: 
	-- orders_items table:
		-- freight_value: 383 missings
	-- order_payments table:
		-- payment_installments: 2
		-- payment_value: 9
	-- orders table:
		-- order_approved_at: 160
		-- order_delivered_carrier_date: 1783
		-- order_delivered_customer_date: 2965
	-- products table:
		-- product_category_name: 623
		-- product_description_lenght: 610
		-- product_height_cm: 2
		-- product_length_cm: 2
		-- product_name_lenght: 610
		-- product_photos_qty: 610
		-- product_weight_g: 6
		-- product_width_cm: 2

-- check for duplicate values in the `id` columns of each table in the `STG` schema
-- Check for duplicate customer_id in STG.customers
SELECT 
    customer_id, 
    COUNT(*) AS duplicate_count
FROM 
    olist_ecom.STG.customers
GROUP BY 
    customer_id
HAVING 
    COUNT(*) > 1;

-- Check for duplicate geolocation_zip_code_prefix in STG.geolocation
SELECT 
    geolocation_zip_code_prefix, 
    COUNT(*) AS duplicate_count
FROM 
    olist_ecom.STG.geolocation
GROUP BY 
    geolocation_zip_code_prefix
HAVING 
    COUNT(*) > 1;

-- Check for duplicate order_id in STG.order_items
SELECT 
    order_id, 
    COUNT(*) AS duplicate_count
FROM 
    olist_ecom.STG.order_items
GROUP BY 
    order_id
HAVING 
    COUNT(*) > 1;

-- Check for duplicate order_id in STG.order_payments
SELECT 
    order_id, 
    COUNT(*) AS duplicate_count
FROM 
    olist_ecom.STG.order_payments
GROUP BY 
    order_id
HAVING 
    COUNT(*) > 1;

-- Check for duplicate order_id in STG.order_reviews
SELECT 
    review_id, 
    COUNT(*) AS duplicate_count
FROM 
    olist_ecom.STG.order_reviews
GROUP BY 
    review_id
HAVING 
    COUNT(*) > 1;

-- Check for duplicate order_id in STG.order_payments
SELECT 
    order_id, 
    COUNT(*) AS duplicate_count
FROM 
    olist_ecom.STG.order_payments
GROUP BY 
    order_id
HAVING 
    COUNT(*) > 1;

-- Check for duplicate order_id in STG.orders
SELECT 
    order_id, 
    COUNT(*) AS duplicate_count
FROM 
    olist_ecom.STG.orders
GROUP BY 
    order_id
HAVING 
    COUNT(*) > 1;

-- Check for duplicate product_id in STG.products
SELECT 
    product_id, 
    COUNT(*) AS duplicate_count
FROM 
    olist_ecom.STG.products
GROUP BY 
    product_id
HAVING 
    COUNT(*) > 1;

-- Check for duplicate seller_id in STG.sellers
SELECT 
    seller_id, 
    COUNT(*) AS duplicate_count
FROM 
    olist_ecom.STG.sellers
GROUP BY 
    seller_id
HAVING 
    COUNT(*) > 1;


-- Inconsistency
-- Customers table
SELECT COUNT(DISTINCT customer_city) FROM stg.customers
SELECT customer_city FROM olist_ecom.STG.customers WHERE customer_city <> LOWER(customer_city ) -- khong sao

UPDATE olist_ecom.STG.customers
SET customer_city = LOWER(LTRIM(RTRIM(customer_city)))
WHERE customer_city <> LOWER(LTRIM(RTRIM(customer_city)));

-- Geolocation table
SELECT geolocation_city FROM olist_ecom.STG.geolocation WHERE geolocation_city <> LOWER(geolocation_city) -- khong sao


WITH DistinctCities AS (
    SELECT
        geolocation_city,
        COUNT(geolocation_city) as 'number'
    FROM
        olist_ecom.STG.geolocation
    GROUP BY geolocation_city 
)
SELECT
    geolocation_city,
    number
FROM
    DistinctCities
ORDER BY
    geolocation_city COLLATE Latin1_General_CI_AI; --mismatch in names

-- fixing
CREATE FUNCTION dbo.RemoveAccents (@input NVARCHAR(4000))
RETURNS NVARCHAR(4000)
AS
BEGIN
    IF @input IS NULL RETURN NULL;

    DECLARE @output NVARCHAR(4000) = @input;

    -- Replace accented characters
    SET @output = REPLACE(@output, N'á', 'a');
    SET @output = REPLACE(@output, N'à', 'a');
    SET @output = REPLACE(@output, N'ả', 'a');
    SET @output = REPLACE(@output, N'ã', 'a');
    SET @output = REPLACE(@output, N'ạ', 'a');
    SET @output = REPLACE(@output, N'ă', 'a');
    SET @output = REPLACE(@output, N'ắ', 'a');
    SET @output = REPLACE(@output, N'ằ', 'a');
    SET @output = REPLACE(@output, N'ẳ', 'a');
    SET @output = REPLACE(@output, N'ẵ', 'a');
    SET @output = REPLACE(@output, N'ặ', 'a');
    SET @output = REPLACE(@output, N'â', 'a');
    SET @output = REPLACE(@output, N'ấ', 'a');
    SET @output = REPLACE(@output, N'ầ', 'a');
    SET @output = REPLACE(@output, N'ẩ', 'a');
    SET @output = REPLACE(@output, N'ẫ', 'a');
    SET @output = REPLACE(@output, N'ậ', 'a');

    SET @output = REPLACE(@output, N'ç', 'c');
    
    SET @output = REPLACE(@output, N'é', 'e');
    SET @output = REPLACE(@output, N'è', 'e');
    SET @output = REPLACE(@output, N'ẻ', 'e');
    SET @output = REPLACE(@output, N'ẽ', 'e');
    SET @output = REPLACE(@output, N'ẹ', 'e');
    SET @output = REPLACE(@output, N'ê', 'e');
    SET @output = REPLACE(@output, N'ế', 'e');
    SET @output = REPLACE(@output, N'ề', 'e');
    SET @output = REPLACE(@output, N'ể', 'e');
    SET @output = REPLACE(@output, N'ễ', 'e');
    SET @output = REPLACE(@output, N'ệ', 'e');

    SET @output = REPLACE(@output, N'í', 'i');
    SET @output = REPLACE(@output, N'ì', 'i');
    SET @output = REPLACE(@output, N'ỉ', 'i');
    SET @output = REPLACE(@output, N'ĩ', 'i');
    SET @output = REPLACE(@output, N'ị', 'i');

    SET @output = REPLACE(@output, N'ó', 'o');
    SET @output = REPLACE(@output, N'ò', 'o');
    SET @output = REPLACE(@output, N'ỏ', 'o');
    SET @output = REPLACE(@output, N'õ', 'o');
    SET @output = REPLACE(@output, N'ọ', 'o');
    SET @output = REPLACE(@output, N'ô', 'o');
    SET @output = REPLACE(@output, N'ố', 'o');
    SET @output = REPLACE(@output, N'ồ', 'o');
    SET @output = REPLACE(@output, N'ổ', 'o');
    SET @output = REPLACE(@output, N'ỗ', 'o');
    SET @output = REPLACE(@output, N'ộ', 'o');
    SET @output = REPLACE(@output, N'ơ', 'o');
    SET @output = REPLACE(@output, N'ớ', 'o');
    SET @output = REPLACE(@output, N'ờ', 'o');
    SET @output = REPLACE(@output, N'ở', 'o');
    SET @output = REPLACE(@output, N'ỡ', 'o');
    SET @output = REPLACE(@output, N'ợ', 'o');

    SET @output = REPLACE(@output, N'ú', 'u');
    SET @output = REPLACE(@output, N'ù', 'u');
    SET @output = REPLACE(@output, N'ủ', 'u');
    SET @output = REPLACE(@output, N'ũ', 'u');
    SET @output = REPLACE(@output, N'ụ', 'u');
    SET @output = REPLACE(@output, N'ư', 'u');
    SET @output = REPLACE(@output, N'ứ', 'u');
    SET @output = REPLACE(@output, N'ừ', 'u');
    SET @output = REPLACE(@output, N'ử', 'u');
    SET @output = REPLACE(@output, N'ữ', 'u');
    SET @output = REPLACE(@output, N'ự', 'u');

    SET @output = REPLACE(@output, N'ý', 'y');
    SET @output = REPLACE(@output, N'ỳ', 'y');
    SET @output = REPLACE(@output, N'ỷ', 'y');
    SET @output = REPLACE(@output, N'ỹ', 'y');
    SET @output = REPLACE(@output, N'ỵ', 'y');

    SET @output = REPLACE(@output, N'đ', 'd');

    RETURN @output;
END;

UPDATE olist_ecom.STG.geolocation
SET geolocation_city = dbo.RemoveAccents(LOWER(LTRIM(RTRIM(geolocation_city))))


SELECT COUNT(DISTINCT geolocation_city) FROM olist_ecom.STG.geolocation -- 8010 -> 5970

SELECT DISTINCT
    geolocation_city
FROM
    olist_ecom.STG.geolocation
WHERE
    geolocation_city LIKE '%[^A-Z ]%';

-- remove special characters
CREATE FUNCTION dbo.RemoveSpecialChars (@input NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    WHILE PATINDEX('%[^a-zA-Z0-9 ]%', @input) > 0
        SET @input = STUFF(@input, PATINDEX('%[^a-z]%', @input), 1, '');

    RETURN @input;
END;


SELECT geolocation_city AS original,
       dbo.RemoveSpecialChars(dbo.RemoveAccents(geolocation_city)) AS cleaned
FROM olist_ecom.STG.geolocation
WHERE geolocation_city LIKE '%[^a-z]%';

CREATE FUNCTION dbo.NormalizeCity (@input NVARCHAR(255))
RETURNS NVARCHAR(255)
AS
BEGIN

    -- NULL handling

    IF @input IS NULL RETURN NULL;


    -- Step 1: Trim + lowercase + remove accents

    SET @input = LTRIM(RTRIM(@input));
    SET @input = LOWER(@input COLLATE Latin1_General_CI_AI);

    -- Step 2: Loop mỗi ký tự, chỉ giữ a-z

    DECLARE @output NVARCHAR(255) = '';
    DECLARE @i INT = 1;
    DECLARE @len INT = LEN(@input);
    DECLARE @c NCHAR(1);

    WHILE @i <= @len
    BEGIN
        SET @c = SUBSTRING(@input, @i, 1);

        -- chỉ giữ a-z
        IF @c COLLATE Latin1_General_BIN LIKE '[a-z]'
            SET @output += @c;
        ELSE
            -- thay ký tự khác bằng khoảng trắng (để không dính liền từ)
            SET @output += ' ';

        SET @i += 1;
    END;

    -- Step 3: Collapse multiple spaces

    WHILE CHARINDEX('  ', @output) > 0
        SET @output = REPLACE(@output, '  ', ' ');

    RETURN LTRIM(RTRIM(@output));
END;

UPDATE olist_ecom.STG.geolocation
SET geolocation_city = dbo.NormalizeCity(dbo.RemoveAccents(geolocation_city)) 
WHERE geolocation_city LIKE '%[^a-z]%'; --5970 -> 5931 distinct

-- order_items table
SELECT 
    COUNT(CASE WHEN TRY_CAST([shipping_limit_date] AS DATETIME) IS NULL AND [shipping_limit_date] IS NOT NULL THEN 1 END) AS invalid_shipping_limit_date,
    COUNT(CASE WHEN TRY_CAST([price] AS FLOAT) IS NULL OR [price] < 0 THEN 1 END) AS invalid_price,
    COUNT(CASE WHEN TRY_CAST([freight_value] AS FLOAT) IS NULL OR [freight_value] < 0 THEN 1 END) AS invalid_freight_value
FROM 
    [olist_ecom].[STG].[order_items];
	-- No issues
SELECT * FROM olist_ecom.STG.order_items WHERE freight_value = ''
-- order_payments table
SELECT * FROM olist_ecom.STG.order_payments WHERE payment_value = ''
SELECT 
    CASE 
        WHEN TRY_CAST([payment_sequential] AS INT) IS NULL THEN 'Invalid payment_sequential'
        ELSE NULL 
    END AS payment_sequential_issue,
    CASE 
        WHEN [payment_type] IS NULL OR LEN([payment_type]) = 0 THEN 'Invalid payment_type'
        ELSE NULL 
    END AS payment_type_issue,
    CASE 
        WHEN TRY_CAST([payment_installments] AS INT) IS NULL THEN 'Invalid payment_installments'
        ELSE NULL 
    END AS payment_installments_issue,
    CASE 
        WHEN TRY_CAST([payment_value] AS FLOAT) IS NULL OR [payment_value] < 0 THEN 'Invalid payment_value'
        ELSE NULL 
    END AS payment_value_issue,
    *
FROM 
    [olist_ecom].[STG].[order_payments]
WHERE 
    TRY_CAST([payment_sequential] AS INT) IS NULL
    OR [payment_type] IS NULL OR LEN([payment_type]) = 0
    OR TRY_CAST([payment_installments] AS INT) IS NULL
    OR TRY_CAST([payment_value] AS FLOAT) IS NULL OR [payment_value] < 0;
	-- no issues

-- order_reviews table
SELECT * FROM olist_ecom.STG.order_reviews

-- orders table
SELECT * FROM olist_ecom.STG.order

SELECT 
    COUNT(CASE WHEN [order_id] IS NULL OR LTRIM(RTRIM([order_id])) = '' THEN 1 END) AS invalid_order_id_count,
    COUNT(CASE WHEN [customer_id] IS NULL OR LTRIM(RTRIM([customer_id])) = '' THEN 1 END) AS invalid_customer_id_count,
    COUNT(CASE WHEN [order_status] IS NULL OR LTRIM(RTRIM([order_status])) = '' THEN 1 END) AS invalid_order_status_count,
    COUNT(CASE WHEN [order_status] NOT IN ('created', 'approved', 'shipped', 'delivered', 'canceled', 'invoiced', 'processing', 'unavailable') THEN 1 END) AS unexpected_order_status_count,
    COUNT(CASE WHEN [order_purchase_timestamp] IS NULL THEN 1 END) AS null_order_purchase_timestamp_count,
    COUNT(CASE WHEN [order_approved_at] IS NOT NULL AND [order_approved_at] < [order_purchase_timestamp] THEN 1 END) AS invalid_order_approved_at_count,
    COUNT(CASE WHEN [order_delivered_carrier_date] IS NOT NULL AND [order_delivered_carrier_date] < [order_approved_at] THEN 1 END) AS invalid_order_delivered_carrier_date_count,
    COUNT(CASE WHEN [order_delivered_customer_date] IS NOT NULL AND [order_delivered_customer_date] < [order_delivered_carrier_date] THEN 1 END) AS invalid_order_delivered_customer_date_count,
    COUNT(CASE WHEN [order_estimated_delivery_date] IS NOT NULL AND [order_estimated_delivery_date] < [order_purchase_timestamp] THEN 1 END) AS invalid_order_estimated_delivery_date_count
FROM 
    [olist_ecom].[STG].[orders];
	-- invalid_order_delivered_customer_date_count: 23
	-- invalid_order_delivered_carrier_date_count: 1359
	-- -> MISINPUTS
-- products table
SELECT * FROM olist_ecom.STG.products
SELECT COUNT(*) FROM olist_ecom.STG.products WHERE product_category_name = ''
	-- 623 missing category name
UPDATE olist_ecom.STG.products
SET product_category_name = 'others' WHERE product_category_name =''

SELECT * FROM olist_ecom.STG.products WHERE product_height_cm  IS NULL OR product_length_cm IS NULL OR product_width_cm IS NULL


-- sellers table
SELECT * FROM olist_ecom.STG.sellers
SELECT * FROM olist_ecom.raw.geolocation WHERE geolocation_zip_code_prefix = 22790
UPDATE olist_ecom.STG.sellers
SET seller_city = 'rio de janeiro' WHERE seller_id = 'ceb7b4fb9401cd378de7886317ad1b47'

