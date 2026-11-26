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
SET ROLE db_admin;

-- Así está el almacén 1 antes de intentar la venta
SELECT producto_id, cantidad FROM stock_almacen WHERE almacen_id = 1 AND producto_id IN (1, 2) ORDER BY producto_id;

-- El monitor sí alcanza, pero 5000 teclados no. La venta completa tiene que caerse.
DO $$
BEGIN
    PERFORM sp_procesar_venta(1, 'Prueba 3', ARRAY[1, 2], ARRAY[2, 5000]);
    RAISE NOTICE 'Prueba 3: la venta pasó y no debía pasar.';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Prueba 3: la venta se canceló como se esperaba -> %', SQLERRM;
END $$;

-- Las cantidades tienen que ser las mismas de arriba, ni el monitor se descontó
SELECT producto_id, cantidad FROM stock_almacen WHERE almacen_id = 1 AND producto_id IN (1, 2) ORDER BY producto_id;
SELECT COUNT(*) AS ventas_de_prueba_3 FROM ventas WHERE cliente = 'Prueba 3';
RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 4 | Rol: db_admin
-- Objetivo: Ejecutar sp_reporte_valoracion_reabastecimiento(1, 10.0)
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 4: Ejecutar sp_reporte_valoracion_reabastecimiento(1, 10.0)'; END $$;
SET ROLE db_admin;
-- Deberían salir el escritorio como Agotado y el teclado como Crítico arriba de la lista
SELECT * FROM sp_reporte_valoracion_reabastecimiento(1, 10.0);
RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 5 | Rol: db_admin
-- Objetivo: Transferir 5 unidades del almacén 1 al 2 -> COMMIT, doble movimiento
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 5: Transferir 5 unidades del almacén 1 al 2 -> COMMIT, doble movimiento'; END $$;
SET ROLE db_admin;

SELECT almacen_id, cantidad FROM stock_almacen WHERE producto_id = 1 ORDER BY almacen_id;

-- Se mueven 5 monitores de Almacén Central a Bodega Norte
BEGIN;
SELECT sp_transferir_inventario(1, 2, 1, 5) AS transferencia_creada;
COMMIT;

-- El central baja 5, la bodega norte aparece con 5 (antes no tenía monitores)
SELECT almacen_id, cantidad FROM stock_almacen WHERE producto_id = 1 ORDER BY almacen_id;

-- Tienen que salir dos movimientos: la SALIDA del 1 y la ENTRADA del 2
SELECT m.transferencia_id, m.almacen_id, m.tipo, m.cantidad
FROM movimientos_inventario m
WHERE m.transferencia_id = (SELECT MAX(t.transferencia_id) FROM transferencias t)
ORDER BY m.movimiento_id;
RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 6 | Rol: db_admin
-- Objetivo: Transferir 5000 unidades -> ROLLBACK, inventario intacto
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 6: Transferir 5000 unidades -> ROLLBACK, inventario intacto'; END $$;
SET ROLE db_admin;

SELECT almacen_id, cantidad FROM stock_almacen WHERE producto_id = 1 ORDER BY almacen_id;
SELECT COUNT(*) AS transferencias_antes FROM transferencias;

DO $$
BEGIN
    PERFORM sp_transferir_inventario(1, 2, 1, 5000);
    RAISE NOTICE 'Prueba 6: la transferencia pasó y no debía pasar.';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Prueba 6: la transferencia se canceló como se esperaba -> %', SQLERRM;
END $$;

-- Nada cambió: mismas cantidades y la misma cantidad de transferencias
SELECT almacen_id, cantidad FROM stock_almacen WHERE producto_id = 1 ORDER BY almacen_id;
SELECT COUNT(*) AS transferencias_despues FROM transferencias;
RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 9 | Rol: inventory_manager
-- Objetivo: Venta de 2 unidades en su almacén -> COMMIT, movimiento SALIDA
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 9: Venta de 2 unidades en su almacén -> COMMIT, movimiento SALIDA'; END $$;
-- El gestor tiene asignada la Bodega Norte (almacén 2); vende 2 mousepads
SET ROLE inventory_manager;

SELECT cantidad AS mousepads_antes FROM stock_almacen WHERE almacen_id = 2 AND producto_id = 5;

BEGIN;
SELECT sp_procesar_venta(2, 'Prueba 9', ARRAY[5], ARRAY[2]) AS venta_creada;
COMMIT;

SELECT cantidad AS mousepads_despues FROM stock_almacen WHERE almacen_id = 2 AND producto_id = 5;

-- La venta deja su salida en la bitácora
SELECT m.venta_id, m.almacen_id, m.producto_id, m.tipo, m.cantidad, m.usuario
FROM movimientos_inventario m
JOIN ventas v ON v.venta_id = m.venta_id
WHERE v.cliente = 'Prueba 9';
RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 13 | Rol: auditor
-- Objetivo: Ejecutar sp_reporte_rotacion_inventario sin restricciones de permisos
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 13: Ejecutar sp_reporte_rotacion_inventario sin restricciones de permisos'; END $$;
SET ROLE auditor;
-- Primer trimestre de 2026, categoría Electrónica (incluye monitores y periféricos)
SELECT * FROM sp_reporte_rotacion_inventario('2026-01-01', '2026-03-31', 2);
RESET ROLE;

-- ---------------------------------------------------------------------
-- PRUEBA 14 | Rol: auditor
-- Objetivo: Rango de fechas inválido -> error controlado con mensaje del enunciado
-- ---------------------------------------------------------------------
DO $$ BEGIN RAISE NOTICE '>>> PRUEBA 14: Rango de fechas inválido -> error controlado con mensaje del enunciado'; END $$;
SET ROLE auditor;
-- Se atrapa el error para que el script siga, pero se muestra el mensaje tal cual
DO $$
BEGIN
    PERFORM * FROM sp_reporte_rotacion_inventario('2026-05-01', '2026-01-01', NULL);
    RAISE NOTICE 'Prueba 14: el reporte corrió y no debía.';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Prueba 14: ERROR: %', SQLERRM;
END $$;
RESET ROLE;
