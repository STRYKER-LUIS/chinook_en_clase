# Sistema de Auditoría y Control de Precios en PostgreSQL (Chinook)

## Descripción del Proyecto
Este proyecto implementa la lógica de negocio para la gestión controlada y trazable de cambios de precios en un catálogo de tienda digital, utilizando la base de datos de ejemplo **Chinook**.

El sistema garantiza:
1. **Cálculo previo sin modificación:** Simulación y validación del precio ajustado.
2. **Control de actualización:** Validación estricta de parámetros e inexistencia de cambios parciales.
3. **Auditoría automática:** Registro de historiales de precios previa comparación efectiva (`OLD` vs `NEW`), independiente de las acciones manuales del usuario.

---

## Entorno de Ejecución
* **Motor BD:** PostgreSQL 18.x
* **Base de Datos:** `chinook_parcial`
* **Cliente SQL:** DataGrip / pgAdmin 4
* **Esquema:** `public`
* **Tabla Catálogo:** `track` (ID: `track_id`, Precio: `unit_price`)
* **Fuente de Chinook:** Script oficial de Chinook para PostgreSQL (`Chinook_PostgreSql.sql`).

---

## Estructura del Repositorio
```text
.
├── sql/
│   ├── 01_preparacion.sql          # Creación de tabla auditoria_precios y llaves foráneas
│   ├── 02_funcion_escalar.sql      # Función calcular_precio_ajustado()
│   ├── 03_procedimiento.sql        # Procedimiento aplicar_ajuste_precio()
│   ├── 04_trigger_y_funcion.sql    # Trigger y función fn_auditar_cambio_precio()
│   └── 05_pruebas.sql              # Suite de 8 casos de prueba y aceptación
└── README.md                       # Documentación del proyecto