-- copy of consultas_analisis.sql (legacy kept at repo root)
-- See root file for detailed comments; this is a synchronized duplicate for structured repo layout.

-- 1) Top 5 productos y mejor vendedor
WITH Top5Products AS (
    SELECT product_id
    FROM stg.sales_clean
    GROUP BY product_id
    ORDER BY SUM(quantity) DESC
    LIMIT 5
), RankedSellers AS (
    SELECT s.product_id, s.salesperson_id, SUM(s.quantity) AS total_quantity_by_seller,
           ROW_NUMBER() OVER(PARTITION BY s.product_id ORDER BY SUM(s.quantity) DESC) as seller_rank
    FROM stg.sales_clean s
    WHERE s.product_id IN (SELECT product_id FROM Top5Products)
    GROUP BY s.product_id, s.salesperson_id
)
SELECT p.product_name AS "Producto",
       (e.first_name || ' ' || e.last_name) AS "Mejor Vendedor",
       rs.total_quantity_by_seller AS "Unidades Vendidas por el Vendedor"
FROM RankedSellers rs
JOIN stg.products_clean p ON rs.product_id = p.product_id
JOIN stg.employees_clean e ON rs.salesperson_id = e.employee_id
WHERE rs.seller_rank = 1
ORDER BY p.product_name;

-- 2) % que representa el mejor vendedor del producto
WITH Top5Products AS (
    SELECT product_id
    FROM stg.sales_clean
    GROUP BY product_id
    ORDER BY SUM(quantity) DESC
    LIMIT 5
), ProductTotalSales AS (
    SELECT product_id, SUM(quantity) as total_product_sales
    FROM stg.sales_clean
    WHERE product_id IN (SELECT product_id FROM Top5Products)
    GROUP BY product_id
), RankedSellers AS (
    SELECT s.product_id, s.salesperson_id, SUM(s.quantity) AS total_quantity_by_seller,
           ROW_NUMBER() OVER(PARTITION BY s.product_id ORDER BY SUM(s.quantity) DESC) as seller_rank
    FROM stg.sales_clean s
    WHERE s.product_id IN (SELECT product_id FROM Top5Products)
    GROUP BY s.product_id, s.salesperson_id
)
SELECT p.product_name AS "Producto",
       (e.first_name || ' ' || e.last_name) AS "Mejor Vendedor",
       rs.total_quantity_by_seller AS "Unidades Vendidas (Vendedor)",
       pts.total_product_sales AS "Unidades Totales (Producto)",
       (rs.total_quantity_by_seller::numeric / pts.total_product_sales) * 100 AS "Porcentaje del Total (%)"
FROM RankedSellers rs
JOIN stg.products_clean p ON rs.product_id = p.product_id
JOIN stg.employees_clean e ON rs.salesperson_id = e.employee_id
JOIN ProductTotalSales pts ON rs.product_id = pts.product_id
WHERE rs.seller_rank = 1
ORDER BY "Porcentaje del Total (%)" DESC;

-- 3) Clientes únicos por producto top y proporción sobre total clientes
WITH Top5Products AS (
    SELECT p.product_name, p.product_id, SUM(s.quantity) AS total_quantity
    FROM stg.sales_clean s
    JOIN stg.products_clean p ON s.product_id = p.product_id
    GROUP BY p.product_name, p.product_id
    ORDER BY total_quantity DESC
    LIMIT 5
), TotalUniqueCustomers AS (
    SELECT COUNT(DISTINCT customer_id) as total_count
    FROM stg.customers_clean
)
SELECT t5.product_name,
       COUNT(DISTINCT s.customer_id) AS unique_customers_per_product,
       (SELECT total_count FROM TotalUniqueCustomers) AS total_unique_customers,
       (COUNT(DISTINCT s.customer_id)::DECIMAL / (SELECT total_count FROM TotalUniqueCustomers)) * 100 AS percentage_of_total_customers
FROM Top5Products t5
JOIN stg.sales_clean s ON t5.product_id = s.product_id
GROUP BY t5.product_name, t5.total_quantity
ORDER BY t5.total_quantity DESC;

-- 4) Proporción de los 5 productos top dentro de su categoría
WITH ProductSales AS (
    SELECT product_id, SUM(quantity) AS total_quantity
    FROM stg.sales_clean
    GROUP BY product_id
), CategorySales AS (
    SELECT p.product_name, c.category_name, ps.total_quantity,
           SUM(ps.total_quantity) OVER (PARTITION BY p.category_id) as total_category_quantity,
           ROW_NUMBER() OVER (ORDER BY ps.total_quantity DESC) as overall_rank
    FROM ProductSales ps
    JOIN stg.products_clean p ON ps.product_id = p.product_id
    JOIN stg.categories_clean c ON p.category_id = c.category_id
)
SELECT product_name AS "Producto",
       category_name AS "Categoría",
       total_quantity AS "Unidades Vendidas (Producto)",
       total_category_quantity AS "Unidades Vendidas (Categoría)",
       (total_quantity::DECIMAL / total_category_quantity) * 100 AS "Proporción en la Categoría (%)"
FROM CategorySales
WHERE overall_rank <= 5
ORDER BY total_quantity DESC;

-- 5) Top 10 catálogo y ranking dentro de su categoría
WITH ProductSales AS (
    SELECT product_id, SUM(quantity) AS total_quantity
    FROM stg.sales_clean
    GROUP BY product_id
), ProductRanking AS (
    SELECT p.product_name, c.category_name, ps.total_quantity,
           RANK() OVER (PARTITION BY p.category_id ORDER BY ps.total_quantity DESC) as category_rank,
           RANK() OVER (ORDER BY ps.total_quantity DESC) as overall_rank
    FROM ProductSales ps
    JOIN stg.products_clean p ON ps.product_id = p.product_id
    JOIN stg.categories_clean c ON p.category_id = c.category_id
)
SELECT product_name AS "Producto",
       category_name AS "Categoría",
       total_quantity AS "Unidades Vendidas",
       overall_rank AS "Ranking General",
       category_rank AS "Ranking en Categoría"
FROM ProductRanking
WHERE overall_rank <= 10
ORDER BY overall_rank;

-- 6) Participación de vendedores > 10% en productos top
WITH Top5Products AS (
    SELECT product_id
    FROM stg.sales_clean
    GROUP BY product_id
    ORDER BY SUM(quantity) DESC
    LIMIT 5
), ProductTotals AS (
    SELECT product_id, SUM(quantity) AS total_qty
    FROM stg.sales_clean
    WHERE product_id IN (SELECT product_id FROM Top5Products)
    GROUP BY product_id
), SellerProduct AS (
    SELECT s.product_id, s.salesperson_id, SUM(s.quantity) AS qty_by_seller
    FROM stg.sales_clean s
    WHERE s.product_id IN (SELECT product_id FROM Top5Products)
    GROUP BY s.product_id, s.salesperson_id
), SellerShare AS (
    SELECT sp.product_id, sp.salesperson_id, sp.qty_by_seller, pt.total_qty,
           (sp.qty_by_seller::numeric / pt.total_qty) * 100 AS pct
    FROM SellerProduct sp
    JOIN ProductTotals pt USING (product_id)
)
SELECT p.product_name AS "Producto",
       (e.first_name || ' ' || e.last_name) AS "Vendedor",
       ROUND(ss.pct, 2) AS "% del Producto",
       COUNT(*) OVER (PARTITION BY ss.salesperson_id) AS "Veces en Top5 (cualquier rol)"
FROM SellerShare ss
JOIN stg.products_clean p ON ss.product_id = p.product_id
JOIN stg.employees_clean e ON ss.salesperson_id = e.employee_id
WHERE ss.pct >= 10
ORDER BY "% del Producto" DESC, p.product_name;

-- 7) Adopción vs concentración (Top 10 y Top 1% clientes)
WITH Top5Products AS (
    SELECT product_id
    FROM stg.sales_clean
    GROUP BY product_id
    ORDER BY SUM(quantity) DESC
    LIMIT 5
), CustomerSales AS (
    SELECT s.product_id, s.customer_id, SUM(s.quantity) AS qty
    FROM stg.sales_clean s
    WHERE s.product_id IN (SELECT product_id FROM Top5Products)
    GROUP BY s.product_id, s.customer_id
), RankedCust AS (
    SELECT cs.*, ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY qty DESC) AS rn,
           COUNT(*) OVER (PARTITION BY product_id) AS n_cust,
           SUM(qty) OVER (PARTITION BY product_id) AS total_prod_qty
    FROM CustomerSales cs
), Agg AS (
    SELECT product_id,
           (SUM(CASE WHEN rn <= 10 THEN qty ELSE 0 END)::numeric / MAX(total_prod_qty)) * 100 AS pct_top10,
           (SUM(CASE WHEN rn <= GREATEST(1, (n_cust * 0.01)::int) THEN qty ELSE 0 END)::numeric / MAX(total_prod_qty)) * 100 AS pct_top1pct
    FROM RankedCust
    GROUP BY product_id
)
SELECT p.product_name AS "Producto",
       ROUND(a.pct_top10, 2) AS "% Top 10 Clientes",
       ROUND(a.pct_top1pct, 2) AS "% Top 1% Clientes",
       CASE WHEN a.pct_top10 >= 40 OR a.pct_top1pct >= 25 THEN 'Concentrado' ELSE 'Amplia adopción' END AS "Diagnóstico"
FROM Agg a
JOIN stg.products_clean p ON a.product_id = p.product_id
ORDER BY "% Top 10 Clientes" DESC;

-- 8) Concentración por categoría: líder vs segundo
WITH ProductSales AS (
    SELECT p.category_id, p.product_id, p.product_name, SUM(s.quantity) AS qty
    FROM stg.sales_clean s
    JOIN stg.products_clean p ON s.product_id = p.product_id
    GROUP BY p.category_id, p.product_id, p.product_name
), Ranked AS (
    SELECT category_id, product_id, product_name, qty,
           RANK() OVER (PARTITION BY category_id ORDER BY qty DESC) AS rnk,
           SUM(qty) OVER (PARTITION BY category_id) AS cat_total
    FROM ProductSales
)
SELECT c.category_name AS "Categoría",
       r1.product_name AS "Líder",
       r1.qty AS "Unidades Líder",
       r2.product_name AS "Segundo",
       r2.qty AS "Unidades Segundo",
       ROUND((r1.qty::numeric / r1.cat_total) * 100, 2) AS "%Líder/Categoría",
       ROUND((r1.qty::numeric / NULLIF(r2.qty,0)) , 2) AS "Ratio Líder/Segundo",
       CASE WHEN (r1.qty::numeric / r1.cat_total) >= 0.5 THEN 'Líder indiscutido' ELSE 'Categoría competitiva' END AS "Diagnóstico"
FROM (SELECT * FROM Ranked WHERE rnk = 1) r1
JOIN (SELECT * FROM Ranked WHERE rnk = 2) r2 USING (category_id)
JOIN stg.categories_clean c ON r1.category_id = c.category_id
ORDER BY "%Líder/Categoría" DESC;
