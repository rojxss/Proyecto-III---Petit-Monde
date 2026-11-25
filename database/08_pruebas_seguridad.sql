-- =====================================================================
-- 08_pruebas_seguridad.sql | Dueño: P2 | Pruebas de seguridad (RBAC / RLS)
-- REGLA DEL ENUNCIADO: cada prueba debe imprimir su identificador con
-- RAISE NOTICE ANTES de la llamada; si no, se ignora en la revisión.
-- Cambiar al rol de la prueba con SET ROLE y volver con RESET ROLE.
-- =====================================================================
SET search_path = inventario, public;

-- ---------------------------------------------------------------------
-- PRUEBA 1 | Rol: db_admin
-- Objetivo: Control total sobre estructura, usuarios y rutinas gerenciales
-- ---------------------------------------------------------------------
do $$ begin raise notice '>>> prueba 1: db_admin tiene control total sobre estructura, usuarios y rutinas gerenciales'; end $$;
set role db_admin;
do $$
declare
  n_filas  bigint;
  rutina   regproc;
begin
  raise notice '    [usuario actual: %]', current_user;

  -- a) estructura (ddl)
  create table prueba_admin_ddl (id int primary key);
  drop table prueba_admin_ddl;
  raise notice '    ok a) create table / drop table permitidos';

  -- b) gestión de usuarios y privilegios (create role, grant, revoke, drop role)
  create role prueba_usuario_tmp nologin;
  grant inventory_manager to prueba_usuario_tmp;
  grant select on productos to prueba_usuario_tmp;
  revoke select on productos from prueba_usuario_tmp;
  drop role prueba_usuario_tmp;
  raise notice '    ok b) create role / grant / revoke / drop role permitidos';

  -- c) sin restricción de rls: ve todos los almacenes
  select count(*) into n_filas from stock_almacen;
  raise notice '    ok c) stock_almacen visible completo: % filas, almacenes: %',
      n_filas, (select string_agg(distinct almacen_id::text, ',') from stock_almacen);

  -- d) rutinas gerenciales / analíticas
  select p.oid::regproc into rutina
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'inventario' and p.proname = 'sp_reporte_valoracion_reabastecimiento';
  if rutina is null then
    raise notice '    pendiente d) sp_reporte_valoracion_reabastecimiento aún no existe (persona 3)';
  else
    execute format('select count(*) from %s(1, 10.0)', rutina) into n_filas;
    raise notice '    ok d) % ejecutado sin restricciones (% filas)', rutina, n_filas;
  end if;

  select p.oid::regproc into rutina
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'inventario' and p.proname = 'sp_reporte_rotacion_inventario';
  if rutina is null then
    raise notice '    pendiente d) sp_reporte_rotacion_inventario aún no existe (persona 3)';
  else
    execute format('select count(*) from %s(%L::date, %L::date, null)', rutina, '2026-01-01', '2026-12-31') into n_filas;
    raise notice '    ok d) % ejecutado sin restricciones (% filas)', rutina, n_filas;
  end if;

  raise notice '    resultado prueba 1: correcto';
end $$;
reset role;

-- ---------------------------------------------------------------------
-- PRUEBA 2 | Rol: inventory_manager
-- Objetivo: Intentar crear un rol / modificar DDL -> permission denied to create role
-- ---------------------------------------------------------------------
do $$ begin raise notice '>>> prueba 2: inventory_manager intenta create role y ddl -> permission denied'; end $$;
set role inventory_manager;
do $$
begin
  raise notice '    [usuario actual: %]', current_user;

  begin
    create role usuario_intruso login;
    raise notice '    fallo: create role no debió permitirse';
    drop role usuario_intruso;
  exception when insufficient_privilege then
    raise notice '    ok create role rechazado -> error: %', sqlerrm;
  end;

  begin
    create table tabla_intrusa (id int);
    raise notice '    fallo: create table no debió permitirse';
    drop table tabla_intrusa;
  exception when insufficient_privilege then
    raise notice '    ok create table rechazado -> error: %', sqlerrm;
  end;

  begin
    alter table productos add column columna_intrusa int;
    raise notice '    fallo: alter table no debió permitirse';
  exception when insufficient_privilege then
    raise notice '    ok alter table rechazado -> error: %', sqlerrm;
  end;
end $$;
reset role;

-- ---------------------------------------------------------------------
-- PRUEBA 7 | Rol: inventory_manager
-- Objetivo: RLS filtra existencias a la sucursal asignada (Almacén 2)
-- ---------------------------------------------------------------------
do $$ begin raise notice '>>> prueba 7: rls filtra existencias al almacén 2 para gestor_norte (inventory_manager)'; end $$;
set role gestor_norte;
select current_user as usuario, almacen_id, count(*) as productos_visibles, sum(cantidad) as unidades
  from stock_almacen group by almacen_id order by almacen_id;
do $$
declare fuera bigint;
begin
  select count(*) into fuera from stock_almacen where almacen_id <> 2;
  if fuera = 0 then
    raise notice '    ok: solo se ven filas del almacén 2 (ninguna de otros almacenes)';
  else
    raise notice '    fallo: se ven % filas de otros almacenes', fuera;
  end if;
end $$;
reset role;
-- contraste (superusuario, sin rls): la tabla global sí tiene ambos almacenes
select 'tabla global' as vista, almacen_id, count(*) as productos from stock_almacen group by almacen_id order by almacen_id;

-- ---------------------------------------------------------------------
-- PRUEBA 8 | Rol: inventory_manager
-- Objetivo: No ve ni modifica registros de otra bodega (Almacén 1)
-- ---------------------------------------------------------------------
do $$ begin raise notice '>>> prueba 8: gestor_norte (almacén 2) intenta ver y modificar registros del almacén 1'; end $$;
set role gestor_norte;
do $$
declare n bigint;
begin
  raise notice '    [usuario actual: %]', current_user;

  select count(*) into n from stock_almacen where almacen_id = 1;
  raise notice '    a) select stock del almacén 1 -> % filas (el registro existe, rls lo oculta)', n;

  update stock_almacen set cantidad = 9999 where almacen_id = 1;
  get diagnostics n = row_count;
  raise notice '    b) update stock del almacén 1 -> % filas modificadas', n;

  select count(*) into n from ventas where almacen_id = 1;
  raise notice '    c) select ventas del almacén 1 -> % filas', n;
  select count(*) into n from detalle_venta d join ventas v using (venta_id) where v.almacen_id = 1;
  raise notice '    c) select detalle_venta de ventas del almacén 1 -> % filas', n;

  begin
    insert into stock_almacen (producto_id, almacen_id, cantidad, stock_minimo, stock_optimo, pasillo, estante)
    values (5, 1, 1, 1, 1, 'z9', '99');
    raise notice '    fallo d): el insert en el almacén 1 no debió permitirse';
  exception when insufficient_privilege then
    raise notice '    d) insert en almacén 1 rechazado -> error: %', sqlerrm;
  end;

  begin
    insert into ventas (almacen_id, cliente) values (1, 'cliente fraudulento');
    raise notice '    fallo e): la venta en el almacén 1 no debió permitirse';
  exception when insufficient_privilege then
    raise notice '    e) insert de venta en almacén 1 rechazado -> error: %', sqlerrm;
  end;
end $$;
reset role;
-- verificación como superusuario: el stock del almacén 1 no cambió
do $$
declare n bigint;
begin
  select count(*) into n from stock_almacen where almacen_id = 1 and cantidad = 9999;
  if n = 0 then raise notice '    ok: el stock del almacén 1 permanece intacto';
  else raise notice '    fallo: el stock del almacén 1 fue alterado'; end if;
end $$;

-- ---------------------------------------------------------------------
-- PRUEBA 10 | Rol: inventory_manager (sin permiso analítico)
-- Objetivo: No puede ejecutar sp_reporte_valoracion_reabastecimiento
-- ---------------------------------------------------------------------
do $$ begin raise notice '>>> prueba 10: operador_demo intenta ejecutar sp_reporte_valoracion_reabastecimiento(1, 10.0)'; end $$;
set role operador_demo;
do $$
begin
  raise notice '    [usuario actual: %]', current_user;
  begin
    perform * from sp_reporte_valoracion_reabastecimiento(1, 10.0);
    raise notice '    fallo: el operador pudo ejecutar el reporte';
  exception
    when insufficient_privilege then
      raise notice '    ok rechazado -> error: %', sqlerrm;
    when undefined_function then
      raise notice '    pendiente: la función de la persona 3 aún no existe o su firma cambió -> %', sqlerrm;
  end;
end $$;
reset role;

-- ---------------------------------------------------------------------
-- PRUEBA 11 | Rol: auditor
-- Objetivo: INSERT en productos -> permission denied for table productos
-- ---------------------------------------------------------------------
do $$ begin raise notice '>>> prueba 11: auditor_demo intenta insert en productos -> permission denied'; end $$;
set role auditor_demo;
do $$
begin
  raise notice '    [usuario actual: %]', current_user;
  begin
    insert into productos (sku, nombre, categoria_id, proveedor_id, costo_unitario, precio_venta)
    values ('aud-001', 'producto no autorizado', 1, 1, 1.00, 2.00);
    raise notice '    fallo: el auditor pudo insertar en productos';
  exception when insufficient_privilege then
    raise notice '    ok insert rechazado -> error: %', sqlerrm;
  end;

  begin
    update productos set precio_venta = 1 where producto_id = 1;
    raise notice '    fallo: el auditor pudo actualizar productos';
  exception when insufficient_privilege then
    raise notice '    ok update rechazado -> error: %', sqlerrm;
  end;

  begin
    delete from movimientos_inventario where movimiento_id = 1;
    raise notice '    fallo: el auditor pudo borrar movimientos';
  exception when insufficient_privilege then
    raise notice '    ok delete rechazado -> error: %', sqlerrm;
  end;
end $$;
reset role;

-- ---------------------------------------------------------------------
-- PRUEBA 12 | Rol: auditor
-- Objetivo: SELECT sobre movimientos de inventario funciona
-- ---------------------------------------------------------------------
do $$ begin raise notice '>>> prueba 12: auditor_demo consulta movimientos_inventario (lectura global autorizada)'; end $$;
set role auditor_demo;
select current_user as usuario, almacen_id, tipo, count(*) as movimientos, sum(cantidad) as unidades
  from movimientos_inventario group by almacen_id, tipo order by almacen_id, tipo;
reset role;

-- ---------------------------------------------------------------------
-- PRUEBA 15 | Rol: auditor
-- Objetivo: No puede ejecutar venta ni transferencia
-- ---------------------------------------------------------------------
do $$ begin raise notice '>>> prueba 15: auditor_demo intenta ejecutar venta y transferencia -> permission denied'; end $$;
set role auditor_demo;
do $$
declare
  f record;
  encontradas int := 0;
begin
  raise notice '    [usuario actual: %]', current_user;
  for f in select p.oid::regproc as nombre, p.pronargs, p.prokind
             from pg_proc p join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'inventario'
              and p.proname in ('sp_procesar_venta', 'sp_transferir_inventario')
            order by p.proname
  loop
    encontradas := encontradas + 1;
    begin
      if f.prokind = 'p' then
        execute format('call %s(%s)', f.nombre, array_to_string(array_fill('null'::text, array[f.pronargs]), ', '));
      else
        execute format('select * from %s(%s)', f.nombre, array_to_string(array_fill('null'::text, array[f.pronargs]), ', '));
      end if;
      raise notice '    fallo: el auditor pudo invocar %', f.nombre;
    exception
      when insufficient_privilege then
        raise notice '    ok % rechazada -> error: %', f.nombre, sqlerrm;
      when others then
        raise notice '    fallo: % no fue rechazada por privilegios (%: %)', f.nombre, sqlstate, sqlerrm;
    end;
  end loop;

  if encontradas = 0 then
    raise notice '    pendiente: sp_procesar_venta / sp_transferir_inventario aún no existen (persona 3)';
  end if;

  -- tampoco puede escribir directamente en las tablas que esas rutinas modifican
  begin
    insert into ventas (almacen_id, cliente) values (1, 'venta directa del auditor');
    raise notice '    fallo: el auditor pudo insertar en ventas';
  exception when insufficient_privilege then
    raise notice '    ok insert directo en ventas rechazado -> error: %', sqlerrm;
  end;
  begin
    update stock_almacen set cantidad = 0;
    raise notice '    fallo: el auditor pudo actualizar stock_almacen';
  exception when insufficient_privilege then
    raise notice '    ok update directo en stock_almacen rechazado -> error: %', sqlerrm;
  end;
end $$;
reset role;


-- evidencias rls 
do $$ begin raise notice '>>> evidencia rls: filas visibles por usuario en cada tabla'; end $$;
do $$
declare
  u        text;
  t        text;
  n        bigint;
  linea    text;
  almacenes text;
begin
  foreach u in array array['db_admin', 'gestor_central', 'gestor_norte', 'gestor_regional', 'operador_demo', 'auditor_demo']
  loop
    execute format('set local role %I', u);
    linea := '';
    foreach t in array array['stock_almacen', 'movimientos_inventario', 'ventas', 'detalle_venta', 'transferencias']
    loop
      begin
        execute format('select count(*) from %I', t) into n;
        linea := linea || format(' %s=%s', t, n);
      exception when insufficient_privilege then
        linea := linea || format(' %s=sin_acceso', t);
      end;
    end loop;
    select coalesce(string_agg(distinct almacen_id::text, ','), '-') into almacenes from stock_almacen;
    execute 'reset role';
    raise notice '    % almacenes_en_stock=[%] |%', rpad(u, 16), almacenes, linea;
  end loop;
end $$;
