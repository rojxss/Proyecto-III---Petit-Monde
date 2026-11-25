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


