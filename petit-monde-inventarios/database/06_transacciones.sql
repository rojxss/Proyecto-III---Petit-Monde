-- =====================================================================
-- 06_transacciones.sql | Dueño: P3 (Lógica) | Fase 5
-- Rutinas ACID. Si algo falla, la excepción revierte todo.
-- =====================================================================
SET search_path = inventario, public;

-- Firmas acordadas (no cambiar sin avisar a P2):
--   sp_procesar_venta(...)          -- Checkout
--   sp_transferir_inventario(...)   -- Transferencia entre almacenes
-- Nota: una función PL/pgSQL ya corre dentro de una transacción; si se lanza
-- una excepción se hace ROLLBACK automático. Si prefieren BEGIN/COMMIT/ROLLBACK
-- explícitos, usar PROCEDURE + CALL.

-- TODO (P3)
