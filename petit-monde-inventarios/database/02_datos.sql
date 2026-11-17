-- =====================================================================
-- 02_datos.sql | Dueño: P1 | Datos de prueba
-- Se carga ANTES de activar RLS (04_rls.sql).
-- Requisitos que otras personas necesitan (ver division-de-trabajo.md):
--   * Stock en almacén 1 (Central) y 2 (Norte)               -> pruebas 7, 8, 9
--   * Productos con stock bajo, en cero y sobre el mínimo     -> Reporte 1 (Agotado/Crítico/Óptimo)
--   * Movimientos SALIDA 2026-01-01..2026-03-31 en Electrónica
--     (ELE-101: 45 uds, ELE-102: 28, ELE-105: 3)              -> Reporte 2 (ejemplo del enunciado)
--   * Un producto con stock < 5000 en almacén 1               -> pruebas 3 y 6
--   * Los 6 productos del Anexo 1 como base
-- =====================================================================
SET search_path = inventario, public;

-- TODO (P1): INSERTs
