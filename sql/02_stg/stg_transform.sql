-- copy of stg.sql (legacy kept at repo root)
-- Crear schema stg
CREATE SCHEMA IF NOT EXISTS stg;


-- 1) tabla intermedia con ProductID/CustomerID TRIMmeados (no toca raw)
DROP TABLE IF EXISTS stg.sales_trimmed;
CREATE TABLE stg.sales_trimmed AS
SELECT
*,
TRIM("ProductID") AS productid_trimmed,
TRIM("CustomerID") AS customerid_trimmed
FROM raw.sales;
ANALYZE stg.sales_trimmed;


-- 2) tabla limpia (casts exitosos)
DROP TABLE IF EXISTS stg.sales_clean;
CREATE TABLE stg.sales_clean AS
SELECT
NULLIF(TRIM(s."SalesID"),'')::bigint AS sales_id,
NULLIF(TRIM(s."SalesPersonID"),'')::int AS salesperson_id,
NULLIF(TRIM(s."CustomerID"),'')::int AS customer_id,
NULLIF(TRIM(s."ProductID"),'')::int AS product_id,
NULLIF(TRIM(s."Quantity"),'')::int AS quantity,
CASE WHEN TRIM(s."Discount") ~ '^[0-9]+(\\.[0-9]+)?$' THEN TRIM(s."Discount")::numeric ELSE NULL END AS discount,
CASE WHEN TRIM(s."TotalPrice") ~ '^[0-9]+(\\.[0-9]+)?$' THEN TRIM(s."TotalPrice")::numeric ELSE NULL END AS total_price,
CASE WHEN TRIM(s."SalesDate") ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN TRIM(s."SalesDate")::timestamp ELSE NULL END AS sales_date,
TRIM(s."TransactionNumber")::text AS transaction_number
FROM raw.sales s
WHERE NULLIF(TRIM(s."SalesID"),'') IS NOT NULL
AND NULLIF(TRIM(s."ProductID"),'') IS NOT NULL
AND NULLIF(TRIM(s."CustomerID"),'') IS NOT NULL;


-- 3) tabla bad (filas que requieren atención: producto huérfano, fecha vacía, total no numérico)
DROP TABLE IF EXISTS stg.sales_bad;
CREATE TABLE stg.sales_bad AS
SELECT s.*
FROM raw.sales s
LEFT JOIN raw.products p ON TRIM(s."ProductID") = p."ProductID"
WHERE p."ProductID" IS NULL
OR TRIM(s."SalesDate") = ''
OR NOT (TRIM(s."TotalPrice") ~ '^[0-9]+(\\.[0-9]+)?$');


-- 4) Staging para Products
-- Tabla limpia para productos
DROP TABLE IF EXISTS stg.products_clean;
CREATE TABLE stg.products_clean AS
SELECT
    NULLIF(TRIM("ProductID"), '')::int AS product_id,
    TRIM("ProductName")::text AS product_name,
    CASE WHEN TRIM("Price") ~ '^[0-9]+(\\.[0-9]+)?$' THEN TRIM("Price")::numeric(12,2) ELSE NULL END AS price,
    NULLIF(TRIM("CategoryID"), '')::int AS category_id,
    TRIM("Class")::text AS class,
    -- Asumiendo que ModifyDate puede tener formatos inconsistentes, se valida antes de castear
    CASE 
        WHEN TRIM("ModifyDate") ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN TRIM("ModifyDate")::timestamp 
        ELSE NULL 
    END AS modify_date,
    TRIM("Resistant")::text AS resistant,
    TRIM("IsAllergic")::text AS is_allergic,
    NULLIF(TRIM("VitalityDays"), '')::int AS vitality_days
FROM raw.products
WHERE NULLIF(TRIM("ProductID"), '') IS NOT NULL;

-- Tabla para productos con datos problemáticos
DROP TABLE IF EXISTS stg.products_bad;
CREATE TABLE stg.products_bad AS
SELECT p.*
FROM raw.products p
LEFT JOIN raw.categories c ON TRIM(p."CategoryID") = c."CategoryID"
WHERE NULLIF(TRIM(p."ProductID"), '') IS NULL
   OR c."CategoryID" IS NULL;


-- 5) Staging para Customers
-- Tabla limpia para clientes
DROP TABLE IF EXISTS stg.customers_clean;
CREATE TABLE stg.customers_clean AS
SELECT
    NULLIF(TRIM("CustomerID"), '')::int AS customer_id,
    TRIM("FirstName")::text AS first_name,
    TRIM("MiddleInitial")::text AS middle_initial,
    TRIM("LastName")::text AS last_name,
    NULLIF(TRIM("CityID"), '')::int AS city_id,
    TRIM("Address")::text AS address
FROM raw.customers
WHERE NULLIF(TRIM("CustomerID"), '') IS NOT NULL;

-- Tabla para clientes con datos problemáticos
DROP TABLE IF EXISTS stg.customers_bad;
CREATE TABLE stg.customers_bad AS
SELECT cu.*
FROM raw.customers cu
LEFT JOIN raw.cities ci ON TRIM(cu."CityID") = ci."CityID"
WHERE NULLIF(TRIM(cu."CustomerID"), '') IS NULL
   OR ci."CityID" IS NULL;


-- 6) Staging para Employees
-- Tabla limpia para empleados
DROP TABLE IF EXISTS stg.employees_clean;
CREATE TABLE stg.employees_clean AS
SELECT
    NULLIF(TRIM("EmployeeID"), '')::int AS employee_id,
    TRIM("FirstName")::text AS first_name,
    TRIM("MiddleInitial")::text AS middle_initial,
    TRIM("LastName")::text AS last_name,
    CASE WHEN TRIM("BirthDate") ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN TRIM("BirthDate")::timestamp ELSE NULL END AS birth_date,
    TRIM("Gender")::char(1) AS gender,
    NULLIF(TRIM("CityID"), '')::int AS city_id,
    CASE WHEN TRIM("HireDate") ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN TRIM("HireDate")::timestamp ELSE NULL END AS hire_date
FROM raw.employees
WHERE NULLIF(TRIM("EmployeeID"), '') IS NOT NULL;

-- Tabla para empleados con datos problemáticos
DROP TABLE IF EXISTS stg.employees_bad;
CREATE TABLE stg.employees_bad AS
SELECT e.*
FROM raw.employees e
LEFT JOIN raw.cities c ON TRIM(e."CityID") = c."CityID"
WHERE NULLIF(TRIM(e."EmployeeID"), '') IS NULL
   OR c."CityID" IS NULL;


-- 7) Staging para Cities
-- Tabla limpia para ciudades
DROP TABLE IF EXISTS stg.cities_clean;
CREATE TABLE stg.cities_clean AS
SELECT
    NULLIF(TRIM("CityID"), '')::int AS city_id,
    TRIM("CityName")::text AS city_name,
    NULLIF(TRIM("Zipcode"), '')::int AS zipcode,
    NULLIF(TRIM("CountryID"), '')::int AS country_id
FROM raw.cities
WHERE NULLIF(TRIM("CityID"), '') IS NOT NULL;

-- Tabla para ciudades con datos problemáticos
DROP TABLE IF EXISTS stg.cities_bad;
CREATE TABLE stg.cities_bad AS
SELECT ci.*
FROM raw.cities ci
LEFT JOIN raw.countries co ON TRIM(ci."CountryID") = co."CountryID"
WHERE NULLIF(TRIM(ci."CityID"), '') IS NULL
   OR co."CountryID" IS NULL;

-- Analizar y crear índices
ANALYZE stg.cities_clean;
ANALYZE stg.cities_bad;
CREATE INDEX IF NOT EXISTS idx_stg_cities_clean_countryid ON stg.cities_clean(country_id);

-- 8) Staging para Countries
-- Tabla limpia para países
DROP TABLE IF EXISTS stg.countries_clean;
CREATE TABLE stg.countries_clean AS
SELECT
    NULLIF(TRIM("CountryID"), '')::int AS country_id,
    TRIM("CountryName")::text AS country_name,
    TRIM("CountryCode")::text AS country_code
FROM raw.countries
WHERE NULLIF(TRIM("CountryID"), '') IS NOT NULL;

-- No se crea tabla _bad para countries al ser la tabla de mayor jerarquía en este caso.

-- Analizar
ANALYZE stg.countries_clean;

-- 9) Staging para Categories
-- Tabla limpia para categorías
DROP TABLE IF EXISTS stg.categories_clean;
CREATE TABLE stg.categories_clean AS
SELECT
    NULLIF(TRIM("CategoryID"), '')::int AS category_id,
    TRIM("CategoryName")::text AS category_name
FROM raw.categories
WHERE NULLIF(TRIM("CategoryID"), '') IS NOT NULL;

-- No se crea tabla _bad para categories al no tener dependencias externas en este script.

-- Analizar
ANALYZE stg.categories_clean;


ANALYZE stg.sales_clean;
ANALYZE stg.sales_bad;
ANALYZE stg.products_clean;
ANALYZE stg.products_bad;
ANALYZE stg.customers_clean;
ANALYZE stg.customers_bad;
ANALYZE stg.employees_clean;
ANALYZE stg.employees_bad;


-- indices en stg para acelerar consultas (opcional)
CREATE INDEX IF NOT EXISTS idx_stg_sales_clean_productid ON stg.sales_clean(product_id);
CREATE INDEX IF NOT EXISTS idx_stg_sales_bad_productid ON stg.sales_bad((TRIM("ProductID")));
CREATE INDEX IF NOT EXISTS idx_stg_products_clean_categoryid ON stg.products_clean(category_id);
CREATE INDEX IF NOT EXISTS idx_stg_customers_clean_cityid ON stg.customers_clean(city_id);
CREATE INDEX IF NOT EXISTS idx_stg_employees_clean_cityid ON stg.employees_clean(city_id);
