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

    
INSERT INTO ventas (almacen_id, fecha, usuario, cliente) VALUES
    (1, '2026-01-12 10:15', 'gestor_central', 'Oficinas del Valle'),
    (1, '2026-02-09 14:30', 'gestor_central', 'Tecnología Cartago'),
    (1, '2026-02-23 09:45', 'gestor_central', 'Oficinas del Valle'),
    (1, '2026-03-16 16:20', 'gestor_central', 'Tecnología Cartago'),
    (2, '2026-01-20 11:00', 'gestor_norte', 'Papelería San José'),
    (2, '2026-03-05 15:10', 'gestor_norte', 'Papelería San José'),
    (1, '2026-08-25 13:40', 'gestor_central', 'Muebles del Este'),
    (2, '2026-09-18 10:05', 'gestor_norte', 'Papelería San José'),
    (1, '2026-10-05 11:25', 'gestor_central', 'Tecnología Cartago'),
    (2, '2026-10-25 09:30', 'gestor_norte', 'Papelería San José');

INSERT INTO detalle_venta (venta_id, linea, producto_id, cantidad, precio_unitario) VALUES
    (1, 1, 1, 15, 280.00),
    (1, 2, 2, 10, 65.00),
    (2, 1, 1, 15, 280.00),
    (2, 2, 7, 3, 25.00),
    (2, 3, 3, 2, 195.00),
    (3, 1, 2, 10, 65.00),
    (3, 2, 3, 1, 195.00),
    (4, 1, 1, 15, 280.00),
    (4, 2, 2, 8, 65.00),
    (5, 1, 5, 20, 15.00),
    (5, 2, 6, 6, 8.00),
    (6, 1, 5, 10, 15.00),
    (6, 2, 6, 4, 8.00),
    (7, 1, 4, 5, 350.00),
    (8, 1, 6, 32, 8.00),
    (9, 1, 2, 18, 65.00),
    (10, 1, 5, 10, 15.00);

-- Entradas: inventario inicial y últimas compras a proveedor
INSERT INTO movimientos_inventario (producto_id, almacen_id, tipo, cantidad, precio_unitario, fecha, usuario) VALUES
    (1, 1, 'ENTRADA', 50, 180.00, '2025-12-15 08:00', 'gestor_central'),
    (2, 1, 'ENTRADA', 30, 35.00, '2025-12-15 08:00', 'gestor_central'),
    (3, 1, 'ENTRADA', 6, 110.00, '2025-12-15 08:00', 'gestor_central'),
    (4, 1, 'ENTRADA', 3, 210.00, '2025-12-15 08:00', 'gestor_central'),
    (7, 1, 'ENTRADA', 38, 15.00, '2025-12-15 08:00', 'gestor_central'),
    (5, 2, 'ENTRADA', 35, 6.50, '2025-12-15 08:00', 'gestor_norte'),
    (6, 2, 'ENTRADA', 20, 3.00, '2025-12-15 08:00', 'gestor_norte'),
    (1, 1, 'ENTRADA', 10, 180.00, '2026-10-15 09:00', 'gestor_central'),
    (2, 1, 'ENTRADA', 20, 35.00, '2026-09-20 09:00', 'gestor_central'),
    (3, 1, 'ENTRADA', 5, 110.00, '2026-10-01 09:00', 'gestor_central'),
    (4, 1, 'ENTRADA', 2, 210.00, '2026-08-10 09:00', 'gestor_central'),
    (5, 2, 'ENTRADA', 50, 6.50, '2026-10-18 09:00', 'gestor_norte'),
    (6, 2, 'ENTRADA', 30, 3.00, '2026-09-05 09:00', 'gestor_norte');

-- Cada línea de venta genera su movimiento de salida
INSERT INTO movimientos_inventario (producto_id, almacen_id, tipo, cantidad, precio_unitario, fecha, usuario, venta_id)
SELECT d.producto_id, v.almacen_id, 'SALIDA', d.cantidad, d.precio_unitario, v.fecha, v.usuario, v.venta_id
FROM detalle_venta d
JOIN ventas v ON v.venta_id = d.venta_id;