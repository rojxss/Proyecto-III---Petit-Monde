--Dueño: Matias Esquivel Lizano 
SET search_path = inventario, public;

alter schema inventario owner to bd_admin;

do $$
declare o record; 
begin 
    for o in select c.oid::regclass as nombre, c.relkind
        from pg_class c 
        join pg_namespace n on n.oid = c.relkind 
        where n.nspname = 'inventario' and c.relkind in ('r', 'v', 'm', 'S')
            and not exists (select 1 from pg_depend d where d.objid = c.oid and d.deptype in ('a', 'i'))
    loop 
        execute format ('alter %s %s owner to bd_admin', 
            case o.relkind  
                when 'v' then 'view' 
                when 'm' then 'materialized view' 
                when 'S' then 'sequence' 
                else 'table' end, o.nombre);
    end loop;

    for o in select p.oid::regprocedure as firma
        from pg_proc p join pg_namespace n on n.oid = pronamespace
        where n.nspname = 'inventario' 
    loop
        execute format ('alter routine %s owner to db_admin', o.firma);
    end loop;
end $$;


-- hay que denegar todo por defecto o sea no poder nada en public 

revoke all on schema inventario from public;
revoke all on all tables in schema inventario from public; 
revoke all on all sequences in schema inventario from public;
revoke all on all routines in schema inventario from public;

-- el acceso al esquema 
grant usage on schema inventario to inventory_manager, auditor, operador;

-- inventory_manager: lectura, inserción y actualización pero nunca delete 
grant select on categorias, proveedores, almacenes, productos, stock_almacen, ventas, detalle_venta, trasnferencias, movimientos_inventario, usuario_almacen
to inventory_manager;

grant insert, update on productos, stock_almacen to inventory_manager;

grant insert on ventas, detalle_venta, trasnferencias, movimientos_inventario to inventory_manager;

grant update(estado, fecha_recepcion) on trasnferencias to inventory_manager;

-- auditor: solo lectura
grant select on categorias, proveedores, almacenes, productos, stock_almacen, ventas, detalle_venta, trasnferencias, movimientos_inventario
to auditor;

-- operador: empleado operativo 
grant select on categorias, almacenes, productos, stock_almacen,usuario_almacen
to operador; 


do $$
declare 
    r record;
    f record;
    hallada boolean;
begin 
    for r in select * from (values
        ('sp_reporte_valoracion_reabastecimiento', 'inventory_manager'),
      ('sp_reporte_rotacion_inventario',         'inventory_manager'),
      ('sp_reporte_rotacion_inventario',         'auditor'),
      ('sp_procesar_venta',                      'inventory_manager'),
      ('sp_transferir_inventario',               'inventory_manager')
    ) as t (rutina, rol)
loop 
    hallada := false;
    for f in select p.oid::regprocedure as firma
        from pg_proc p join pg_namespace n on n.oid = pronamespace 
        where n.nspname = 'inventario' and p.proname = r.rutina  
    loop 
        hallada := true;
        execute format ('grant execute on routine %s to %I', f.firma, r.rol);
    end loop;
    if not hallada then 
        raise warning 'No se encontró la rutina %', r.rutina;
    end if;
end loop;
end $$;

