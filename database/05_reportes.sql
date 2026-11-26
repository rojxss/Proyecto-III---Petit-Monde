-- =====================================================================
-- 05_reportes.sql | P3 (Lógica) | Fase 4
-- Los dos reportes van como funciones RETURNS TABLE, que es lo que en
-- PostgreSQL hace las veces de procedimiento almacenado.
-- Son SECURITY INVOKER (el valor por defecto), así que el RLS de quien
-- las ejecuta se respeta solo.
-- =====================================================================
SET search_path = inventario, public;


-- ---------------------------------------------------------------------
-- REPORTE 1: Valoración del inventario y reabastecimiento
--
-- Para cada producto de cada almacén calcula cuánto vale lo que hay,
-- en qué estado está (Agotado, Crítico u Óptimo) y cuánto costaría
-- volver a llenarlo hasta el stock óptimo.
--
-- p_almacen_id    almacén a revisar, o NULL para toda la empresa
-- p_margen_alerta porcentaje extra sobre el mínimo. Con 10, un producto
--                 con mínimo 10 ya se marca como crítico si tiene 11 o menos.
--
-- Ejemplo: SELECT * FROM sp_reporte_valoracion_reabastecimiento(1, 10.0);
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_reporte_valoracion_reabastecimiento(
    p_almacen_id    INT,
    p_margen_alerta NUMERIC
)
RETURNS TABLE (
    prioridad           INT,
    almacen             VARCHAR,
    sku                 VARCHAR,
    producto            VARCHAR,
    categoria           VARCHAR,
    stock_actual        INT,
    stock_minimo        INT,
    stock_optimo        INT,
    unidades_en_transito INT,
    costo_unitario      NUMERIC,
    valor_inventario    NUMERIC,
    estado              VARCHAR,
    unidades_a_pedir    INT,
    costo_reposicion    NUMERIC
)
LANGUAGE plpgsql
SET search_path = inventario, public
AS $$
-- Las columnas de salida se llaman igual que las de la tabla temporal;
-- con esto PostgreSQL entiende que hablamos de la columna.
#variable_conflict use_column
DECLARE
    v_margen NUMERIC;
BEGIN
    -- Si no mandan margen se trabaja con 0 %
    v_margen := COALESCE(p_margen_alerta, 0);

    IF v_margen < 0 THEN
        RAISE EXCEPTION 'El margen de alerta no puede ser negativo (se recibió %).', v_margen;
    END IF;

    IF p_almacen_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM almacenes a WHERE a.almacen_id = p_almacen_id) THEN
            RAISE EXCEPTION 'No existe ningún almacén con el id %.', p_almacen_id;
        END IF;
    END IF;

    -- Se borra por si el reporte ya se corrió antes en la misma sesión
    IF to_regclass('pg_temp.tmp_valoracion') IS NOT NULL THEN
        DROP TABLE tmp_valoracion;
    END IF;

    CREATE TEMP TABLE tmp_valoracion (
        producto_id      INT,
        almacen_id       INT,
        almacen          VARCHAR(80),
        sku              VARCHAR(20),
        producto         VARCHAR(120),
        categoria        VARCHAR(80),
        stock_actual     INT,
        stock_minimo     INT,
        stock_optimo     INT,
        en_transito      INT,
        costo_unitario   NUMERIC(12,2),
        valor_inventario NUMERIC(14,2),
        estado           VARCHAR(10),
        prioridad        INT,
        unidades_a_pedir INT,
        costo_reposicion NUMERIC(14,2)
    );

    -- Paso 1: lo que hay en cada almacén. Aquí ya actúa el RLS, entonces
    -- si el usuario solo ve un almacén solo entra ese, aunque pidan NULL.
    INSERT INTO tmp_valoracion (producto_id, almacen_id, almacen, sku, producto, categoria,
                                stock_actual, stock_minimo, stock_optimo, costo_unitario)
    SELECT p.producto_id, a.almacen_id, a.nombre, p.sku, p.nombre, c.nombre,
           COALESCE(sa.cantidad, 0), COALESCE(sa.stock_minimo, 0),
           COALESCE(sa.stock_optimo, 0), COALESCE(p.costo_unitario, 0)
    FROM stock_almacen sa
    JOIN productos p  ON p.producto_id = sa.producto_id
    JOIN categorias c ON c.categoria_id = p.categoria_id
    JOIN almacenes a  ON a.almacen_id = sa.almacen_id
    WHERE p.activo = TRUE
      AND (p_almacen_id IS NULL OR sa.almacen_id = p_almacen_id);

    -- Paso 2: unidades que vienen en camino por transferencias sin recibir
    UPDATE tmp_valoracion t
    SET en_transito = COALESCE((SELECT SUM(tr.cantidad)
                                FROM transferencias tr
                                WHERE tr.producto_id = t.producto_id
                                  AND tr.almacen_destino_id = t.almacen_id
                                  AND tr.estado = 'EN_TRANSITO'), 0);

    -- Paso 3: valor actual y estado de cada producto
    UPDATE tmp_valoracion
    SET valor_inventario = COALESCE(stock_actual, 0) * COALESCE(costo_unitario, 0),
        estado = CASE
                     WHEN stock_actual = 0 THEN 'Agotado'
                     WHEN stock_actual + en_transito <= stock_minimo * (1 + v_margen / 100) THEN 'Crítico'
                     ELSE 'Óptimo'
                 END;

    UPDATE tmp_valoracion
    SET prioridad = CASE estado
                        WHEN 'Agotado' THEN 1
                        WHEN 'Crítico' THEN 2
                        ELSE 3
                    END;

    -- Paso 4: cuánto hay que pedir para llegar al óptimo y cuánto cuesta.
    -- Lo que ya viene en camino no se vuelve a pedir.
    UPDATE tmp_valoracion
    SET unidades_a_pedir = CASE
                               WHEN stock_optimo - stock_actual - en_transito > 0
                                   THEN stock_optimo - stock_actual - en_transito
                               ELSE 0
                           END;

    UPDATE tmp_valoracion
    SET costo_reposicion = COALESCE(unidades_a_pedir, 0) * COALESCE(costo_unitario, 0);

    -- Primero lo más urgente y, dentro de cada estado, lo que más cuesta reponer
    RETURN QUERY
    SELECT t.prioridad, t.almacen, t.sku, t.producto, t.categoria,
           t.stock_actual, t.stock_minimo, t.stock_optimo, t.en_transito,
           t.costo_unitario, t.valor_inventario, t.estado,
           t.unidades_a_pedir, t.costo_reposicion
    FROM tmp_valoracion t
    ORDER BY t.prioridad, t.costo_reposicion DESC, t.sku;
END;
$$;


-- ---------------------------------------------------------------------
-- REPORTE 2: Rotación del inventario en un rango de fechas
--
-- Revisa cuánto se vendió de cada producto en el periodo, cuánto
-- representa en dinero, cuántas unidades salen por día y para cuántos
-- días alcanza lo que queda. Al final los clasifica en A, B o C.
--
-- p_fecha_inicio, p_fecha_fin  periodo a revisar (los dos días cuentan)
-- p_categoria_id               categoría a revisar, o NULL para todas.
--                              Si es una categoría padre, también entran
--                              sus subcategorías.
--
-- Ejemplo: SELECT * FROM sp_reporte_rotacion_inventario('2026-01-01', '2026-03-31', 2);
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_reporte_rotacion_inventario(
    p_fecha_inicio DATE,
    p_fecha_fin    DATE,
    p_categoria_id INT
)
RETURNS TABLE (
    sku                      VARCHAR,
    producto                 VARCHAR,
    categoria                VARCHAR,
    stock_promedio           NUMERIC,
    total_salidas_unidades   INT,
    valor_total_salidas_usd  NUMERIC,
    promedio_diario_salidas  NUMERIC,
    dias_inventario_restante INT,
    clasificacion_abc        VARCHAR
)
LANGUAGE plpgsql
SET search_path = inventario, public
AS $$
-- Las columnas de salida se llaman igual que las de la tabla temporal;
-- con esto PostgreSQL entiende que hablamos de la columna.
#variable_conflict use_column
DECLARE
    v_dias       INT;
    v_total      NUMERIC;
    v_acumulado  NUMERIC;
    v_porcentaje NUMERIC;
    r            RECORD;
BEGIN
    IF p_fecha_inicio IS NULL OR p_fecha_fin IS NULL THEN
        RAISE EXCEPTION 'Hay que indicar la fecha de inicio y la fecha fin. Operación cancelada.';
    END IF;

    IF p_fecha_inicio > p_fecha_fin THEN
        RAISE EXCEPTION 'La fecha de inicio (%) no puede ser posterior a la fecha fin (%). Operación cancelada.',
            p_fecha_inicio, p_fecha_fin;
    END IF;

    -- Se cuentan los dos extremos, por eso el + 1 (el primer trimestre da 90)
    v_dias := p_fecha_fin - p_fecha_inicio + 1;

    IF to_regclass('pg_temp.tmp_rotacion') IS NOT NULL THEN
        DROP TABLE tmp_rotacion;
    END IF;

    CREATE TEMP TABLE tmp_rotacion (
        producto_id   INT,
        sku           VARCHAR(20),
        producto      VARCHAR(120),
        categoria     VARCHAR(80),
        stock_promedio NUMERIC(12,1),
        stock_actual  INT,
        unidades      INT,
        valor         NUMERIC(14,2),
        promedio      NUMERIC(12,2),
        dias_restante INT,
        clase         VARCHAR(30)
    );

    -- Paso 1: productos de la categoría con su stock. Se muestra la
    -- categoría padre cuando la hay (un monitor sale como Electrónica).
    INSERT INTO tmp_rotacion (producto_id, sku, producto, categoria, stock_promedio, stock_actual)
    SELECT p.producto_id, p.sku, p.nombre, COALESCE(padre.nombre, c.nombre),
           ROUND(AVG(COALESCE(sa.cantidad, 0)), 1), SUM(COALESCE(sa.cantidad, 0))
    FROM stock_almacen sa
    JOIN productos p  ON p.producto_id = sa.producto_id
    JOIN categorias c ON c.categoria_id = p.categoria_id
    LEFT JOIN categorias padre ON padre.categoria_id = c.categoria_padre_id
    WHERE p_categoria_id IS NULL
       OR c.categoria_id = p_categoria_id
       OR c.categoria_padre_id = p_categoria_id
    GROUP BY p.producto_id, p.sku, p.nombre, COALESCE(padre.nombre, c.nombre);

    -- Paso 2: lo vendido en el periodo. Solo cuentan las salidas por
    -- venta; una transferencia mueve la mercadería pero no la vende.
    UPDATE tmp_rotacion t
    SET unidades = COALESCE((SELECT SUM(m.cantidad)
                             FROM movimientos_inventario m
                             WHERE m.producto_id = t.producto_id
                               AND m.tipo = 'SALIDA'
                               AND m.venta_id IS NOT NULL
                               AND m.fecha >= p_fecha_inicio
                               AND m.fecha < p_fecha_fin + 1), 0),
        valor = COALESCE((SELECT SUM(m.cantidad * m.precio_unitario)
                          FROM movimientos_inventario m
                          WHERE m.producto_id = t.producto_id
                            AND m.tipo = 'SALIDA'
                            AND m.venta_id IS NOT NULL
                            AND m.fecha >= p_fecha_inicio
                            AND m.fecha < p_fecha_fin + 1), 0);

    -- Paso 3: promedio por día y para cuántos días alcanza el stock.
    -- Si no se vendió nada no se puede estimar, queda en NULL.
    UPDATE tmp_rotacion
    SET promedio = ROUND(COALESCE(unidades, 0)::NUMERIC / v_dias, 2),
        dias_restante = CASE
                            WHEN COALESCE(unidades, 0) > 0
                                THEN ROUND(COALESCE(stock_actual, 0) / (unidades::NUMERIC / v_dias))
                            ELSE NULL
                        END;

    -- Paso 4: clasificación ABC. Se recorre de mayor a menor valor vendido
    -- y se va sumando el porcentaje: lo que entra antes del 80 % es A,
    -- hasta el 95 % es B y el resto es C.
    SELECT COALESCE(SUM(valor), 0) INTO v_total FROM tmp_rotacion;
    v_acumulado := 0;

    FOR r IN SELECT producto_id, valor FROM tmp_rotacion ORDER BY valor DESC, sku LOOP
        IF v_total > 0 THEN
            v_porcentaje := v_acumulado * 100 / v_total;
        ELSE
            v_porcentaje := 100;
        END IF;

        UPDATE tmp_rotacion
        SET clase = CASE
                        WHEN r.valor > 0 AND v_porcentaje < 80 THEN 'Clase A (Alta Rotación)'
                        WHEN r.valor > 0 AND v_porcentaje < 95 THEN 'Clase B (Rotación Media)'
                        ELSE 'Clase C (Baja Rotación)'
                    END
        WHERE producto_id = r.producto_id;

        v_acumulado := v_acumulado + COALESCE(r.valor, 0);
    END LOOP;

    RETURN QUERY
    SELECT t.sku, t.producto, t.categoria, t.stock_promedio, t.unidades,
           t.valor, t.promedio, t.dias_restante, t.clase
    FROM tmp_rotacion t
    ORDER BY t.valor DESC, t.sku;
END;
$$;
