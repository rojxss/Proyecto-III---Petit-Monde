# Plan de recuperación ante fallos y respaldos

## Objetivo

Garantizar que la base de datos de Petit Monde se pueda recuperar ante fallos de hardware, errores humanos o desastres, con estas metas:

- **RPO:** máximo 15 minutos de datos perdidos.
- **RTO:** servicio restablecido en máximo 2 horas ante la caída total del servidor principal.

## Supuestos

- Motor: PostgreSQL. Los respaldos completos, incrementales y el archivado de WAL se hacen con pgBackRest, una herramienta de código abierto para este fin.
- Horario de operación: 16 horas diarias, que se asumen de 6:00 a.m. a 10:00 p.m. La ventana de baja actividad es de 10:00 p.m. a 6:00 a.m.
- Picos de venta: 12:00 m.d. a 2:00 p.m., 5:00 p.m. a 7:00 p.m. y sábados por la mañana. Ningún respaldo ni copia pesada se programa en esos horarios.
- Tamaño inicial de la base: 1.2 GB de datos y 400 MB de índices, es decir, 1.6 GB. Las bitácoras de auditoría y los reportes agregan unos 4 GB al mes, así que el tamaño en el mes `m` es `1.6 + 4 × m` GB.
- WAL: entre 100 y 150 MB diarios. En cierres de mes y en noviembre y diciembre el volumen sube hasta 250 %, por lo que se calcula con 3.5 veces el volumen normal (525 MB al día en el peor caso).
- Para los cálculos, 1 TB se toma como 1,000 GB.
- La empresa no contrata almacenamiento en la nube. La copia fuera de sede va a otra sucursal de la empresa.
- Los cálculos de espacio no consideran compresión, salvo que se indique.

## Cuadro de respaldos y recuperación

| Componente | Frecuencia / configuración | Ventana | Retención | Riesgos que mitiga | Justificación |
|---|---|---|---|---|---|
| Respaldo completo (Full) | Semanal, los domingos. Con compresión y verificación de integridad. | Domingo de 1:00 a.m. a 3:00 a.m. | 3 completos semanales (21 días). El primero de cada mes se guarda 6 meses. | R-01 y R-05 (RTO) | Es el punto de partida de toda restauración. El domingo de madrugada queda lejos de los picos de venta y de los cierres de mes. Se hace semanal y no diario porque un completo diario ocuparía 7 veces más espacio. Además mantiene corta la cadena de incrementales (máximo 6), lo que acelera la restauración. Se guardan 3 semanas para cubrir los 14 días de incrementales con margen. |
| Respaldos incrementales | Diario, de lunes a sábado (el domingo corre el completo). | De 1:00 a.m. a 2:00 a.m. En los cierres de mes (últimos 2 y primeros 2 días hábiles) se mueve a las 2:00 a.m. | 14 días (12 incrementales). | R-05 (RTO), R-03 y R-01 | Guardan solo lo que cambió desde el respaldo anterior, así que son pequeños: los 14 días ocupan 1.5 veces un completo, o sea unas 0.125 veces por incremental. Reducen el trabajo de restauración y permiten volver a un día anterior ante un error humano. |
| Bitácoras de transacción (WAL) | Archivado continuo: cada segmento se envía al llenarse o a los 5 minutos como máximo (`archive_timeout = 300`). Con `wal_level = replica`, `archive_mode = on`, `fsync` y `synchronous_commit` activos, y el WAL en un disco distinto al de los datos. | Las 24 horas. No necesita ventana porque el volumen es pequeño y no compite con la operación. | 30 días. | R-02 (RPO), R-01 y R-03 | Con archivado cada 5 minutos, la pérdida máxima es de unos 5 minutos más lo que tarde la copia, muy por debajo del RPO de 15. Permite la Recuperación Puntual (PITR) hasta el minuto anterior a un fallo o error. La escritura síncrona y el disco separado protegen ante apagones, comunes de mayo a noviembre. Los 30 días cubren los 3 completos semanales y ocupan 4.5 GB en operación normal y 15.75 GB en el peor caso. |
| Ubicación y retención | Tres copias: (1) servidor de respaldos en la sede central, (2) copia en Bodega Norte, San José, y (3) disco externo desconectado. | Bodega Norte: el WAL viaja de forma continua; los incrementales, a diario de 3:00 a.m. a 4:00 a.m.; el completo, el domingo de 3:00 a.m. a 6:00 a.m., con velocidad limitada y reanudando cada noche de 10:00 p.m. a 6:00 a.m. si no termina. Disco externo: el primer domingo de cada mes. | Sede central: lo indicado arriba. Bodega Norte: 2 completos semanales, 14 días de incrementales y 30 días de WAL. Disco externo: 1 completo mensual durante 12 meses. | R-04 y R-01 | Como la política prohíbe la nube, la copia fuera de sede va a otra sucursal propia, en otra ciudad y con otra red eléctrica. El WAL es muy liviano (menos de 10 KB por segundo en promedio), así que viaja casi en tiempo real sin saturar el canal. Lo pesado, el completo, se envía solo de noche y con límite de velocidad. El disco desconectado da aislamiento físico total. El servidor central avisa al llegar a 700 GB (70 %) y la alerta es crítica en 1 TB. |

## Cálculo de espacio en el servidor de respaldos

El servidor de respaldos de la sede central tiene un límite de 1 TB (1,000 GB). Con `F` como el tamaño de la base en el mes `m`:

- `F = 1.6 + 4 × m` GB
- Completos semanales: `3 × F`
- Completos mensuales (últimos 6 meses): la suma de los últimos 6 tamaños, que es `6 × F − 60`
- Incrementales de 14 días: `1.5 × F`
- WAL de 30 días en el peor caso: `30 × 0.525 = 15.75` GB

### Ejemplo en el mes 12

En el mes 12, `F = 1.6 + 48 = 49.6` GB.

| Componente | Cálculo | Espacio |
|---|---|---|
| Completos semanales | 3 × 49.6 | 148.8 GB |
| Completos mensuales (meses 7 a 12) | 29.6 + 33.6 + 37.6 + 41.6 + 45.6 + 49.6 | 237.6 GB |
| Incrementales (14 días) | 1.5 × 49.6 | 74.4 GB |
| WAL (30 días, peor caso) | 30 × 0.525 | 15.75 GB |
| **Total** | | **476.55 GB (47.7 % de 1 TB)** |

### Proyección a 24 meses

Los valores están en GB.

| Mes | Tamaño base | Semanales | Mensuales | Incrementales | WAL | Total | % de 1 TB | Con compresión del 50 % | % de 1 TB |
|---|---|---|---|---|---|---|---|---|---|
| 6 | 25.6 | 76.8 | 93.6 | 38.4 | 15.75 | 224.55 | 22.5 % | 112.3 | 11.2 % |
| 12 | 49.6 | 148.8 | 237.6 | 74.4 | 15.75 | 476.55 | 47.7 % | 238.3 | 23.8 % |
| 18 | 73.6 | 220.8 | 381.6 | 110.4 | 15.75 | 728.55 | 72.9 % | 364.3 | 36.4 % |
| 24 | 97.6 | 292.8 | 525.6 | 146.4 | 15.75 | 980.55 | 98.1 % | 490.3 | 49.0 % |

### Conclusiones

- Durante el primer año el servidor nunca pasa del 47.7 % de su capacidad, aun sin compresión.
- Sin compresión, el uso supera el 70 % en el mes 18 y llega al límite de 1 TB en el mes 25. Con una compresión del 50 % no pasa de 49 % en 24 meses. Por eso la compresión queda activa desde el inicio.
- Si el uso llega a 700 GB (70 %), la alerta preventiva se activa y se reduce la retención de completos mensuales de 6 a 3 meses. Los completos de hasta 12 meses siguen disponibles en el disco externo.
- Margen para picos: si en noviembre y diciembre los incrementales se duplicaran, el total del mes 12 subiría a 550.95 GB (55.1 %).
- Bodega Norte necesita al menos 190 GB libres al mes 12 (2 × 49.6 + 74.4 + 15.75 = 189.35 GB sin compresión).
- El disco externo necesita al menos 331.2 GB para guardar 12 completos mensuales hasta el mes 12.

## Cumplimiento del RPO

La pérdida máxima de datos es de unos 5 minutos (el `archive_timeout`) más lo que tarde la copia, que es menos de 1 minuto. Eso da unos 6 minutos, por debajo del límite de 15. El WAL se archiva en el servidor de respaldos, que es otra máquina, y llega casi en tiempo real a Bodega Norte.

## Cumplimiento del RTO

Estimación teórica para la caída total del servidor principal, con un disco de unos 100 MB por segundo y con margen sobre el tiempo de copia puro. Se confirma con las pruebas de restauración.

| Paso | Mes 12 | Mes 24 |
|---|---|---|
| Preparar un servidor sustituto e instalar PostgreSQL (script automatizado) | 30 min | 30 min |
| Restaurar el último completo (49.6 GB y 97.6 GB) | 15 min | 20 min |
| Aplicar los incrementales (máximo 6) | 10 min | 15 min |
| Reproducir el WAL desde el último incremental (máximo 1 día, 0.5 GB) | 10 min | 10 min |
| Verificar datos: conteos, stock contra movimientos y transferencias en tránsito | 15 min | 15 min |
| Reconectar aplicaciones y usuarios | 15 min | 15 min |
| **Total** | **95 min** | **105 min** |

Ambos totales quedan por debajo de los 120 minutos del RTO. Para mantener el margen en el mes 24, la restauración usa varios procesos en paralelo.

## Pruebas de restauración

- **Mensual:** el segundo domingo de cada mes, a las 4:00 a.m., se restaura el último completo con sus incrementales en un servidor de prueba. Se cronometra y se compara con el RTO.
- **Trimestral:** simulacro de PITR hasta una hora exacta y simulacro de restauración desde la copia de Bodega Norte.
- **Cada semana:** verificación automática de la integridad de los respaldos después de cada completo.
- **Después de un apagón largo:** se revisa el registro de recuperación de PostgreSQL y se verifica el último respaldo.

## Vinculación con la matriz de riesgos

| Riesgo | Cómo lo cubre este plan |
|---|---|
| R-01 Corrupción de datos | Completo semanal, incrementales y WAL permiten PITR. La prevención (RAID y S.M.A.R.T.) se complementa con la verificación semanal de integridad. |
| R-02 Pérdida de transacciones recientes | WAL archivado cada 5 minutos con escritura síncrona. Pérdida estimada de unos 6 minutos. |
| R-03 Error humano | PITR al minuto anterior al error, incrementales de 14 días y completos mensuales. RBAC y RLS reducen la probabilidad de que ocurra. |
| R-04 Saturación o fallo del almacenamiento de respaldos | Alerta al 70 %, compresión, purga automática y copias en Bodega Norte y en disco externo. |
| R-05 Superar el RTO | Cadena corta de incrementales, scripts de despliegue automatizados y pruebas mensuales. Estimación de 95 a 105 minutos. |

## Otras restricciones del negocio

- **Apagones (mayo a noviembre):** UPS en el servidor de base de datos y en el de respaldos, escritura síncrona y WAL en disco separado. Al reiniciar, PostgreSQL se recupera solo con su WAL local.
- **Transferencias en tránsito:** después de restaurar a un punto en el tiempo, se comparan las transferencias en estado `EN_TRANSITO` con la mercancía que físicamente va en camino antes de reabrir el sistema.
- **Cierres de mes:** los reportes masivos corren en horario de oficina y los respaldos en la madrugada. Durante esos 4 días el incremental se mueve a las 2:00 a.m.
- **Horas pico:** ningún respaldo ni copia pesada se programa de 12:00 m.d. a 2:00 p.m., de 5:00 p.m. a 7:00 p.m. ni los sábados por la mañana.
- **Noviembre y diciembre:** el aumento de volumen ya está incluido en los cálculos del WAL.