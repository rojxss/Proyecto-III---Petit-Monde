# Petit Monde – Auditoría y rediseño de la BD de inventarios

Proyecto III del curso de Bases de Datos. Se parte de una tabla plana y desnormalizada (Anexo 1 del enunciado) y se entrega:

1. Esquema normalizado hasta 3FNBC (Fase 1)
2. Control de acceso por roles, RBAC (Fase 2)
3. Seguridad a nivel de fila, RLS (Fase 3)
4. Dos reportes analíticos como procedimientos/funciones (Fase 4)
5. Dos rutinas transaccionales ACID: venta y transferencia (Fase 5)
6. Plan teórico de recuperación y respaldos (Fase 6)
7. 15 pruebas funcionales por rol + informe técnico en PDF

**Motor:** PostgreSQL 16 (PL/pgSQL). Los "stored procedures" son funciones `RETURNS TABLE`.

## Estructura

```
petit-monde-inventarios/
├── database/                 # Scripts SQL numerados (se ejecutan en orden)
│   ├── run_all.sql           # Orquesta todo desde cero
│   ├── 00_reset.sql          # Limpieza
│   ├── 01_esquema.sql        # P1  Fase 1
│   ├── 02_datos.sql          # P1  Datos de prueba
│   ├── 03_roles.sql          # P2  Fase 2 (crear roles)
│   ├── 04_rls.sql            # P2  Fase 3
│   ├── 05_reportes.sql       # P3  Fase 4
│   ├── 06_transacciones.sql  # P3  Fase 5
│   ├── 07_permisos.sql       # P2  Fase 2 (GRANT/REVOKE)
│   ├── 08_pruebas_seguridad.sql  # P2  pruebas 1,2,7,8,10,11,12,15
│   └── 09_pruebas_logica.sql     # P3  pruebas 3,4,5,6,9,13,14
├── docs/
│   ├── contrato-esquema.md   # Acuerdos compartidos (nombres, firmas)  ← leer primero
│   ├── p1-modelo/            # Normalización, respaldos
│   ├── p2-seguridad/         # Matriz RBAC, arquitectura RLS
│   ├── p3-logica/            # Reportes y transacciones
│   ├── entrega/              # Informe final (PDF)
│   └── referencia/           # Enunciado y división de trabajo (PDF)
├── scripts/
│   ├── db-run.sh             # Reconstruir BD / ejecutar un archivo / abrir psql
│   └── build-entrega.sh      # Genera el .zip de entrega
├── .github/pull_request_template.md
├── docker-compose.yml        # PostgreSQL local
├── .env.example
├── package.json              # Atajos: npm run db:*
├── division-de-trabajo.md
└── README.md
```

> No hay carpeta `app/`: el proyecto es 100 % base de datos. Si el profesor pide una interfaz, se agrega después.

## Puesta en marcha

Requisitos: Docker (o PostgreSQL 16 instalado) y `psql`.

```bash
cp .env.example .env        # ajustar si hace falta
npm run db:up               # levanta PostgreSQL (docker compose up -d)
npm run db:reset            # reconstruye TODO desde cero y corre las pruebas
npm run db:psql             # consola psql
```

Para ejecutar un solo archivo mientras desarrollan:

```bash
bash scripts/db-run.sh 05_reportes.sql
```

> Sin npm también sirve: `bash scripts/db-run.sh`.

## Flujo de trabajo en Git

- `main`: siempre ejecutable de principio a fin (`npm run db:reset` sin errores).
- Una rama por persona: `p1/modelo`, `p2/seguridad`, `p3/logica`. Ramas cortas adicionales con prefijo `p#/`.
- Cada quien edita **solo sus archivos** (ver `division-de-trabajo.md`), así casi no hay conflictos.
- Cambios a `docs/contrato-esquema.md`, `00_reset.sql` o `run_all.sql` se avisan al grupo antes del PR.
- Pull Request a `main` con al menos 1 revisión de otro compañero.

## Convenciones SQL

- Todo en el schema `inventario`; nombres en `snake_case` y en español.
- Dinero siempre `NUMERIC(12,2)`; fechas `DATE` / `TIMESTAMPTZ`.
- Scripts **re-ejecutables desde cero** (el reset limpia antes).
- Funciones `SECURITY INVOKER` (para que RLS aplique).
- Comentar cada bloque; encabezado con dueño y fase.

## Entrega

```bash
# poner el informe final en docs/entrega/Informe_Final.pdf
npm run db:build            # genera entrega/Proyecto3_PetitMonde.zip (.sql + PDF)
```

## Integrantes

| Persona | Nombre | Parte |
|---|---|---|
| P1 | _por completar_ | Modelo de datos y respaldos |
| P2 | _por completar_ | Seguridad (RBAC + RLS) |
| P3 | _por completar_ | Lógica de negocio (reportes + transacciones) |
