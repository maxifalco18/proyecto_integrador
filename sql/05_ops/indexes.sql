-- copy of indices_avance1.sql (legacy kept at repo root)
-- Índices para optimización de consultas seleccionadas
CREATE INDEX IF NOT EXISTS idx_sales_product_salesperson ON stg.sales_clean(product_id, salesperson_id);
CREATE INDEX IF NOT EXISTS idx_sales_product_customer ON stg.sales_clean(product_id, customer_id);
