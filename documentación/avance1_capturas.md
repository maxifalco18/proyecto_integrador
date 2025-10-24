# Avance 1 – Capturas de salida

Este documento compila las salidas ("capturas") de las consultas y scripts ejecutados en PostgreSQL (contenedor `pg-integrador`).

> Nota: Las tablas se muestran en formato de salida de `psql`.

---

## Imagen 1

### 1) Top 5 productos y su mejor vendedor

```
Producto        | Mejor Vendedor | Unidades Vendidas por el Vendedor 
------------------------+----------------+-----------------------------------
 Cream Of Tartar        | Daphne King    |                             10551
 Longos - Chicken Wings | Jean Vang      |                             10785
 Onion Powder           | Devon Brewer   |                             10570
 Thyme - Lemon; Fresh   | Devon Brewer   |                             11050
 Yoghurt Tubes          | Daphne King    |                             10285
(5 rows)
```

### 2) % que representa el mejor vendedor del producto

```
        Producto        | Mejor Vendedor | Unidades Vendidas (Vendedor) | Unidades Totales (Producto) | Porcentaje del Total (%) 
------------------------+----------------+------------------------------+-----------------------------+--------------------------
 Thyme - Lemon; Fresh   | Devon Brewer   |                        11050 |                      198567 |   5.56487231010187997000
 Longos - Chicken Wings | Jean Vang      |                        10785 |                      199659 |   5.40170991540576683200
 Onion Powder           | Devon Brewer   |                        10570 |                      198163 |   5.33399272316224522200
 Cream Of Tartar        | Daphne King    |                        10551 |                      200002 |   5.27544724552754472500
 Yoghurt Tubes          | Daphne King    |                        10285 |                      199724 |   5.14960645691053654000
(5 rows)
```

---

## Imagen 2

### 3) Clientes únicos por producto top y proporción sobre total de clientes

```
      product_name      | unique_customers_per_product | total_unique_customers | percentage_of_total_customers 
------------------------+------------------------------+------------------------+-------------------------------
 Cream Of Tartar        |                        14247 |                  98759 |       14.42602699500804989900
 Yoghurt Tubes          |                        14066 |                  98759 |       14.24275255926042183500
 Longos - Chicken Wings |                        14252 |                  98759 |       14.43108982472483520500
 Thyme - Lemon; Fresh   |                        14101 |                  98759 |       14.27819236727791897400
 Onion Powder           |                        14058 |                  98759 |       14.23465203171356534600
(5 rows)
```

### 4) Categoría de los 5 productos top y su proporción en la categoría

```
        Producto        | Categoría | Unidades Vendidas (Producto) | Unidades Vendidas (Categoría) | Proporción en la Categoría (%) 
------------------------+----------+------------------------------+-------------------------------+---------------------------------
 Cream Of Tartar        | Meat     |                       200002 |                        9721150 |           2.05739032933346363300
 Yoghurt Tubes          | Seafood  |                       199724 |                        6996142 |           2.85477338796153651500
 Longos - Chicken Wings | Snails   |                       199659 |                        7199358 |           2.77328895159818417100
 Thyme - Lemon; Fresh   | Poultry  |                       198567 |                        9159792 |           2.16781123414156129300
 Onion Powder           | Beverages|                       198163 |                        7393693 |           2.68016267378155949900
(5 rows)
```

### 5) Top 10 del catálogo y ranking dentro de su categoría

```
        Producto         | Categoría | Unidades Vendidas | Ranking General | Ranking en Categoría 
-------------------------+----------+-------------------+-----------------+----------------------
 Cream Of Tartar         | Meat     |            200002 |               1 |                     1
 Yoghurt Tubes           | Seafood  |            199724 |               2 |                     1
 Longos - Chicken Wings  | Snails   |            199659 |               3 |                     1
 Thyme - Lemon; Fresh    | Poultry  |            198567 |               4 |                     1
 Onion Powder            | Beverages|            198163 |               5 |                     1
 Dried Figs              | Produce  |            198032 |               6 |                     1
 Apricots - Dried        | Snails   |            198032 |               6 |                     2
 Towels - Paper / Kraft  | Meat     |            198005 |               8 |                     2
 Wine - Redchard Merritt | Dairy    |            197969 |               9 |                     1
 Hersey Shakes           | Poultry  |            197942 |              10 |                     2
(10 rows)
```

### 6) Participación de vendedores > 10% en productos top

```
 Producto | Vendedor | % del Producto | Veces en Top5 (cualquier rol) 
----------+----------+----------------+-------------------------------
(0 rows)
```

### 7) Adopción vs. concentración (Top 10 y Top 1% de clientes)

```
        Producto        | % Top 10 Clientes | % Top 1% Clientes |   Diagnóstico   
------------------------+-------------------+-------------------+------------------
 Cream Of Tartar        |              1.26 |              4.47 | Amplia adopción
 Thyme - Lemon; Fresh   |              0.36 |              3.60 | Amplia adopción
 Longos - Chicken Wings |              0.36 |              3.61 | Amplia adopción
 Yoghurt Tubes          |              0.36 |              3.59 | Amplia adopción
 Onion Powder           |              0.36 |              3.60 | Amplia adopción
(5 rows)
```

### 8) Concentración por categoría: líder vs. competencia

```
 Categoría  | Líder                      | Unidades Líder | Segundo                            | Unidades Segundo | %Líder/Categoría | Ratio Líder/Segundo | Diagnóstico
------------+----------------------------+----------------+------------------------------------+------------------+------------------+---------------------+-------------
 Grain       | Isomalt                   |          196760| Grenadine                          |           196031 |             3.62 |                1.00 | Categoría competitiva
 Dairy       | Wine - Redchard Merritt   |          197969| Beef - Short Loin                  |           197725 |             2.90 |                1.00 | Categoría competitiva
 Seafood     | Yoghurt Tubes             |          199724| Tea - Decaf Lipton                 |           196983 |             2.85 |                1.01 | Categoría competitiva
 Shell fish  | Pepper - Paprika; Hungarian|         196743| Appetizer - Mini Egg Roll; Shrimp  |           196353 |             2.82 |                1.00 | Categoría competitiva
 Snails      | Longos - Chicken Wings    |          199659| Apricots - Dried                   |           198032 |             2.77 |                1.01 | Categoría competitiva
 Beverages   | Onion Powder              |          198163| Bouq All Italian - Primerba        |           197614 |             2.68 |                1.00 | Categoría competitiva
 Produce     | Dried Figs                |          198032| Beef - Chuck; Boneless             |           197584 |             2.37 |                1.00 | Categoría competitiva
 Cereals     | Cookies Cereal Nut        |          197343| Sugar - Fine                       |           196382 |             2.26 |                1.00 | Categoría competitiva
 Poultry     | Thyme - Lemon; Fresh      |          198567| Hersey Shakes                      |           197942 |             2.17 |                1.00 | Categoría competitiva
 Meat        | Cream Of Tartar           |          200002| Towels - Paper / Kraft             |           198005 |             2.06 |                1.01 | Categoría competitiva
 Confections | Mussels - Cultivated      |          197318| Wine - Red; Cooking                |           197020 |             1.78 |                1.00 | Categoría competitiva
(11 rows)
```

---

## Imagen 3 – Trigger de monitoreo

Salida tras ejecutar `triggers_avance1.sql` (creación + inserción de prueba + consulta de monitoreo):

```
 product_id |  product_name   | total_qty |         checked_at
------------+-----------------+-----------+----------------------------
        103 | Cream Of Tartar |    200002 | 2025-10-24 19:35:52.626412
(1 row)
```

---

## Imagen 4 – Índices y rendimiento (EXPLAIN ANALYZE)

1) Clientes únicos por producto:

- Consulta: `SELECT product_id, COUNT(DISTINCT customer_id) FROM stg.sales_clean GROUP BY product_id;`
- Antes de índice (tiempo real capturado): ~46000.900 ms
- Después de índice `(product_id, customer_id)` – plan y tiempo:

```
 GroupAggregate  (cost=0.43..208159.48 rows=453 width=12) (actual time=15.191..6789.028 rows=469 loops=1)
   Group Key: product_id
   ->  Index Only Scan using idx_sales_product_customer on sales_clean  (cost=0.43..174364.32 rows=6758126 width=8) (actual time=0.157..4961.426 rows=6758126 loops=1)
         Heap Fetches: 51
 Planning Time: 1.324 ms
 JIT:
   Functions: 3
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 0.988 ms, Inlining 0.000 ms, Optimization 0.534 ms, Emission 5.311 ms, Total 6.833 ms
 Execution Time: 6851.496 ms
```

2) Mejor vendedor por producto (consulta resumida con CTEs): tiempos representativos capturados

- Antes: ~2582.419 ms
- Después de índices: ~4548.790 ms (no mejora en este dataset por naturaleza del plan; se mantienen agregaciones pesadas)

Plan (después):

```
 Hash Join  (cost=269908.77..270171.85 rows=52 width=16) (actual time=4452.285..4452.449 rows=5 loops=1)
   Hash Cond: ((s.product_id = seller.product_id) AND (s.qty = (max(seller.qty))))
   CTE seller
     ->  HashAggregate  (cost=269537.11..269641.30 rows=10419 width=16) (actual time=4451.875..4452.120 rows=115 loops=1)
           Group Key: s_1.product_id, s_1.salesperson_id
           Batches: 1  Memory Usage: 417kB
           ->  Nested Loop  (cost=120298.17..268977.66 rows=74593 width=12) (actual time=3074.191..4346.733 rows=76245 loops=1)
                 ->  Limit  (cost=120130.12..120130.13 rows=5 width=12) (actual time=3054.045..3054.191 rows=5 loops=1)
                       ->  Sort  (cost=120130.12..120131.25 rows=453 width=12) (actual time=2972.620..2972.755 rows=5 loops=1)
                             Sort Key: (sum(sales_clean.quantity)) DESC
                             Sort Method: top-N heapsort  Memory: 25kB
                             ->  Finalize GroupAggregate  (cost=120007.83..120122.59 rows=453 width=12) (actual time=2971.604..2972.527 rows=469 loops=1)
                                   Group Key: sales_clean.product_id
                                   ->  Gather Merge  (cost=120007.83..120113.53 rows=906 width=12) (actual time=2971.526..2972.093 rows=1373 loops=1)
                                         Workers Planned: 2
                                         Workers Launched: 2
                                         ->  Sort  (cost=119007.80..119008.94 rows=453 width=12) (actual time=2886.552..2886.603 rows=458 loops=3)
                                               Sort Key: sales_clean.product_id
                                               Sort Method: quicksort  Memory: 49kB
                                               ->  Partial HashAggregate  (cost=118983.29..118987.82 rows=453 width=12) (actual time=2883.080..2883.192 rows=458 loops=3)
                                                     Group Key: sales_clean.product_id
                                                     ->  Parallel Seq Scan on sales_clean  (cost=0.00..104903.86 rows=2815886 width=8) (actual time=0.033..1031.430 rows=2252709 loops=3)
                 ->  Bitmap Heap Scan on sales_clean s_1  (cost=168.05..29620.31 rows=14919 width=12) (actual time=20.719..247.549 rows=15249 loops=5)
                       Recheck Cond: (product_id = sales_clean.product_id)
                       ->  Bitmap Index Scan on idx_stg_sales_clean_productid
```

---

Fin de capturas.
