# Anomalías del esquema original

El Anexo 1 guarda todo en una sola tabla de 21 columnas, con una fila por cada producto en cada almacén. Los ejemplos salen de esos datos.

## Redundancia de datos

| Dato repetido | Dónde se repite |
|---|---|
| Proveedor Tech Supplies Co. (Carlos Ruiz, +506 8888-1111, Costa Rica) | Filas 1001 y 1002 |
| Proveedor Muebles & Confort (Ana Gómez, +506 8888-2222, Costa Rica) | Filas 1003 y 1004 |
| Proveedor Importadora Global (Luis Mora, +506 8888-3333, Costa Rica) | Filas 1005 y 1006 |
| Almacén Central y su ubicación (Cartago, Costa Rica) | Filas 1001 a 1004 |
| Bodega Norte y su ubicación (San José, Costa Rica) | Filas 1005 y 1006 |
| Categoría Electrónica | Filas 1001 y 1002 |

Además, `ValorTotalStock` y `EstadoStock` se pueden calcular con otras columnas (por ejemplo, 15 × 180.00 = 2,700.00), pero la tabla los guarda como datos.

## Anomalías de actualización

| Cambio | Qué obliga a hacer | Riesgo |
|---|---|---|
| Cambiar el teléfono de Tech Supplies Co. | Editar las filas 1001 y 1002 | Si se edita solo una, el mismo proveedor queda con dos teléfonos |
| Cambiar la ubicación del Almacén Central | Editar las filas 1001 a 1004 | El mismo almacén aparece en lugares distintos |
| Subir el costo de ELE-101 de 180.00 a 190.00 | Recalcular `ValorTotalStock` a mano | La fila queda con 2,700.00 y un costo que ya no corresponde |
| Vender las últimas unidades de un producto | Cambiar `EstadoStock` a mano | Un producto con cantidad 0 sigue apareciendo como "En Stock" |
| Registrar una nueva entrada de mercancía | Sobrescribir `FechaÚltimaEntrada` y `CantidadÚltimaEntrada` | Se pierden las entradas anteriores y no hay trazabilidad |

## Anomalías de inserción

| Situación | Problema |
|---|---|
| Registrar un proveedor nuevo que aún no tiene productos | No hay dónde guardarlo sin inventar una fila de stock ficticia |
| Registrar un almacén nuevo vacío | Igual: se necesita una fila de producto y cantidad falsa |
| Registrar una categoría nueva sin productos | No se puede guardar sola |
| Registrar un producto que todavía no tiene stock | Obliga a elegir un almacén y una cantidad |
| Agregar un producto de un proveedor que ya existe | Hay que escribir de nuevo su contacto y teléfono; un error de escritura (por ejemplo "Tech Supplies" en vez de "Tech Supplies Co.") crea un proveedor distinto |

## Anomalías de borrado

| Situación | Qué se pierde sin querer |
|---|---|
| Borrar la fila 1004 (OFF-202, agotado) para quitar su stock del Almacén Central | El producto completo: nombre, costo y precio |
| Borrar las filas 1005 y 1006 (únicas de Bodega Norte) | Bodega Norte con su ubicación, y también Importadora Global con su contacto |
| Borrar las filas 1003 y 1004 al descontinuar sillas y escritorios | El proveedor Muebles & Confort y su contacto |

## Cómo las resuelve el nuevo diseño

| Anomalía | Solución |
|---|---|
| Datos de proveedor o almacén repetidos | Cada uno vive en una sola fila de `proveedores` o `almacenes`; el producto solo guarda el `proveedor_id` |
| Valor total y estado desactualizados | No se guardan; se calculan en los reportes con `cantidad`, `costo_unitario` y `stock_minimo` |
| Pérdida del historial de entradas | `movimientos_inventario` guarda cada entrada y salida con su fecha |
| No poder registrar proveedores, almacenes o categorías sin productos | Cada uno tiene su propia tabla, independiente del stock |
| Borrar de más | Quitar stock solo toca `stock_almacen`, y las llaves foráneas impiden borrar lo que está en uso |