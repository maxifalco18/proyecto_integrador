-- copy of load.sql (legacy kept at repo root)
SET client_encoding TO 'UTF8';

TRUNCATE TABLE countries, cities, categories, products, employees, customers, sales RESTART IDENTITY CASCADE;

INSERT INTO countries (CountryID, CountryName, CountryCode)
SELECT country_id, country_name, country_code
FROM stg.countries_clean;

INSERT INTO cities (CityID, CityName, Zipcode, CountryID)
SELECT city_id, city_name, zipcode, country_id
FROM stg.cities_clean;

INSERT INTO categories (CategoryID, CategoryName)
SELECT category_id, category_name
FROM stg.categories_clean;

INSERT INTO products (ProductID, ProductName, Price, CategoryID, Class, ModifyDate, Resistant, IsAllergic, VitalityDays)
SELECT product_id, product_name, price, category_id, class, modify_date, resistant, is_allergic, vitality_days
FROM stg.products_clean;

INSERT INTO employees (EmployeeID, FirstName, MiddleInitial, LastName, BirthDate, Gender, CityID, HireDate)
SELECT employee_id, first_name, middle_initial, last_name, birth_date, gender, city_id, hire_date
FROM stg.employees_clean;

INSERT INTO customers (CustomerID, FirstName, MiddleInitial, LastName, CityID, Address)
SELECT customer_id, first_name, middle_initial, last_name, city_id, address
FROM stg.customers_clean;

INSERT INTO sales (SalesID, SalesPersonID, CustomerID, ProductID, Quantity, Discount, TotalPrice, SalesDate, TransactionNumber)
SELECT sales_id, salesperson_id, customer_id, product_id, quantity, discount, total_price, sales_date, transaction_number
FROM stg.sales_clean;

ANALYZE countries; ANALYZE cities; ANALYZE categories; ANALYZE products; ANALYZE employees; ANALYZE customers; ANALYZE sales;
