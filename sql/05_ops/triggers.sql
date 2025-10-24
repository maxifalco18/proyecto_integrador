-- copy of triggers_avance1.sql (legacy kept at repo root)
-- Monitoreo de productos que superan 200.000 unidades vendidas
CREATE SCHEMA IF NOT EXISTS stg;

CREATE TABLE IF NOT EXISTS stg.product_sales_monitor (
    product_id int PRIMARY KEY,
    product_name text,
    total_qty bigint,
    checked_at timestamp without time zone DEFAULT now()
);

CREATE OR REPLACE FUNCTION stg.fn_monitor_product_threshold()
RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    WITH prod AS (
        SELECT NEW.product_id AS product_id
    ), totals AS (
        SELECT p.product_id,
               p.product_name,
               SUM(s.quantity) AS total_qty
        FROM prod pr
        JOIN stg.sales_clean s ON s.product_id = pr.product_id
        JOIN stg.products_clean p ON p.product_id = pr.product_id
        GROUP BY p.product_id, p.product_name
    )
    INSERT INTO stg.product_sales_monitor(product_id, product_name, total_qty, checked_at)
    SELECT t.product_id, t.product_name, t.total_qty, now()
    FROM totals t
    WHERE t.total_qty >= 200000
    ON CONFLICT (product_id)
    DO UPDATE SET total_qty = EXCLUDED.total_qty, checked_at = EXCLUDED.checked_at;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_monitor_sales ON stg.sales_clean;
CREATE TRIGGER trg_monitor_sales
AFTER INSERT ON stg.sales_clean
FOR EACH ROW
EXECUTE FUNCTION stg.fn_monitor_product_threshold();
