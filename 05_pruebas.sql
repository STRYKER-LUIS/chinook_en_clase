-- =============================================================================
-- ARCHIVO: sql/05_pruebas.sql
-- OBJETIVO: Suite de pruebas obligatorias y casos de aceptación (Casos 1 al 8).
-- BASE DE DATOS: Chinook (PostgreSQL)
-- =============================================================================

-- Reiniciamos la tabla de auditoría para iniciar las pruebas desde un estado limpio
TRUNCATE TABLE auditoria_precios RESTART IDENTITY;

-- =============================================================================
-- CASO 1: Función Scalar - Aumento y Reducción Válidos
-- Propósito: Verificar cálculo correcto de +10% y -50% sobre un valor base de 10.00.
-- Resultado esperado: 11.00 para incremento del 10%, 5.00 para reducción del 50%.
-- =============================================================================
SELECT 
    10.00::NUMERIC AS precio_base,
    calcular_precio_ajustado(10.00, 10.00) AS aumento_10_porc,
    calcular_precio_ajustado(10.00, -50.00) AS rebaja_50_porc;


-- =============================================================================
-- CASO 2: Función Scalar - Entradas Inválidas (Pruebas Aisladas)
-- Propósito: Comprobar rechazo de nulos, precios <= 0 y porcentajes fuera de [-50, 100].
-- Resultado esperado: Error controlado en cada subcaso sin modificar datos.
-- =============================================================================

-- Subcaso 2.1: Parámetro NULL
DO $$
BEGIN
    PERFORM calcular_precio_ajustado(NULL, 10);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error capturado exitosamente (NULL): %', SQLERRM;
END $$;

-- Subcaso 2.2: Precio base menor o igual a cero
DO $$
BEGIN
    PERFORM calcular_precio_ajustado(0.00, 10);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error capturado exitosamente (Precio <= 0): %', SQLERRM;
END $$;

-- Subcaso 2.3: Porcentaje menor a -50%
DO $$
BEGIN
    PERFORM calcular_precio_ajustado(10.00, -55.00);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error capturado exitosamente (Porcentaje < -50): %', SQLERRM;
END $$;

-- Subcaso 2.4: Porcentaje mayor a 100%
DO $$
BEGIN
    PERFORM calcular_precio_ajustado(10.00, 105.00);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error capturado exitosamente (Porcentaje > 100): %', SQLERRM;
END $$;


-- =============================================================================
-- CASO 3: Procedimiento Almacenado - Cambio Válido
-- Propósito: Aplicar ajuste de +10% a pista id=1 y verificar no afectación de id=2.
-- Datos: track_id = 1 (Pista objetivo) y track_id = 2 (Pista control).
-- Resultado esperado: track_id=1 actualiza precio y genera auditoría. track_id=2 intacto.
-- =============================================================================

-- 1. Estado ANTES del cambio
SELECT track_id, name, unit_price FROM track WHERE track_id IN (1, 2) ORDER BY track_id;
SELECT COUNT(*) AS total_auditoria_antes FROM auditoria_precios;

-- 2. Ejecución del procedimiento
CALL aplicar_ajuste_precio(1, 10.00);

-- 3. Estado DESPUÉS del cambio
SELECT track_id, name, unit_price FROM track WHERE track_id IN (1, 2) ORDER BY track_id;

-- 4. Verificación de Auditoría
SELECT * FROM auditoria_precios WHERE track_id = 1;


-- =============================================================================
-- CASO 4: Procedimiento Almacenado - Identificador Inexistente
-- Propósito: Evaluar comportamiento ante un ID de pista que no existe en la base.
-- Datos: track_id = 999999.
-- Resultado esperado: Error 'P0002' (No existe la pista) y auditoría sin cambios.
-- =============================================================================
DO $$
BEGIN
    CALL aplicar_ajuste_precio(999999, 10.00);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error capturado exitosamente (ID inexistente): %', SQLERRM;
END $$;

-- Verificar que el conteo de auditoría no se incrementó
SELECT COUNT(*) AS total_auditoria_tras_caso4 FROM auditoria_precios;


-- =============================================================================
-- CASO 5: Procedimiento Almacenado - Porcentaje Inválido
-- Propósito: Evaluar rechazo de porcentaje fuera de rango en la llamada al procedimiento.
-- Datos: track_id = 1, porcentaje = 120.00.
-- Resultado esperado: Error del cálculo y estado de precio sin cambios parciales.
-- =============================================================================
DO $$
BEGIN
    CALL aplicar_ajuste_precio(1, 120.00);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error capturado exitosamente (Porcentaje inválido en proc): %', SQLERRM;
END $$;


-- =============================================================================
-- CASO 6: Trigger - UPDATE Directo sobre Catálogo
-- Propósito: Demostrar auditoría automática ante un UPDATE manual sin usar el procedimiento.
-- Datos: UPDATE directo a track_id = 2 cambiando unit_price a 1.50.
-- Resultado esperado: Se genera un nuevo registro en auditoria_precios automáticamente.
-- =============================================================================
UPDATE track 
SET unit_price = 1.50 
WHERE track_id = 2;

-- Verificación de la nueva fila en auditoría para track_id = 2
SELECT * FROM auditoria_precios WHERE track_id = 2;


-- =============================================================================
-- CASO 7: Trigger - UPDATE sin Cambio de Precio (Mismo Valor)
-- Propósito: Verificar que asignar el mismo precio no produce registros redundantes.
-- Datos: UPDATE track_id = 2 asignando nuevamente unit_price = 1.50.
-- Resultado esperado: La consulta ejecuta sin error, pero el conteo de auditoría permanece igual.
-- =============================================================================

-- Conteo antes del UPDATE sin cambio
SELECT COUNT(*) AS conteo_auditoria_antes FROM auditoria_precios;

-- UPDATE con el mismo valor actual
UPDATE track 
SET unit_price = 1.50 
WHERE track_id = 2;

-- Conteo después (debe ser igual al conteo anterior)
SELECT COUNT(*) AS conteo_auditoria_despues FROM auditoria_precios;


-- =============================================================================
-- CASO 8: Integridad Transaccional (ROLLBACK de Precio y Auditoría)
-- Propósito: Demostrar que al revertir una transacción se deshacen tanto la tabla principal como la auditoría.
-- Datos: track_id = 3 dentro de un bloque de transacción explícito (BEGIN / ROLLBACK).
-- Resultado esperado: Tras el ROLLBACK, ni el precio ni la auditoría conservan la modificación.
-- =============================================================================

BEGIN;

-- Estado inicial de la pista 3
SELECT track_id, unit_price FROM track WHERE track_id = 3;

-- Aplicación del cambio dentro de la transacción
CALL aplicar_ajuste_precio(3, 20.00);

-- Verificación dentro de la transacción (se aprecia el cambio y la auditoría)
SELECT track_id, unit_price FROM track WHERE track_id = 3;
SELECT * FROM auditoria_precios WHERE track_id = 3;

-- Reversión de la transacción
ROLLBACK;

-- Verificación final POST-ROLLBACK: El precio original vuelve y la auditoría desaparece
SELECT track_id, unit_price FROM track WHERE track_id = 3;
SELECT * FROM auditoria_precios WHERE track_id = 3;