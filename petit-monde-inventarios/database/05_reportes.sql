-- =====================================================================
-- 05_reportes.sql | Dueño: P3 (Lógica) | Fase 4
-- Funciones RETURNS TABLE (equivalente a los Stored Procedures en PostgreSQL).
-- Todas SECURITY INVOKER (por defecto) para que RLS se aplique.
-- =====================================================================
SET search_path = inventario, public;

-- Firmas acordadas (no cambiar sin avisar a P2: él hace los GRANT EXECUTE):
--   sp_reporte_valoracion_reabastecimiento(p_almacen_id INT, p_margen_alerta NUMERIC)
--   sp_reporte_rotacion_inventario(p_fecha_inicio DATE, p_fecha_fin DATE, p_categoria_id INT)

-- Checklist de calidad:
--   [ ] tabla temporal + lógica CASE/IF (Agotado, Crítico, Óptimo)
--   [ ] COALESCE en todas las operaciones aritméticas
--   [ ] validación de parámetros con RAISE EXCEPTION (mensaje exacto del enunciado)
--   [ ] EXCEPTION WHEN ... (equivalente a TRY...CATCH)
--   [ ] (opcional) bitácora de reportes generados

-- TODO (P3)
