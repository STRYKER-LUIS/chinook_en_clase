-- =============================================================================
-- ARCHIVO: sql/02_funcion_escalar.sql
-- OBJETIVO: Función escalar para calcular precio ajustado con validaciones.
-- =============================================================================

CREATE OR REPLACE FUNCTION calcular_precio_ajustado(
    p_precio_actual NUMERIC,
    p_porcentaje NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_precio_nuevo NUMERIC;
BEGIN
    -- 1. Validación de parámetros no nulos
    IF p_precio_actual IS NULL OR p_porcentaje IS NULL THEN
        RAISE EXCEPTION 'Los parámetros precio_actual y porcentaje no pueden ser NULL.'
            USING ERRCODE = '22004';
    END IF;

    -- 2. Validación de precio inicial positivo
    IF p_precio_actual <= 0 THEN
        RAISE EXCEPTION 'El precio actual debe ser estrictamente mayor a cero. Valor recibido: %', p_precio_actual
            USING ERRCODE = '22023';
    END IF;

    -- 3. Validación de rango de porcentaje [-50, 100]
    IF p_porcentaje < -50 OR p_porcentaje > 100 THEN
        RAISE EXCEPTION 'El porcentaje de ajuste debe estar entre -50 y 100. Valor recibido: %', p_porcentaje
            USING ERRCODE = '22023';
    END IF;

    -- 4. Cálculo de precio y redondeo a 2 decimales
    v_precio_nuevo := ROUND(p_precio_actual * (1 + p_porcentaje / 100.0), 2);

    -- 5. Validación del precio final resultante
    IF v_precio_nuevo <= 0 THEN
        RAISE EXCEPTION 'El precio resultante (%), tras el redondeo, debe ser mayor a cero.', v_precio_nuevo
            USING ERRCODE = '22023';
    END IF;

    RETURN v_precio_nuevo;
END;
$$;

-- =============================================================================
-- DEMOSTRACIÓN DE USO MEDIANTE SELECT
-- =============================================================================
SELECT 
    10.00 AS precio_base,
    calcular_precio_ajustado(10.00, 10) AS aumento_10_porc,   -- Esperado: 11.00
    calcular_precio_ajustado(10.00, -50) AS rebaja_50_porc;   -- Esperado: 5.00