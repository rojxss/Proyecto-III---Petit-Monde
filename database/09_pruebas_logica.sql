-- =====================================================================
-- 09_pruebas_logica.sql | Dueño: P3 | Pruebas de reportes y transacciones
-- REGLA DEL ENUNCIADO: cada prueba debe imprimir su identificador con
-- RAISE NOTICE ANTES de la llamada; si no, se ignora en la revisión.
-- Cambiar al rol de la prueba con SET ROLE y volver con RESET ROLE.
-- =====================================================================
SET search_path = inventario, public;

-- ---------------------------------------------------------------------
-- PRUEBA 3 | Rol: db_admin
-- Objetivo: Venta que excede existencias -> excepción y ROLLBACK, inventario intacto
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 3: Venta que excede existencias -> excepción y ROLLBACK, inventario intacto'; END $$;
-- TODO: SET ROLE ...; ejecutar; RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 4 | Rol: db_admin
-- Objetivo: Ejecutar sp_reporte_valoracion_reabastecimiento(1, 10.0)
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 4: Ejecutar sp_reporte_valoracion_reabastecimiento(1, 10.0)'; END $$;
-- TODO: SET ROLE ...; ejecutar; RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 5 | Rol: db_admin
-- Objetivo: Transferir 5 unidades del almacén 1 al 2 -> COMMIT, doble movimiento
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 5: Transferir 5 unidades del almacén 1 al 2 -> COMMIT, doble movimiento'; END $$;
-- TODO: SET ROLE ...; ejecutar; RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 6 | Rol: db_admin
-- Objetivo: Transferir 5000 unidades -> ROLLBACK, inventario intacto
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 6: Transferir 5000 unidades -> ROLLBACK, inventario intacto'; END $$;
-- TODO: SET ROLE ...; ejecutar; RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 9 | Rol: inventory_manager
-- Objetivo: Venta de 2 unidades en su almacén -> COMMIT, movimiento SALIDA
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 9: Venta de 2 unidades en su almacén -> COMMIT, movimiento SALIDA'; END $$;
-- TODO: SET ROLE ...; ejecutar; RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 13 | Rol: auditor
-- Objetivo: Ejecutar sp_reporte_rotacion_inventario sin restricciones de permisos
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 13: Ejecutar sp_reporte_rotacion_inventario sin restricciones de permisos'; END $$;
-- TODO: SET ROLE ...; ejecutar; RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 14 | Rol: auditor
-- Objetivo: Rango de fechas inválido -> error controlado con mensaje del enunciado
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 14: Rango de fechas inválido -> error controlado con mensaje del enunciado'; END $$;
-- TODO: SET ROLE ...; ejecutar; RESET ROLE;
