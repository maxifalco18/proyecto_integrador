-- copy of raw_schema_and_copy.sql (legacy kept at repo root)
SET client_min_messages = WARNING;

CREATE SCHEMA IF NOT EXISTS raw;

-- categories
DROP TABLE IF EXISTS raw.categories;
CREATE TABLE raw.categories (
  "CategoryID" text,
  "CategoryName" text
);
COPY raw.categories ("CategoryID","CategoryName")
FROM 'data/categories.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- cities
DROP TABLE IF EXISTS raw.cities;
CREATE TABLE raw.cities (
  "CityID" text,
  "CityName" text,
  "Zipcode" text,
  "CountryID" text
);
COPY raw.cities ("CityID","CityName","Zipcode","CountryID")
FROM 'data/cities.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- countries
DROP TABLE IF EXISTS raw.countries;
CREATE TABLE raw.countries (
  "CountryID" text,
  "CountryName" text,
  "CountryCode" text
);
COPY raw.countries ("CountryID","CountryName","CountryCode")
FROM 'data/countries.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- customers
DROP TABLE IF EXISTS raw.customers;
CREATE TABLE raw.customers (
  "CustomerID" text,
  "FirstName" text,
  "MiddleInitial" text,
  "LastName" text,
  "CityID" text,
  "Address" text
);
COPY raw.customers ("CustomerID","FirstName","MiddleInitial","LastName","CityID","Address")
FROM 'data/customers.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- employees
DROP TABLE IF EXISTS raw.employees;
CREATE TABLE raw.employees (
  "EmployeeID" text,
  "FirstName" text,
  "MiddleInitial" text,
  "LastName" text,
  "BirthDate" text,
  "Gender" text,
  "CityID" text,
  "HireDate" text
);
COPY raw.employees ("EmployeeID","FirstName","MiddleInitial","LastName","BirthDate","Gender","CityID","HireDate")
FROM 'data/employees.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- products
DROP TABLE IF EXISTS raw.products;
CREATE TABLE raw.products (
  "ProductID" text,
  "ProductName" text,
  "Price" text,
  "CategoryID" text,
  "Class" text,
  "ModifyDate" text,
  "Resistant" text,
  "IsAllergic" text,
  "VitalityDays" text
);
COPY raw.products ("ProductID","ProductName","Price","CategoryID","Class","ModifyDate","Resistant","IsAllergic","VitalityDays")
FROM 'data/products.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- sales
DROP TABLE IF EXISTS raw.sales;
CREATE TABLE raw.sales (
  "SalesID" text,
  "SalesPersonID" text,
  "CustomerID" text,
  "ProductID" text,
  "Quantity" text,
  "Discount" text,
  "TotalPrice" text,
  "SalesDate" text,
  "TransactionNumber" text
);
COPY raw.sales ("SalesID","SalesPersonID","CustomerID","ProductID","Quantity","Discount","TotalPrice","SalesDate","TransactionNumber")
FROM 'data/sales.csv' WITH (FORMAT csv, HEADER true, DELIMIT ',');

GRANT USAGE ON SCHEMA raw TO PUBLIC;
