-- =====================================================================
-- 07_permisos.sql | Dueño: P2 (Seguridad) | Fase 2 (GRANT/REVOKE)
-- Se ejecuta DESPUÉS de crear tablas y funciones.
-- Principio de mínimo privilegio: denegar por defecto, otorgar lo necesario.
-- =====================================================================
SET search_path = inventario, public;

-- TODO (P2):
--   REVOKE ALL ON SCHEMA/TABLES/FUNCTIONS ... FROM PUBLIC;
--   REVOKE EXECUTE ON FUNCTION ... FROM PUBLIC;   -- ¡por defecto PUBLIC puede ejecutar!
--   GRANT por rol según docs/p2-seguridad/matriz-rbac.md
--     reportes valoración  -> db_admin, inventory_manager
--     reporte rotación     -> db_admin, inventory_manager, auditor
--     venta                -> inventory_manager, db_admin
--     transferencia        -> inventory_manager, db_admin
