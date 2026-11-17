-- =====================================================================
-- 04_rls.sql | Dueño: P2 (Seguridad) | Fase 3
-- Row-Level Security por almacén.
-- Mecanismo definido en docs/contrato-esquema.md (decisión #6):
--   tabla inventario.usuario_almacen (usuario, almacen_id)  y/o
--   current_setting('app.almacen_id').
-- Recordar: USING y WITH CHECK; las funciones deben ser SECURITY INVOKER.
-- =====================================================================
SET search_path = inventario, public;

-- TODO (P2):
--   CREATE TABLE usuario_almacen (...);
--   ALTER TABLE ... ENABLE ROW LEVEL SECURITY;
--   CREATE POLICY ... ON stock_almacen / movimientos_inventario / ventas / transferencias ...
--   db_admin: bypass autorizado (BYPASSRLS o política permisiva).
