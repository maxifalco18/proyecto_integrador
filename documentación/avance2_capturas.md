# Avance 2 — Optimización y monitoreo en SQL

Este documento reúne las evidencias del Avance 2: trigger de monitoreo, inserción de venta de prueba y creación de índices con comparación de performance.

## Consignas (texto literal)

Ver `documentación/Consignas_Avances_1_2_3_UNIFICADO_v2.txt` (sección AVANCE 2).

## Scripts relevantes

- Trigger de monitoreo: `sql/05_ops/triggers.sql`
- Índices para consultas seleccionadas: `sql/05_ops/indexes.sql`
- Inserción + verificación del trigger: `sql/05_ops/avance2_insert_and_check.sql`

## Evidencias sugeridas (capturas)

1) Trigger de monitoreo
- Crear/ejecutar: `sql/05_ops/triggers.sql`
- Verificar estructura: `\d stg.product_sales_monitor` y `\d+ stg.sales_clean`
- Consulta esperada: `SELECT * FROM stg.product_sales_monitor WHERE product_id = 103;`

2) Inserción de venta de prueba
- Ejecutar: `sql/05_ops/avance2_insert_and_check.sql`
- Guardar salida de la consulta final (monitor) en `documentación/capturas_txt/av2_trigger_monitor.txt`

3) Índices — Antes y después
- Ejecutar dos consultas del Avance 1 (por ejemplo: top vendedor por producto; clientes únicos por producto)
- Capturar tiempos antes y después de `sql/05_ops/indexes.sql`
- Guardar salidas: `documentación/capturas_txt/av2_perf_consulta1_{antes,despues}.txt`, `av2_perf_consulta2_{antes,despues}.txt`

## Notas
- El trigger se dispara sobre `stg.sales_clean` (AFTER INSERT) y actualiza `stg.product_sales_monitor` cuando el acumulado del producto supera 200.000 unidades.
- Los índices creados optimizan joins y agrupaciones por `product_id` combinadas con `salesperson_id` y `customer_id`. Ajustar si se eligen otras consultas.
