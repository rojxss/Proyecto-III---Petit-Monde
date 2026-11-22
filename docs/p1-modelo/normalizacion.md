# Normalización hasta 3FNBC

## Punto de partida

Tabla única del Anexo 1 con estas columnas: `IDRegistro`, `SKU`, `Producto`, `Categoría`, `Subcategoría`, `AlmacénNombre`, `Ubicación`, `Pasillo`, `Estante`, `CantidadEnStock`, `StockMínimo`, `CostoUnitario`, `PrecioVenta`, `ValorTotalStock`, `NombreProveedor`, `ContactoProveedor`, `TeléfonoProveedor`, `PaísProveedor`, `FechaÚltimaEntrada`, `CantidadÚltimaEntrada`, `EstadoStock`.

`IDRegistro` identifica cada fila, pero la llave natural es la pareja (`SKU`, `AlmacénNombre`): cada fila es un producto en un almacén.

## Dependencias funcionales

| Determinante | Determina |
|---|---|
| `SKU` | Producto, Subcategoría, CostoUnitario, PrecioVenta, NombreProveedor |
| `NombreProveedor` | ContactoProveedor, TeléfonoProveedor, PaísProveedor |
| `AlmacénNombre` | Ubicación |
| `Subcategoría` | Categoría |
| (`SKU`, `AlmacénNombre`) | CantidadEnStock, StockMínimo, Pasillo, Estante, FechaÚltimaEntrada, CantidadÚltimaEntrada |
| (`CantidadEnStock`, `CostoUnitario`) | ValorTotalStock |
| (`CantidadEnStock`, `StockMínimo`) | EstadoStock |

Nota: en los datos, la subcategoría "Periféricos" aparece bajo Electrónica y bajo Accesorios, así que el nombre de la subcategoría no determina su categoría. Por eso las categorías se modelan con un identificador y una categoría padre.

## Primera forma normal (1FN)

La tabla ya cumple 1FN: todas las columnas tienen un solo valor por celda, no hay grupos repetidos y existe una llave primaria. `Ubicación` se deja como un solo texto porque solo se usa como etiqueta del almacén y nunca se filtra por ciudad o país por separado.

## Segunda forma normal (2FN)

Con la llave (`SKU`, `AlmacénNombre`) hay dependencias parciales:

- Los datos del producto dependen solo del `SKU`.
- `Ubicación` depende solo del almacén.

Se separan en `productos` y `almacenes`. En `stock_almacen` quedan los datos que dependen de la pareja completa: cantidad, mínimo, óptimo, pasillo y estante.

## Tercera forma normal (3FN)

Se eliminan las dependencias transitivas:

- `SKU → NombreProveedor → contacto, teléfono, país`: se crea `proveedores`.
- `Subcategoría → Categoría`: se crea `categorias` con `categoria_padre_id`.
- `ValorTotalStock` y `EstadoStock` son derivados: se quitan y se calculan en los reportes.
- `FechaÚltimaEntrada` y `CantidadÚltimaEntrada` guardan solo el último evento: se reemplazan por `movimientos_inventario`, que conserva todo el historial.

## Forma normal de Boyce-Codd (3FNBC)

En cada tabla final, todo determinante es una llave candidata.

| Tabla | Llaves candidatas | Dependencias | ¿Cumple? |
|---|---|---|---|
| `categorias` | `categoria_id`, `nombre` | Cada llave determina `categoria_padre_id` | Sí |
| `proveedores` | `proveedor_id`, `nombre` | Cada llave determina contacto, teléfono y país | Sí |
| `almacenes` | `almacen_id`, `nombre` | Cada llave determina la ubicación | Sí |
| `productos` | `producto_id`, `sku` | Cada llave determina el resto de columnas | Sí |
| `stock_almacen` | (`producto_id`, `almacen_id`) | La llave determina cantidad, mínimo, óptimo, pasillo y estante | Sí |
| `ventas` | `venta_id` | La llave determina almacén, fecha, usuario y cliente | Sí |
| `detalle_venta` | (`venta_id`, `linea`), (`venta_id`, `producto_id`) | Ambas llaves determinan cantidad y precio | Sí |
| `transferencias` | `transferencia_id` | La llave determina origen, destino, producto, cantidad y estado | Sí |
| `movimientos_inventario` | `movimiento_id` | La llave determina el resto de columnas | Sí |

## Esquema final

| Tabla | Llave primaria | Llaves foráneas |
|---|---|---|
| `categorias` | `categoria_id` | `categoria_padre_id` → `categorias` |
| `proveedores` | `proveedor_id` | — |
| `almacenes` | `almacen_id` | — |
| `productos` | `producto_id` | `categoria_id`, `proveedor_id` |
| `stock_almacen` | (`producto_id`, `almacen_id`) | `producto_id`, `almacen_id` |
| `ventas` | `venta_id` | `almacen_id` |
| `detalle_venta` | (`venta_id`, `linea`) | `venta_id`, `producto_id` |
| `transferencias` | `transferencia_id` | `almacen_origen_id`, `almacen_destino_id`, `producto_id` |
| `movimientos_inventario` | `movimiento_id` | `producto_id`, `almacen_id`, `venta_id`, `transferencia_id` |

## Decisiones de diseño

- `stock_optimo` se agrega a `stock_almacen` porque el Anexo 1 no lo trae y el reporte de reabastecimiento lo necesita.
- `ventas`, `detalle_venta`, `transferencias` y `movimientos_inventario` no vienen del Anexo 1; el enunciado las exige para las rutinas de venta y transferencia.
- `precio_unitario` en `detalle_venta` y en `movimientos_inventario` guarda el precio del momento. Así el historial no cambia si después se modifica el precio del producto.
- El dinero usa `NUMERIC(12,2)` y las fechas usan `TIMESTAMPTZ`.