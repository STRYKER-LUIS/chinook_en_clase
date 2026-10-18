-- =============================================================================
-- ARCHIVO: sql/03_procedimiento.sql
-- OBJETIVO: Procedimiento almacenado para aplicar el ajuste de precio en catálogo.
-- =============================================================================

CREATE OR REPLACE PROCEDURE aplicar_ajuste_precio(
    p_track_id INT,
    p_porcentaje NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_precio_actual NUMERIC(10, 2);
    v_precio_nuevo NUMERIC(10, 2);
BEGIN
    -- 1. Validación del parámetro track_id no nulo
    IF p_track_id IS NULL THEN
        RAISE EXCEPTION 'El ID de la pista (track_id) no puede ser NULL.'
            USING ERRCODE = '22004';
    END IF;

    -- 2. Obtención del precio actual y verificación de existencia
    SELECT unit_price INTO v_precio_actual
    FROM track
    WHERE track_id = p_track_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la pista con el track_id especificado: %', p_track_id
            USING ERRCODE = 'P0002';
    END IF;

    -- 3. Reutilización de la función escalar para calcular el nuevo precio
    v_precio_nuevo := calcular_precio_ajustado(v_precio_actual, p_porcentaje);

    -- 4. Actualización exclusiva del registro solicitado
    UPDATE track
    SET unit_price = v_precio_nuevo
    WHERE track_id = p_track_id;

END;
$$;