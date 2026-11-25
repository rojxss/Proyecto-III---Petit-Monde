-- Roles del proyecto // Dueño: Matías Esquivel Lizano
-- Fase 2 para el proyecto de base de datos
--Este script de sql solo va a crear roles y usuarios de ejemplos para la ejecución del proyecto
-- Todos los permisos para estos roles van en el script llamado "07_permisos" el cuál tiene los Grant y los Revoke 
--Roles que se van a crear:
-- bd_admin: tiene el control total de la bd y gestión de usuarios
-- inventory_manager: operativa diario de sus almacenes más los reportes gerenciales
-- auditor: solo tiene permisos de lectura más reporte de rotación
--operador: rol operativo sin permisos gerenciales ni analíticos (empleado)

DO $$
declare r text;
begin
    foreach r in array array [
        'admin_demo',
        'aperador',
        'operador_demo',
        'auditor_demo',
        'gestor_regional',
        'gestor_norte',
        'gestor_central',
    ] loop
        if exists (select 1 from pg_roles where rolname = r) then
            execute format('drop owned by %I', r);
            execute format('drop role %I', r);
        end if;
    end loop;
end $$;

-- Roles del grupo

-- vamos a crear el db_admin que administra estructura y usuarios pero no es un superusuario


