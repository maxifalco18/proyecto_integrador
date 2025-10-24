-- Avance 2 — Consulta 1: Vendedor top por producto
-- Medir con EXPLAIN (ANALYZE, BUFFERS) antes y después de aplicar índices de sql/05_ops/indexes.sql
-- Sugerencia: probar con product_id en top y también con un id arbitrario.

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
WITH product_totals AS (
  SELECT s.product_id, s.salesperson_id, SUM(s.quantity) AS qty
  FROM stg.sales_clean s
  GROUP BY s.product_id, s.salesperson_id
), best_seller AS (
  SELECT pt.product_id,
         pt.salesperson_id,
         pt.qty,
         ROW_NUMBER() OVER (PARTITION BY pt.product_id ORDER BY pt.qty DESC) AS rn
  FROM product_totals pt
)
SELECT b.product_id,
       b.salesperson_id,
       b.qty AS best_qty
FROM best_seller b
WHERE b.rn = 1
  AND b.product_id = 103;  -- cambiar si se desea medir otro producto
