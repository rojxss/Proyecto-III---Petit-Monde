SET search_path = inventario, public;

-- Los ids salen en orden: 1 Muebles, 2 Electrónica, 3 Accesorios
INSERT INTO categorias (nombre, categoria_padre_id) VALUES
    ('Muebles', NULL),
    ('Electrónica', NULL),
    ('Accesorios', NULL);

INSERT INTO categorias (nombre, categoria_padre_id) VALUES
    ('Monitores', 2),
    ('Periféricos', 2),
    ('Oficina', 1),
    ('Mousepads', 3),
    ('Cables', 3);

INSERT INTO proveedores (nombre, contacto, telefono, pais) VALUES
    ('Tech Supplies Co.', 'Carlos Ruiz', '+506 8888-1111', 'Costa Rica'),
    ('Muebles & Confort', 'Ana Gómez', '+506 8888-2222', 'Costa Rica'),
    ('Importadora Global', 'Luis Mora', '+506 8888-3333', 'Costa Rica');

INSERT INTO almacenes (nombre, ubicacion) VALUES
    ('Almacén Central', 'Cartago, Costa Rica'),
    ('Bodega Norte', 'San José, Costa Rica');