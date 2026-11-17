-- =====================================================================
-- 00_reset.sql | Dueño: compartido (cambios solo con aviso al equipo)
-- Deja la BD limpia para poder ejecutar todo desde cero.
-- =====================================================================
DROP SCHEMA IF EXISTS inventario CASCADE;

DO $$
DECLARE r TEXT;
BEGIN
  FOREACH r IN ARRAY ARRAY['db_admin','inventory_manager','auditor'] LOOP
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
      EXECUTE format('DROP OWNED BY %I', r);
      EXECUTE format('DROP ROLE %I', r);
    END IF;
  END LOOP;
END $$;
