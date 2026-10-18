-- =============================================================================
-- ARCHIVO: sql/04_trigger_y_funcion.sql
-- OBJETIVO: Función de soporte PL/pgSQL y Trigger AFTER UPDATE para auditoría.
-- =============================================================================

-- 1. Función de soporte del trigger
CREATE OR REPLACE FUNCTION fn_auditar_cambio_precio()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Registrar únicamente si hubo un cambio efectivo en el precio
    IF OLD.unit_price IS DISTINCT FROM NEW.unit_price THEN
        INSERT INTO auditoria_precios (
            track_id,
            precio_anterior,
            precio_nuevo,
            fecha_hora,
            usuario_bd
        ) VALUES (
            NEW.track_id,
            OLD.unit_price,
            NEW.unit_price,
            CURRENT_TIMESTAMP,
            CURRENT_USER
        );
    END IF;

    RETURN NEW;
END;
$$;

-- 2. Definición del trigger sobre la tabla track
DROP TRIGGER IF EXISTS trg_auditar_cambio_precio ON track;

CREATE TRIGGER trg_auditar_cambio_precio
AFTER UPDATE OF unit_price ON track
FOR EACH ROW
EXECUTE FUNCTION fn_auditar_cambio_precio();