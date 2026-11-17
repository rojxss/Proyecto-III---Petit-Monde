-- =====================================================================
-- run_all.sql : reconstruye toda la BD desde cero, en orden lógico.
-- Se ejecuta con:  npm run db:reset   (o: bash scripts/db-run.sh)
-- build-entrega.sh lee las líneas \i de este archivo para armar el .sql final.
-- Mantener el ORDEN: cada archivo solo depende de los anteriores.
-- =====================================================================
\set ON_ERROR_STOP on

\i 00_reset.sql
\i 01_esquema.sql
\i 02_datos.sql
\i 03_roles.sql
\i 04_rls.sql
\i 05_reportes.sql
\i 06_transacciones.sql
\i 07_permisos.sql
\i 08_pruebas_seguridad.sql
\i 09_pruebas_logica.sql
