-- Avance 2 — Consulta 2: Clientes únicos por producto (y % sobre el total)
-- Medir con EXPLAIN (ANALYZE, BUFFERS) antes y después de aplicar índices de sql/05_ops/indexes.sql

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
WITH total_customers AS (
  SELECT COUNT(DISTINCT customer_id) AS total_customers
  FROM stg.sales_clean
), product_customers AS (
  SELECT s.product_id,
         COUNT(DISTINCT s.customer_id) AS unique_customers
  FROM stg.sales_clean s
  GROUP BY s.product_id
)
SELECT pc.product_id,
       pc.unique_customers,
       tc.total_customers,
       ROUND((pc.unique_customers::numeric / NULLIF(tc.total_customers,0)) * 100, 2) AS pct_of_total
FROM product_customers pc
CROSS JOIN total_customers tc
WHERE pc.product_id = 103;  -- cambiar si se desea medir otro producto
