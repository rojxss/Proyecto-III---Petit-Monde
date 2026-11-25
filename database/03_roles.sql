-- Roles del proyecto // Dueño: Matías Esquivel Lizano
-- Fase 2 para el proyecto de base de datos
--Este script de sql solo va a crear roles y usuarios de ejemplos para la ejecución del proyecto
-- Todos los permisos para estos roles van en el script llamado "07_permisos" el cuál tiene los Grant y los Revoke 
--Roles que se van a crear:
-- bd_admin: tiene el control total de la bd y gestión de usuarios
-- inventory_manager: operativa diario de sus almacenes más los reportes gerenciales
-- auditor: solo tiene permisos de lectura más reporte de rotación
--operador: rol operativo sin permisos gerenciales ni analíticos (empleado)

do $$
declare r text;
begin
    foreach r in array array [
        'admin_demo',
        'operador',
        'operador_demo',
        'auditor_demo',
        'gestor_regional',
        'gestor_norte',
        'gestor_central'
    ] loop
        if exists (select 1 from pg_roles where rolname = r) then
            execute format('drop owned by %I', r);
            execute format('drop role %I', r);
        end if;
    end loop;
end $$;

-- Roles del grupo

create role db_admin nologin
    nosuperuser nocreatedb createrole noreplication bypassrls;

create role inventory_manager nologin
    nosuperuser nocreatedb nocreaterole noreplication nobypassrls;

create role auditor nologin
    nosuperuser nocreatedb nocreaterole noreplication nobypassrls;

create role operador nologin
    nosuperuser nocreatedb nocreaterole noreplication nobypassrls;

grant inventory_manager, auditor, operador
    to db_admin with admin option, inherit false, set false;

-- creación de usuarios de ejemplo que estos si van a ocupar login 

create role admin_demo login in role db_admin;
create role gestor_central login in role inventory_manager;
create role gestor_norte login in role inventory_manager;
create role gestor_regional login in role inventory_manager;
create role operador_demo login in role operador;
create role auditor_demo login in role auditor;

comment on role db_admin is 'rol de administración de la base de datos, tiene todos los permisos y puede crear usuarios';
comment on role inventory_manager is 'gestor de inventario: lectura/inserción/actualización de sus almacenes';
comment on role auditor is 'auditor: solo lectura y reporte de rotación';
comment on role operador is 'operativo sin permisos gerenciales ni analíticos (empleado)';

