-- copy of init.sql (legacy kept at repo root)
SET client_encoding TO 'UTF8';

-- 1) Dimensiones
CREATE TABLE IF NOT EXISTS countries (
  CountryID     INTEGER PRIMARY KEY,
  CountryName   TEXT NOT NULL,
  CountryCode   TEXT
);

CREATE TABLE IF NOT EXISTS cities (
  CityID     INTEGER PRIMARY KEY,
  CityName   TEXT NOT NULL,
  Zipcode    INTEGER,
  CountryID  INTEGER NOT NULL REFERENCES countries(CountryID)
);

CREATE TABLE IF NOT EXISTS categories (
  CategoryID   INTEGER PRIMARY KEY,
  CategoryName TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS products (
  ProductID     INTEGER PRIMARY KEY,
  ProductName   TEXT NOT NULL,
  Price         NUMERIC(12,2),
  CategoryID    INTEGER REFERENCES categories(CategoryID),
  Class         TEXT,
  ModifyDate    TIMESTAMP NULL,
  Resistant     TEXT,
  IsAllergic    TEXT,
  VitalityDays  INTEGER
);

CREATE TABLE IF NOT EXISTS employees (
  EmployeeID     INTEGER PRIMARY KEY,
  FirstName      TEXT NOT NULL,
  MiddleInitial  TEXT,
  LastName       TEXT NOT NULL,
  BirthDate      TIMESTAMP NULL,
  Gender         CHAR(1),
  CityID         INTEGER REFERENCES cities(CityID),
  HireDate       TIMESTAMP NULL
);

CREATE TABLE IF NOT EXISTS customers (
  CustomerID     INTEGER PRIMARY KEY,
  FirstName      TEXT NOT NULL,
  MiddleInitial  TEXT,
  LastName       TEXT NOT NULL,
  CityID         INTEGER REFERENCES cities(CityID),
  Address        TEXT
);

-- 2) Hecho
CREATE TABLE IF NOT EXISTS sales (
  SalesID            INTEGER PRIMARY KEY,
  SalesPersonID      INTEGER REFERENCES employees(EmployeeID),
  CustomerID         INTEGER REFERENCES customers(CustomerID),
  ProductID          INTEGER REFERENCES products(ProductID),
  Quantity           INTEGER,
  Discount           NUMERIC(6,3),
  TotalPrice         NUMERIC(14,2),
  SalesDate          TIMESTAMP NULL,
  TransactionNumber  TEXT
);
