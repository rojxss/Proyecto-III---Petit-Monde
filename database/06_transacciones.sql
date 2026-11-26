-- =====================================================================
-- 06_transacciones.sql | P3 (Lógica) | Fase 5
-- Las dos rutinas que mueven inventario: la venta (checkout) y la
-- transferencia entre almacenes.
--
-- Sobre las transacciones: en PostgreSQL una función siempre corre
-- completa dentro de una sola transacción. Si en cualquier paso se lanza
-- un RAISE EXCEPTION, todo lo que la función alcanzó a hacer se deshace
-- (ROLLBACK). Si termina bien, los cambios quedan cuando se hace COMMIT.
-- Así nunca queda una venta o una transferencia a medias.
-- =====================================================================
SET search_path = inventario, public;


-- ---------------------------------------------------------------------
-- RUTINA 1: Procesar una venta (checkout)
--
-- p_almacen_id   almacén desde donde se despacha
-- p_cliente      nombre del cliente (puede ir NULL)
-- p_productos    ids de los productos, por ejemplo ARRAY[1, 2]
-- p_cantidades   cantidad de cada producto, en el mismo orden, ARRAY[2, 1]
--
-- Devuelve el id de la venta creada.
-- Ejemplo: SELECT sp_procesar_venta(1, 'Oficinas del Valle', ARRAY[1, 2], ARRAY[2, 1]);
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_procesar_venta(
    p_almacen_id INT,
    p_cliente    VARCHAR,
    p_productos  INT[],
    p_cantidades INT[]
)
RETURNS INT
LANGUAGE plpgsql
SET search_path = inventario, public
AS $$
DECLARE
    v_venta_id   INT;
    v_total      INT;
    v_producto   INT;
    v_cantidad   INT;
    v_disponible INT;
    v_precio     NUMERIC(12,2);
    v_sku        VARCHAR(20);
    i            INT;
BEGIN
    v_total := COALESCE(array_length(p_productos, 1), 0);

    IF v_total = 0 THEN
        RAISE EXCEPTION 'La venta no trae productos. Operación cancelada.';
    END IF;

    IF v_total <> COALESCE(array_length(p_cantidades, 1), 0) THEN
        RAISE EXCEPTION 'Cada producto necesita su cantidad: llegaron % productos y % cantidades. Operación cancelada.',
            v_total, COALESCE(array_length(p_cantidades, 1), 0);
    END IF;

    -- Paso 1: antes de tocar nada se revisa que alcance el stock de cada
    -- producto. El FOR UPDATE bloquea la fila para que otra venta no se
    -- lleve las mismas unidades mientras tanto.
    FOR i IN 1 .. v_total LOOP
        v_producto := p_productos[i];
        v_cantidad := COALESCE(p_cantidades[i], 0);

        IF v_cantidad <= 0 THEN
            RAISE EXCEPTION 'La cantidad del producto % tiene que ser mayor que cero. Operación cancelada.', v_producto;
        END IF;

        v_disponible := NULL;
        SELECT sa.cantidad INTO v_disponible
        FROM stock_almacen sa
        WHERE sa.producto_id = v_producto
          AND sa.almacen_id = p_almacen_id
        FOR UPDATE;

        IF v_disponible IS NULL THEN
            RAISE EXCEPTION 'El producto % no está registrado en el almacén %. Operación cancelada.',
                v_producto, p_almacen_id;
        END IF;

        IF v_disponible < v_cantidad THEN
            SELECT p.sku INTO v_sku FROM productos p WHERE p.producto_id = v_producto;
            RAISE EXCEPTION 'No hay suficiente stock de % en el almacén %: se pidieron % y solo hay %. Operación cancelada.',
                COALESCE(v_sku, v_producto::VARCHAR), p_almacen_id, v_cantidad, v_disponible;
        END IF;
    END LOOP;

    -- Paso 2: la cabecera de la venta
    INSERT INTO ventas (almacen_id, cliente)
    VALUES (p_almacen_id, p_cliente)
    RETURNING venta_id INTO v_venta_id;

    FOR i IN 1 .. v_total LOOP
        v_producto := p_productos[i];
        v_cantidad := p_cantidades[i];

        SELECT COALESCE(p.precio_venta, 0) INTO v_precio
        FROM productos p
        WHERE p.producto_id = v_producto;

        -- Paso 3: una línea de detalle por producto, con el precio de hoy
        INSERT INTO detalle_venta (venta_id, linea, producto_id, cantidad, precio_unitario)
        VALUES (v_venta_id, i, v_producto, v_cantidad, v_precio);

        -- Paso 4: se descuenta del almacén. El CHECK de la tabla no deja
        -- que quede negativo, así que si algo cambió también se cae aquí.
        UPDATE stock_almacen
        SET cantidad = cantidad - v_cantidad
        WHERE producto_id = v_producto
          AND almacen_id = p_almacen_id;

        -- Paso 5: queda la salida anotada en la bitácora de movimientos
        INSERT INTO movimientos_inventario (producto_id, almacen_id, tipo, cantidad, precio_unitario, venta_id)
        VALUES (v_producto, p_almacen_id, 'SALIDA', v_cantidad, v_precio, v_venta_id);
    END LOOP;

    RETURN v_venta_id;
END;
$$;


-- ---------------------------------------------------------------------
-- RUTINA 2: Transferir inventario entre almacenes
--
-- p_origen_id    almacén que envía
-- p_destino_id   almacén que recibe
-- p_producto_id  producto que se mueve (uno por transferencia)
-- p_cantidad     unidades a mover
--
-- Devuelve el id de la transferencia.
-- Ejemplo: SELECT sp_transferir_inventario(1, 2, 1, 5);
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_transferir_inventario(
    p_origen_id   INT,
    p_destino_id  INT,
    p_producto_id INT,
    p_cantidad    INT
)
RETURNS INT
LANGUAGE plpgsql
SET search_path = inventario, public
AS $$
DECLARE
    v_transferencia_id INT;
    v_disponible       INT;
    v_minimo           INT;
    v_optimo           INT;
    v_costo            NUMERIC(12,2);
BEGIN
    IF p_origen_id IS NULL OR p_destino_id IS NULL OR p_producto_id IS NULL THEN
        RAISE EXCEPTION 'Faltan datos: hay que indicar el almacén de origen, el de destino y el producto. Operación cancelada.';
    END IF;

    IF p_origen_id = p_destino_id THEN
        RAISE EXCEPTION 'El almacén de origen y el de destino son el mismo (%). Operación cancelada.', p_origen_id;
    END IF;

    IF COALESCE(p_cantidad, 0) <= 0 THEN
        RAISE EXCEPTION 'La cantidad a transferir tiene que ser mayor que cero. Operación cancelada.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM almacenes a WHERE a.almacen_id = p_destino_id) THEN
        RAISE EXCEPTION 'No existe ningún almacén con el id %. Operación cancelada.', p_destino_id;
    END IF;

    -- Paso 1: el origen tiene que tener las unidades. Se bloquea la fila
    -- para que nadie más las venda o las mueva mientras tanto.
    SELECT sa.cantidad, sa.stock_minimo, sa.stock_optimo
    INTO v_disponible, v_minimo, v_optimo
    FROM stock_almacen sa
    WHERE sa.producto_id = p_producto_id
      AND sa.almacen_id = p_origen_id
    FOR UPDATE;

    IF v_disponible IS NULL THEN
        RAISE EXCEPTION 'El producto % no está registrado en el almacén de origen %. Operación cancelada.',
            p_producto_id, p_origen_id;
    END IF;

    IF v_disponible < p_cantidad THEN
        RAISE EXCEPTION 'El almacén % solo tiene % unidades del producto % y se quieren mover %. Operación cancelada.',
            p_origen_id, v_disponible, p_producto_id, p_cantidad;
    END IF;

    SELECT COALESCE(p.costo_unitario, 0) INTO v_costo
    FROM productos p
    WHERE p.producto_id = p_producto_id;

    -- Paso 2: se registra la transferencia. Como la entrada al destino se
    -- hace en esta misma operación, queda de una vez como RECIBIDA.
    INSERT INTO transferencias (almacen_origen_id, almacen_destino_id, producto_id, cantidad,
                                estado, fecha_recepcion)
    VALUES (p_origen_id, p_destino_id, p_producto_id, p_cantidad, 'RECIBIDA', now())
    RETURNING transferencia_id INTO v_transferencia_id;

    -- Paso 3: sale del origen
    UPDATE stock_almacen
    SET cantidad = cantidad - p_cantidad
    WHERE producto_id = p_producto_id
      AND almacen_id = p_origen_id;

    -- Paso 4: entra al destino. Si el producto nunca había estado ahí se
    -- crea la fila con los mismos mínimos del origen y sin ubicación fija.
    IF EXISTS (SELECT 1 FROM stock_almacen sa
               WHERE sa.producto_id = p_producto_id
                 AND sa.almacen_id = p_destino_id) THEN
        UPDATE stock_almacen
        SET cantidad = cantidad + p_cantidad
        WHERE producto_id = p_producto_id
          AND almacen_id = p_destino_id;
    ELSE
        INSERT INTO stock_almacen (producto_id, almacen_id, cantidad, stock_minimo, stock_optimo, pasillo, estante)
        VALUES (p_producto_id, p_destino_id, p_cantidad,
                COALESCE(v_minimo, 0), COALESCE(v_optimo, 0), 'S/A', 'S/A');
    END IF;

    -- Paso 5: doble registro en la bitácora, la salida y la entrada
    INSERT INTO movimientos_inventario (producto_id, almacen_id, tipo, cantidad, precio_unitario, transferencia_id)
    VALUES (p_producto_id, p_origen_id, 'SALIDA', p_cantidad, v_costo, v_transferencia_id);

    INSERT INTO movimientos_inventario (producto_id, almacen_id, tipo, cantidad, precio_unitario, transferencia_id)
    VALUES (p_producto_id, p_destino_id, 'ENTRADA', p_cantidad, v_costo, v_transferencia_id);

    RETURN v_transferencia_id;
END;
$$;
