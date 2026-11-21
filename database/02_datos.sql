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

    
-- ids 1 al 7 en el orden de la lista
INSERT INTO productos (sku, nombre, categoria_id, proveedor_id, costo_unitario, precio_venta) VALUES
    ('ELE-101', 'Monitor Gamer 27" 144Hz', 4, 1, 180.00, 280.00),
    ('ELE-102', 'Teclado Mecánico RGB', 5, 1, 35.00, 65.00),
    ('OFF-201', 'Silla Ergonómica Ejecutiva', 6, 2, 110.00, 195.00),
    ('OFF-202', 'Escritorio Ajustable de Pie', 6, 2, 210.00, 350.00),
    ('ACC-301', 'Mousepad XL Antideslizante', 7, 3, 6.50, 15.00),
    ('ACC-302', 'Cable HDMI 2.1 2m', 8, 3, 3.00, 8.00),
    ('ELE-105', 'Cable DisplayPort 1.4', 2, 1, 15.00, 25.00);

INSERT INTO stock_almacen (producto_id, almacen_id, cantidad, stock_minimo, stock_optimo, pasillo, estante) VALUES
    (1, 1, 15, 5, 30, 'A', '01'),
    (2, 1, 4, 10, 25, 'A', '02'),
    (7, 1, 35, 10, 60, 'A', '03'),
    (3, 1, 8, 3, 15, 'B', '05'),
    (4, 1, 0, 2, 8, 'B', '06'),
    (5, 2, 45, 15, 80, 'C', '01'),
    (6, 2, 8, 12, 40, 'C', '03');