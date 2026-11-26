# Contrato de esquema (acuerdos compartidos)

> Se cierra en la primera reunión. Después **se congela**: cualquier cambio se avisa al grupo y se actualiza aquí.

## Decisiones

| # | Decisión | Propuesta inicial | Acordado |
|---|---|---|---|
| 1 | Schema y nombres de tablas/columnas | schema `inventario`; tablas listadas abajo | ☐ |
| 2 | `stock_optimo` en `stock_almacen` | Sí (no existe en el Anexo 1) | ☐ |
| 3 | Precio para `valor_total_salidas_usd` (Reporte 2) | Precio guardado en el movimiento (histórico) | ☐ |
| 4 | Firmas de funciones | ver abajo | ☐ |
| 5 | Seguridad de funciones | `SECURITY INVOKER` en todas | ☐ |
| 6 | Contexto de sesión para RLS | tabla `usuario_almacen` (usuario → almacén) | ☐ |
| 7 | Quién ejecuta transferencias | `db_admin` e `inventory_manager` con ambos almacenes asignados | ☐ |
| 8 | Estados de transferencia | `EN_TRANSITO`, `RECIBIDA` | ☐ |
| 9 | Orden de archivos SQL | el de `database/run_all.sql` | ☐ |

## Tablas (propuesta; P1 completa columnas y tipos)

| Tabla | Clave primaria | Columna de almacén (para RLS) |
|---|---|---|
| `categorias` | `categoria_id` | — |
| `proveedores` | `proveedor_id` | — |
| `almacenes` | `almacen_id` | — |
| `productos` | `producto_id` (`sku` UNIQUE) | — |
| `stock_almacen` | (`producto_id`, `almacen_id`) | `almacen_id` |
| `ventas` / `detalle_venta` | `venta_id` / (`venta_id`, `linea`) | `almacen_id` |
| `transferencias` | `transferencia_id` | `almacen_origen_id`, `almacen_destino_id` |
| `movimientos_inventario` | `movimiento_id` | `almacen_id` |
| `usuario_almacen` (la crea P2) | (`usuario`, `almacen_id`) | `almacen_id` |

## Firmas de funciones

```sql
sp_reporte_valoracion_reabastecimiento(p_almacen_id INT, p_margen_alerta NUMERIC)
sp_reporte_rotacion_inventario(p_fecha_inicio DATE, p_fecha_fin DATE, p_categoria_id INT)
sp_procesar_venta(p_almacen_id INT, p_cliente VARCHAR, p_productos INT[], p_cantidades INT[])  -- devuelve INT (venta_id)
sp_transferir_inventario(p_origen_id INT, p_destino_id INT, p_producto_id INT, p_cantidad INT)   -- devuelve INT (transferencia_id)
```

## Notas sobre el enunciado

- El Reporte 1 aparece con dos nombres; usamos `sp_reporte_valoracion_reabastecimiento` (el de las pruebas).
- Mensaje de error exacto del Reporte 2: `La fecha de inicio (…) no puede ser posterior a la fecha fin (…). Operación cancelada.`
