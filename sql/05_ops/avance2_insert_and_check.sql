-- Avance 2 — Inserción de venta de prueba y verificación de trigger de monitoreo
-- Requisitos:
--  - Debe existir el esquema y tablas de stg (ver sql/02_stg/stg_transform.sql)
--  - Debe estar creado el trigger (ver sql/05_ops/triggers.sql)
--
-- Acción: Insertar una venta (sales_clean) para el vendedor 9, cliente 84, producto 103,
--         por 1.876 unidades y valor total 1200. Luego consultar la tabla de monitoreo.

BEGIN;

-- 1) Genera un nuevo SalesID (MAX + 1) para evitar colisiones
WITH next_id AS (
  SELECT COALESCE(MAX(sales_id), 0) + 1 AS new_id FROM stg.sales_clean
)
INSERT INTO stg.sales_clean (
  sales_id, salesperson_id, customer_id, product_id,
  quantity, discount, total_price, sales_date, transaction_number
)
SELECT
  n.new_id,  -- sales_id
  9,         -- salesperson_id
  84,        -- customer_id
  103,       -- product_id
  1876,      -- quantity
  NULL,      -- discount (no requerido en Avance 2)
  1200,      -- total_price (valor de la venta)
  now(),     -- sales_date
  'AV2-TEST' -- transaction_number
FROM next_id n;

-- 2) Consultar tabla de monitoreo para el producto 103
SELECT *
FROM stg.product_sales_monitor
WHERE product_id = 103;

COMMIT;