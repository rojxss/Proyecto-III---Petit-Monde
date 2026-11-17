-- =====================================================================
-- 01_esquema.sql | Dueño: P1 (Modelo de datos) | Fase 1
-- Esquema normalizado hasta 3FNBC. Todo vive en el schema "inventario".
-- Debe respetar docs/contrato-esquema.md (nombres de tablas y columnas).
-- =====================================================================
CREATE SCHEMA inventario;
SET search_path = inventario, public;

-- TODO (P1): tablas, en orden de dependencia. Lista sugerida:
--   categorias (con jerarquía: categoria_padre_id)
--   proveedores
--   almacenes
--   productos            (sku UNIQUE, costo_unitario, precio_venta, categoria_id, proveedor_id)
--   stock_almacen        (producto_id, almacen_id, cantidad, stock_minimo, stock_optimo, ubicación/pasillo/estante)
--   transferencias       (almacen_origen_id, almacen_destino_id, fecha, usuario, estado EN_TRANSITO/RECIBIDA)
--   ventas / detalle_venta
--   movimientos_inventario (tipo ENTRADA/SALIDA, producto, almacén, cantidad, fecha, usuario, referencias)
-- Recordar: PK, FK, CHECK (cantidad >= 0, etc.), UNIQUE, NOT NULL, NUMERIC para dinero.
