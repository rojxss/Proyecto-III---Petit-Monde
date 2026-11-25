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