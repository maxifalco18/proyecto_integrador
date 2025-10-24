# Avance 1 — Carga y exploración de datos en SQL

Este documento cubre exclusivamente el Avance 1 del Proyecto Integrador. Se cargaron datos crudos en SQL, se armó un staging limpio para analizarlos y se desarrollaron las consultas pedidas. Para cada consigna, se incluye la salida (captura/tablas) y una interpretación breve.

## Contenido del entregable y estructura del proyecto

- SQL (create/transform/load/analysis/ops)
  - Raw: `sql/01_raw/raw_load.sql`
  - Staging: `sql/02_stg/stg_transform.sql`
  - Modelo final: `sql/03_public/init_public.sql`, `sql/03_public/load_public.sql`
  - Análisis: `sql/04_analysis/analysis_queries.sql`
  - Operaciones: `sql/05_ops/triggers.sql`, `sql/05_ops/indexes.sql`
- Evidencias (salidas): `documentación/avance1_capturas.md` y `documentación/capturas_txt/`
- Datos CSV: `data/`
- Documentación de repo: `.gitignore`, `CONTRIBUTING.md`, `.github/pull_request_template.md`
 

Estructura actual (ruta base: `c:\Users\CTI23994\Dropbox\Data Engineering - HENRY\proyecto_integrador`):

```
/ (raíz)
├─ data/                       # CSV de entrada
├─ documentación/
│  ├─ avance1_capturas.md      # evidencias del avance
│  ├─ capturas_txt/            # salidas en texto (no se listan todas aquí)
│  └─ Consignas_Avances_1_2_3_UNIFICADO_v2.txt
├─ sql/
│  ├─ 01_raw/
│  │  └─ raw_load.sql
│  ├─ 02_stg/
│  │  └─ stg_transform.sql
│  ├─ 03_public/
│  │  ├─ init_public.sql
│  │  └─ load_public.sql
│  ├─ 04_analysis/
│  │  └─ analysis_queries.sql
│  └─ 05_ops/
│     ├─ indexes.sql
│     └─ triggers.sql
└─ README.md
```

## Consignas y resultados (con evidencia)

Fuente de consignas: `documentación/Consignas_Avances_1_2_3_UNIFICADO_v2.txt`

> PI 1 — CONSIGNA: Desarrollar las siguientes consultas SQL e incluir capturas con breve interpretación. Entregar el script completo utilizado.

---

### 1) Top 5 productos y vendedor top (+ repetición y umbral 10%)

> ¿Cuáles fueron los 5 productos más vendidos (por cantidad total), y cuál fue el vendedor que más unidades vendió de cada uno? ¿Hay algún vendedor que aparece más de una vez como el que más vendió un producto? ¿Algunos de estos vendedores representan más del 10% de la ventas de este producto?

Tabla (top 5 por unidades, vendedor top y % sobre el total):

| product_id | product_name             | total_qty | seller_name   | best_qty | best_pct |
|------------|--------------------------|-----------|---------------|----------|----------|
| 103        | Cream Of Tartar          | 200002    | Daphne King   | 10551    | 5.28%    |
| 179        | Yoghurt Tubes            | 199724    | Daphne King   | 10285    | 5.15%    |
| 161        | Longos - Chicken Wings   | 199659    | Jean Vang     | 10785    | 5.40%    |
| 47         | Thyme - Lemon; Fresh     | 198567    | Devon Brewer  | 11050    | 5.56%    |
| 280        | Onion Powder             | 198163    | Devon Brewer  | 10570    | 5.33%    |

Tabla (vendedores con ≥10% en los 5 productos top):

| product_id | product_name | salesperson_id | seller_name | qty | pct |
|------------|--------------|----------------|-------------|-----|-----|
| —          | —            | —              | —           | —   | —   |

Interpretación:
- Hay vendedores repetidos (Daphne King y Devon Brewer) en el top por producto.
- Ningún vendedor supera el 10% del total del producto; la venta está distribuida.

Evidencia: `documentación/capturas_txt/imagen1_top5_mejor_vendedor.txt`, `documentación/capturas_txt/imagen1_porcentaje_mejor_vendedor.txt`, `documentación/capturas_txt/imagen2_vendedores_mayor_10_por_ciento.txt`

---

### 2) Clientes únicos y proporción sobre el total

> Entre los 5 productos más vendidos, ¿cuántos clientes únicos compraron cada uno y qué proporción representa sobre el total de clientes?

Tabla (clientes únicos y % sobre el total de clientes):

| product_id | product_name             | unique_customers | total_customers | pct_of_total |
|------------|--------------------------|------------------|-----------------|--------------|
| 103        | Cream Of Tartar          | 14247            | 98759           | 14.43%       |
| 179        | Yoghurt Tubes            | 14066            | 98759           | 14.24%       |
| 161        | Longos - Chicken Wings   | 14252            | 98759           | 14.43%       |
| 47         | Thyme - Lemon; Fresh     | 14101            | 98759           | 14.28%       |
| 280        | Onion Powder             | 14058            | 98759           | 14.23%       |

Interpretación: ~14% de la base de clientes compró cada producto top → amplia adopción (no está concentrado en pocos clientes).

Evidencia: `documentación/capturas_txt/imagen2_clientes_unicos_y_proporcion.txt`

---

### 3) Proporción del producto dentro de su categoría (ventanas)

> ¿A qué categorías pertenecen los 5 productos más vendidos y qué proporción representan dentro del total de unidades vendidas de su categoría? Utiliza funciones de ventana…

Tabla (participación del producto dentro de su categoría):

| product_id | product_name             | category_name | product_units | category_units | pct_in_category |
|------------|--------------------------|---------------|---------------|----------------|-----------------|
| 179        | Yoghurt Tubes            | Seafood       | 199724        | 6996142        | 2.85%           |
| 161        | Longos - Chicken Wings   | Snails        | 199659        | 7199358        | 2.77%           |
| 280        | Onion Powder             | Beverages     | 198163        | 7393693        | 2.68%           |
| 47         | Thyme - Lemon; Fresh     | Poultry       | 198567        | 9159792        | 2.17%           |
| 103        | Cream Of Tartar          | Meat          | 200002        | 9721150        | 2.06%           |

Interpretación: los líderes explican ~2–3% de su categoría; categorías competitivas sin dominancia.

Evidencia: `documentación/capturas_txt/imagen2_proporcion_en_categoria.txt`

---

### 4) Top 10 del catálogo y ranking en su categoría (+ concentración)

> ¿Cuáles son los 10 productos con mayor cantidad de unidades vendidas en todo el catálogo y cuál es su posición dentro de su propia categoría? … ¿Qué observas sobre la concentración de ventas dentro de algunas categorías?

Tabla (top 10 global y ranking dentro de su categoría):

| product_id | product_name              | category_name | units  | category_rank |
|------------|---------------------------|---------------|--------|---------------|
| 103        | Cream Of Tartar           | Meat          | 200002 | 1             |
| 179        | Yoghurt Tubes             | Seafood       | 199724 | 1             |
| 161        | Longos - Chicken Wings    | Snails        | 199659 | 1             |
| 47         | Thyme - Lemon; Fresh      | Poultry       | 198567 | 1             |
| 280        | Onion Powder              | Beverages     | 198163 | 1             |
| 39         | Dried Figs                | Produce       | 198032 | 1             |
| 324        | Apricots - Dried          | Snails        | 198032 | 2             |
| 319        | Towels - Paper / Kraft    | Meat          | 198005 | 2             |
| 425        | Wine - Redchard Merritt   | Dairy         | 197969 | 1             |
| 184        | Hersey Shakes             | Poultry       | 197942 | 2             |

Tabla (top1 share y ratio top1/top2 por categoría — muestra de 10):

| category_name | product_top1 | top1_name                | category_units | units_top1 | units_top2 | top1_share_pct | top1_to_top2_ratio |
|---------------|--------------|--------------------------|----------------|------------|------------|----------------|--------------------|
| Grain         | 350          | Isomalt                  | 5433152        | 196760     | 196031     | 3.62%          | 1.00               |
| Dairy         | 425          | Wine - Redchard Merritt  | 6815143        | 197969     | 197725     | 2.90%          | 1.00               |
| Seafood       | 179          | Yoghurt Tubes            | 6996142        | 199724     | 196983     | 2.85%          | 1.01               |
| Shell fish    | 60           | Pepper - Paprika; Hungarian | 6983451     | 196743     | 196353     | 2.82%          | 1.00               |
| Snails        | 161          | Longos - Chicken Wings   | 7199358        | 199659     | 198032     | 2.77%          | 1.01               |
| Beverages     | 280          | Onion Powder             | 7393693        | 198163     | 197614     | 2.68%          | 1.00               |
| Produce       | 39           | Dried Figs               | 8368793        | 198032     | 197584     | 2.37%          | 1.00               |
| Cereals       | 331          | Cookies Cereal Nut       | 8735255        | 197343     | 196382     | 2.26%          | 1.00               |
| Poultry       | 47           | Thyme - Lemon; Fresh     | 9159792        | 198567     | 197942     | 2.17%          | 1.00               |
| Meat          | 103          | Cream Of Tartar          | 9721150        | 200002     | 198005     | 2.06%          | 1.01               |

Interpretación: varios top globales no dominan su categoría; la concentración es baja (top1 ~2–3% y razón top1/top2 ≈ 1).

Evidencia: `documentación/capturas_txt/imagen2_top10_y_ranking_categoria.txt`, `documentación/capturas_txt/imagen2_concentracion_por_categoria.txt`

## Checklist de validación

| Entregable | Qué se valida | Evidencia | Estado |
|---|---|---|---|
| Script SQL de análisis | Todas las consultas del Avance 1 ejecutables | [`sql/04_analysis/analysis_queries.sql`](sql/04_analysis/analysis_queries.sql) | Cumple |
| Capturas e interpretaciones | Salidas por consigna con breve análisis | [`documentación/avance1_capturas.md`](documentación/avance1_capturas.md) | Cumple |
| Top 5 + vendedor top | Tabla en README + archivo de evidencia | Tabla en README; [`imagen1_top5_mejor_vendedor.txt`](documentación/capturas_txt/imagen1_top5_mejor_vendedor.txt) | Cumple |
| ¿Vendedor ≥10%? ¿Se repite? | 0 casos ≥10%; vendedores repetidos visibles | Tabla en README; [`imagen2_vendedores_mayor_10_por_ciento.txt`](documentación/capturas_txt/imagen2_vendedores_mayor_10_por_ciento.txt) | Cumple |
| Clientes únicos y proporción | % ~14% en cada producto top | Tabla en README; [`imagen2_clientes_unicos_y_proporcion.txt`](documentación/capturas_txt/imagen2_clientes_unicos_y_proporcion.txt) | Cumple |
| Proporción por categoría (ventanas) | Participación ~2–3% por producto | Tabla en README; [`imagen2_proporcion_en_categoria.txt`](documentación/capturas_txt/imagen2_proporcion_en_categoria.txt) | Cumple |
| Top 10 global y ranking por categoría | Ranking por categoría correcto | Tabla en README; [`imagen2_top10_y_ranking_categoria.txt`](documentación/capturas_txt/imagen2_top10_y_ranking_categoria.txt) | Cumple |
| Concentración por categoría | top1_share y top1/top2 ratio | Tabla en README; [`imagen2_concentracion_por_categoria.txt`](documentación/capturas_txt/imagen2_concentracion_por_categoria.txt) | Cumple |
| Trigger e índices (Avance 1) | Creación OK y evidencia | [`sql/05_ops/triggers.sql`](sql/05_ops/triggers.sql), [`sql/05_ops/indexes.sql`](sql/05_ops/indexes.sql) | Cumple |
| Notebook Avance 1 | No requerido (sin evidencia) | — | No aplica |

## Decisiones técnicas (breve)

- El análisis se realizó sobre `stg.*_clean` para asegurar integridad referencial y tipos correctos.
- Agregaciones con `SUM()` y conteos distintos; funciones de ventana (`ROW_NUMBER`, `RANK`, `SUM() OVER (PARTITION BY ...)`) para rankings y proporciones por categoría.
- Salidas capturadas con `psql`; algunos acentos pueden verse como "?" por encoding de consola.

## Conclusiones del Avance 1

- Se cumplieron todas las consultas y análisis del Avance 1, con evidencias y breves interpretaciones.
- La adopción de los productos top es amplia (base de clientes grande) y los líderes no dominan sus categorías.
- Pendiente opcional: entregar un notebook con los mismos resultados (si la cátedra lo pide) y mejorar el formateo de salidas (UTF-8) para capturas.

## Avance 2 (en rama develop)

- Trigger de monitoreo: `sql/05_ops/triggers.sql` (registra productos que superan 200.000 unidades tras un INSERT en `stg.sales_clean`).
- Índices para optimizar consultas del Avance 1: `sql/05_ops/indexes.sql`.
- Inserción de prueba + verificación del trigger: `sql/05_ops/avance2_insert_and_check.sql`.
- Consultas para medir performance (EXPLAIN ANALYZE): `sql/04_analysis/av2_perf_query1_top_seller.sql`, `sql/04_analysis/av2_perf_query2_unique_customers.sql`.
- Evidencias y guía: `documentación/avance2_capturas.md`.

Cómo ejecutar (resumen):
1) Cargar staging si hace falta: `sql/01_raw/raw_load.sql` y `sql/02_stg/stg_transform.sql`.
2) Crear/actualizar trigger: `sql/05_ops/triggers.sql`.
3) Insertar venta de prueba y verificar el monitoreo: `sql/05_ops/avance2_insert_and_check.sql`.
4) Medir performance de las dos consultas con EXPLAIN (ANALYZE, BUFFERS) antes y después de `sql/05_ops/indexes.sql` y guardar salidas en `documentación/capturas_txt/`.
