-- =====================================================================
-- 08_pruebas_seguridad.sql | Dueño: P2 | Pruebas de seguridad (RBAC / RLS)
-- REGLA DEL ENUNCIADO: cada prueba debe imprimir su identificador con
-- RAISE NOTICE ANTES de la llamada; si no, se ignora en la revisión.
-- Cambiar al rol de la prueba con SET ROLE y volver con RESET ROLE.
-- =====================================================================
SET search_path = inventario, public;

-- ---------------------------------------------------------------------
-- PRUEBA 1 | Rol: db_admin
-- Objetivo: Control total sobre estructura, usuarios y rutinas gerenciales
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 1: Control total sobre estructura, usuarios y rutinas gerenciales'; END $$;
-- TODO: SET ROLE ...; ejecutar; RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 2 | Rol: inventory_manager
-- Objetivo: Intentar crear un rol / modificar DDL -> permission denied to create role
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 2: Intentar crear un rol / modificar DDL -> permission denied to create role'; END $$;
-- TODO: SET ROLE ...; ejecutar; RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 7 | Rol: inventory_manager
-- Objetivo: RLS filtra existencias a la sucursal asignada (Almacén 2)
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 7: RLS filtra existencias a la sucursal asignada (Almacén 2)'; END $$;
-- TODO: SET ROLE ...; ejecutar; RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 8 | Rol: inventory_manager
-- Objetivo: No ve ni modifica registros de otra bodega (Almacén 1)
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 8: No ve ni modifica registros de otra bodega (Almacén 1)'; END $$;
-- TODO: SET ROLE ...; ejecutar; RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 10 | Rol: inventory_manager (sin permiso analítico)
-- Objetivo: No puede ejecutar sp_reporte_valoracion_reabastecimiento
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 10: No puede ejecutar sp_reporte_valoracion_reabastecimiento'; END $$;
-- TODO: SET ROLE ...; ejecutar; RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 11 | Rol: auditor
-- Objetivo: INSERT en productos -> permission denied for table productos
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 11: INSERT en productos -> permission denied for table productos'; END $$;
-- TODO: SET ROLE ...; ejecutar; RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 12 | Rol: auditor
-- Objetivo: SELECT sobre movimientos de inventario funciona
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 12: SELECT sobre movimientos de inventario funciona'; END $$;
-- TODO: SET ROLE ...; ejecutar; RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 15 | Rol: auditor
-- Objetivo: No puede ejecutar venta ni transferencia
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 15: No puede ejecutar venta ni transferencia'; END $$;
-- TODO: SET ROLE ...; ejecutar; RESET ROLE;
