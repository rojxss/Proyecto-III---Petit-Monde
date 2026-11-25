-- Row-level security // Dueño: Matías Esquivel 
-- Fase 3 del proyecto 

-- Lo que ve cada rol: 
-- db_admin: todo
-- inventory_manager: solo los almacenes que se asginan en usuario_almacen
-- operador: solo los alacenes asignados
-- auditor: todo, pero solo lectura
SET search_path = inventario, public;

-- Tablas para la asignación usuario con los almacenes 
create table usuario_almacen (
    usuario varchar(50) not null, 
    almacen_id in not null references almacenes(almacen_id),
    primary key (usuario, almacen_id)
);
comment on table usuario_almacen is 'Almacenes sobre los que cada usuario tiene autoridad';

-- Asignación (1= almacén central, 2 = bodega norte)
insert into usuario_almacen (usuario, almacen_id) values
    ('gestor_central', 1),
    ('gestor_norte', 2),
    ('gestor_regional', 1),
    ('gestor_regional', 2);
    ('operador_demo', 1);

--cada usuario solo puede ver sus propias asginaciones a menos de que sea el admin que ve todas 
alter table usuario_almacen enable row level security;
create policy p_usuario_almacen_propio on usuario_almacen
    for select to inventory_manager, operador
    using (usuario = current_user);

