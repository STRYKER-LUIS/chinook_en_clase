-- =============================================================================
-- ARCHIVO: sql/01_preparacion.sql
-- OBJETIVO: Crear la tabla de auditoría para registrar cambios de precio en Chinook.
-- BASE DE DATOS: Chinook (PostgreSQL)
-- CATÁLOGO: track (Clave Primaria: track_id, Precio: unit_price)
-- =============================================================================

-- 1. Limpieza si la tabla ya existía previamente
DROP TABLE IF EXISTS auditoria_precios CASCADE;

-- 2. Creación de la tabla de auditoría
CREATE TABLE auditoria_precios (
    id_auditoria INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    track_id INT NOT NULL,
    precio_anterior NUMERIC(10, 2) NOT NULL,
    precio_nuevo NUMERIC(10, 2) NOT NULL,
    fecha_hora TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    usuario_bd VARCHAR(100) DEFAULT CURRENT_USER NOT NULL,
    CONSTRAINT fk_auditoria_track 
        FOREIGN KEY (track_id) 
        REFERENCES track (track_id) 
        ON DELETE CASCADE
);

-- 3. Documentación técnica de columnas
COMMENT ON TABLE auditoria_precios IS 'Registro automático de cambios de precio en el catálogo de pistas.';
COMMENT ON COLUMN auditoria_precios.track_id IS 'ID de la pista en la tabla track.';
COMMENT ON COLUMN auditoria_precios.precio_anterior IS 'Precio unitario anterior (NUMERIC).';
COMMENT ON COLUMN auditoria_precios.precio_nuevo IS 'Precio unitario actualizado (NUMERIC).';
COMMENT ON COLUMN auditoria_precios.fecha_hora IS 'Fecha y hora con zona horaria del cambio.';
COMMENT ON COLUMN auditoria_precios.usuario_bd IS 'Usuario de la BD que realizó el cambio.';

-- 4. Verificación de creación
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'auditoria_precios';