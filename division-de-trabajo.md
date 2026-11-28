# División de trabajo

Detalle completo de dependencias: `docs/referencia/Proyecto_III_Division_y_Dependencias.pdf`.

## P1 – Modelo de datos y respaldos (Fases 1 y 6)

**Archivos SQL:** `01_esquema.sql`, `02_datos.sql`
**Documentación:** `docs/p1-modelo/`

- [x] Auditoría de anomalías de actualización, inserción y borrado
- [x] Normalización a 3FNBC (justificación paso a paso)
- [x] DER definitivo
- [x] DDL con PK, FK, CHECK, UNIQUE, NOT NULL y tipos óptimos
- [x] Incluir `stock_optimo` (no viene en el Anexo 1) y estado de transferencia (`EN_TRANSITO`/`RECIBIDA`)
- [x] Datos de prueba que cumplan los requisitos listados en `02_datos.sql`
- [x] Cuadro de recuperación y respaldos (Full, incrementales, WAL, ubicación) con cálculos contra el límite de 1 TB y sin nube
- [x] Documento de normalización + cuadro de recuperación

## P2 – Seguridad (Fases 2 y 3)

**Archivos SQL:** `03_roles.sql`, `04_rls.sql`, `07_permisos.sql`, `08_pruebas_seguridad.sql`
**Pruebas:** 1, 2, 7, 8, 10, 11, 12, 15
**Documentación:** `docs/p2-seguridad/`

- [ ] Roles `db_admin`, `inventory_manager`, `auditor` (+ usuarios de ejemplo)
- [ ] GRANT/REVOKE por mínimo privilegio, incluido `REVOKE EXECUTE ... FROM PUBLIC` en cada función
- [ ] Tabla `usuario_almacen` y políticas RLS (`USING` + `WITH CHECK`)
- [ ] Bypass de RLS autorizado para `db_admin`
- [ ] Matriz de permisos RBAC
- [ ] Arquitectura de RLS con evidencia de lo que ve cada rol

## P3 – Lógica de negocio (Fases 4 y 5)

**Archivos SQL:** `05_reportes.sql`, `06_transacciones.sql`, `09_pruebas_logica.sql`
**Pruebas:** 3, 4, 5, 6, 9, 13, 14
**Documentación:** `docs/p3-logica/`

- [ ] `sp_reporte_valoracion_reabastecimiento(INT, NUMERIC)` con tabla temporal, estados Agotado/Crítico/Óptimo, costo de reposición
- [ ] `sp_reporte_rotacion_inventario(DATE, DATE, INT)` con validación de fechas, métricas derivadas y clasificación ABC
- [ ] `COALESCE`, manejo de excepciones, (opcional) bitácora de reportes
- [ ] Rutina de venta (Checkout) transaccional
- [ ] Rutina de transferencia entre almacenes transaccional
- [ ] Documento de reportes y rutinas

## Todos

- [ ] Reunión inicial: cerrar `docs/contrato-esquema.md` (las 9 decisiones)
- [ ] Sesión de integración (medio día): correr las 15 pruebas bajo cada rol
- [ ] Un día antes: `npm run db:reset` desde BD limpia sin errores
- [ ] Informe final unificado en `docs/entrega/Informe_Final.pdf` y `npm run db:build`

## Dependencias clave (resumen)

| Quién | Necesita de | Qué |
|---|---|---|
| P2 | P1 | Nombres de tablas/columnas y datos en 2 almacenes |
| P2 | P3 | Firmas de las 4 funciones |
| P3 | P1 | Columnas de stock, movimientos, ventas, transferencias y datos |
| P3 | P2 | Roles y políticas RLS (solo para ejecutar pruebas 9, 13, 14) |
| P1 | nadie | — |

Pruebas que obligan a juntar el trabajo: **9, 10, 13 y 15**.
