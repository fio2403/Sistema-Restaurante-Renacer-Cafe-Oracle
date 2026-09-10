-- ------------------------------------------------------------
--  0) LIMPIEZA
--  la PRIMERA vez que corras el script estos DROP fallaran
--  con "table or view does not exist". Es normal: ignora ese error.
--  Se borran en orden inverso a las dependencias (hijos primero).
-- ------------------------------------------------------------
DROP TABLE "202601_Ingrediente_Almacen"     CASCADE CONSTRAINTS;
DROP TABLE "202601_Ingrediente_Proveedor"    CASCADE CONSTRAINTS;
DROP TABLE "202601_Plato_Ingrediente"       CASCADE CONSTRAINTS;
DROP TABLE "202601_COMPROBANTE"             CASCADE CONSTRAINTS;
DROP TABLE "202601_ADICIONALES"             CASCADE CONSTRAINTS;
DROP TABLE "202601_DETALLE_CUENTA"          CASCADE CONSTRAINTS;
DROP TABLE "202601_CUENTA"                  CASCADE CONSTRAINTS;
DROP TABLE "202601_ESTADO"                  CASCADE CONSTRAINTS;
DROP TABLE "202601_REGISTRO_DIARIO"         CASCADE CONSTRAINTS;
DROP TABLE "202601_ALMACEN"                 CASCADE CONSTRAINTS;
DROP TABLE "202601_PROVEEDOR"                CASCADE CONSTRAINTS;
DROP TABLE "202601_INGREDIENTE"             CASCADE CONSTRAINTS;
DROP TABLE "202601_PLATO_CARTA"             CASCADE CONSTRAINTS;
DROP TABLE "202601_CLIENTE"                 CASCADE CONSTRAINTS;
DROP TABLE "202601_CARGO"                   CASCADE CONSTRAINTS;

-- ------------------------------------------------------------
--  1) CREACION DE TABLAS (padres primero)
-- ------------------------------------------------------------

CREATE TABLE "202601_CARGO"
(
  Id_Tipo CHAR(10) NOT NULL,
  Nombre VARCHAR(78) NOT NULL,
  Personal FLOAT NOT NULL,
  CONSTRAINT pk_CARGO PRIMARY KEY (Id_Tipo)
);

CREATE TABLE "202601_CLIENTE"
(
  DNI CHAR(8) NOT NULL,
  Id_Cliente CHAR(10) NOT NULL,
  Nombre VARCHAR(49) NOT NULL,
  Apellido VARCHAR(25) NOT NULL,
  Numero CHAR(9) NOT NULL,
  Especialidad VARCHAR(49) NOT NULL,
  Id_Tipo CHAR(10) NOT NULL,
  CONSTRAINT pk_CLIENTE PRIMARY KEY (Id_Cliente),
  CONSTRAINT fk_CLIENTE_CARGO
    FOREIGN KEY (Id_Tipo) REFERENCES "202601_CARGO" (Id_Tipo),  
  CONSTRAINT uq_cliente_DNI UNIQUE (DNI),
  CONSTRAINT uq_cliente_Numero UNIQUE (Numero)
);

CREATE TABLE "202601_PLATO_CARTA"
(
  Id_Plato_Carta CHAR(10) NOT NULL,
  Nombre VARCHAR(49) NOT NULL,
  Precio_Venta NUMERIC(10,2) NOT NULL,
  Costo NUMERIC(10,2) NOT NULL,
  Tipo CHAR(4) NOT NULL,
  CONSTRAINT pk_Id_Plato_Carta PRIMARY KEY (Id_Plato_Carta)
);

CREATE TABLE "202601_INGREDIENTE"
(
  Id_Ingrediente CHAR(10) NOT NULL,
  Nombre VARCHAR(49) NOT NULL,
  Precio NUMERIC(10,2) NOT NULL,
  CONSTRAINT pk_Id_Ingrediente PRIMARY KEY (Id_Ingrediente)
);

CREATE TABLE "202601_PROVEEDOR"
(
  Id_Proveedor CHAR(10) NOT NULL,
  Nombre VARCHAR(49) NOT NULL,
  Ruc CHAR(11) NOT NULL,
  Numero CHAR(9) NOT NULL,
  CONSTRAINT pk_Id_Proveedor PRIMARY KEY (Id_Proveedor),
  CONSTRAINT uq_Ruc UNIQUE (Ruc),
  CONSTRAINT uq_Proveedor_Numero UNIQUE (Numero)
);

CREATE TABLE "202601_ALMACEN"
(
  Id_Almacen CHAR(10) NOT NULL,
  Cantidad NUMBER(10,2) NOT NULL,
  Nombre VARCHAR(49) NOT NULL,
  Ubicacion VARCHAR(49) NOT NULL,
  Ultimo_Precio NUMERIC(10,2) NOT NULL,
  CONSTRAINT pk_Id_Almacen PRIMARY KEY (Id_Almacen)
);

CREATE TABLE "202601_REGISTRO_DIARIO"
(
  Id_Registro_Diario CHAR(10) NOT NULL,
  Fecha DATE NOT NULL,
  Caja_Dia NUMBER(10,2) NOT NULL,
  CONSTRAINT pk_Id_Registro_Diario PRIMARY KEY (Id_Registro_Diario)
);

CREATE TABLE "202601_ESTADO"
(
  Id_Estado CHAR(10) NOT NULL,
  Nombre VARCHAR(9) NOT NULL,
  Tipo_Pago CHAR(3) NOT NULL,
  CONSTRAINT pk_Id_Estado PRIMARY KEY (Id_Estado)
);

CREATE TABLE "202601_CUENTA"
(
  Id_Cuenta CHAR(10) NOT NULL,
  Precio_Total NUMERIC(10,2) NOT NULL,
  Id_Registro_Diario CHAR(10) NOT NULL,
  Id_Estado CHAR(10) NOT NULL,
  Id_Cliente CHAR(10) NOT NULL,
  CONSTRAINT pk_Id_Cuenta PRIMARY KEY (Id_Cuenta),
  CONSTRAINT fk_CUENTA_REGISTRO_DIARIO
    FOREIGN KEY (Id_Registro_Diario) REFERENCES "202601_REGISTRO_DIARIO" (Id_Registro_Diario),
  CONSTRAINT fk_CUENTA_ESTADO
    FOREIGN KEY (Id_Estado) REFERENCES "202601_ESTADO" (Id_Estado),
  CONSTRAINT fk_CUENTA_CLIENTE
    FOREIGN KEY (Id_Cliente) REFERENCES "202601_CLIENTE" (Id_Cliente)
);

CREATE TABLE "202601_DETALLE_CUENTA"
(
  Id_Detalle CHAR(10) NOT NULL,
  Cantidad INT NOT NULL,
  Subtotal NUMERIC(10,2) NOT NULL,
  Llevar FLOAT NOT NULL,
  Id_Cuenta CHAR(10) NOT NULL,
  Id_Plato_Carta CHAR(10) NOT NULL,
  CONSTRAINT pk_Id_Detalle PRIMARY KEY (Id_Detalle),
  CONSTRAINT fk_DETALLE_CUENTA_CUENTA
    FOREIGN KEY (Id_Cuenta) REFERENCES "202601_CUENTA" (Id_Cuenta),
  CONSTRAINT fk_DETALLE_CUENTA_PLATO_CARTA
    FOREIGN KEY (Id_Plato_Carta) REFERENCES "202601_PLATO_CARTA" (Id_Plato_Carta)
);

CREATE TABLE "202601_ADICIONALES"
(
  Id_Comentario CHAR(10) NOT NULL,
  Precio NUMERIC(10,2) NOT NULL,
  Nombre VARCHAR(49) NOT NULL,
  Descuento DECIMAL(5,2) NOT NULL,
  Id_Detalle CHAR(10) NOT NULL,
  CONSTRAINT pk_Id_Comentario PRIMARY KEY (Id_Comentario),
  CONSTRAINT fk_ADICIONALES_DETALLE_CUENTA
    FOREIGN KEY (Id_Detalle) REFERENCES "202601_DETALLE_CUENTA" (Id_Detalle)
);

CREATE TABLE "202601_COMPROBANTE"
(
  Id_comprobante INT NOT NULL,
  Tipo CHAR (3) NOT NULL,
  Id_Estado CHAR(10) NOT NULL,
  CONSTRAINT pk_Id_comprobante PRIMARY KEY (Id_comprobante),
  CONSTRAINT fk_COMPROBANTE_ESTADO
    FOREIGN KEY (Id_Estado) REFERENCES "202601_ESTADO" (Id_Estado)
);

CREATE TABLE "202601_Plato_Ingrediente"
(
  Id_Plato_Carta CHAR(10) NOT NULL,
  Id_Ingrediente CHAR(10) NOT NULL,
  CONSTRAINT pk_Id_Plato_Id_Ingrediente PRIMARY KEY (Id_Plato_Carta, Id_Ingrediente),
  CONSTRAINT fk_Plato_Ingredient_PLATO_CARTA
    FOREIGN KEY (Id_Plato_Carta) REFERENCES "202601_PLATO_CARTA" (Id_Plato_Carta),
  CONSTRAINT fk_Plato_Ingredient_INGREDIENT
    FOREIGN KEY (Id_Ingrediente) REFERENCES "202601_INGREDIENTE"(Id_Ingrediente)
);

CREATE TABLE "202601_Ingrediente_Proveedor"
(
  Id_Ingrediente CHAR(10) NOT NULL,
  Id_Proveedor CHAR(10) NOT NULL,
  CONSTRAINT pk_Id_Ingrediente_Proveedor PRIMARY KEY (Id_Ingrediente, Id_Proveedor),
  CONSTRAINT fk_Ingrediente_Proveedor_INGREDIENTE
    FOREIGN KEY (Id_Ingrediente) REFERENCES "202601_INGREDIENTE" (Id_Ingrediente),
  CONSTRAINT fk_Ingrediente_Proveedor_PROVEEDOR  
    FOREIGN KEY (Id_Proveedor) REFERENCES "202601_PROVEEDOR" (Id_Proveedor)
);

CREATE TABLE "202601_Ingrediente_Almacen"
(
  Id_Ingrediente CHAR(10) NOT NULL,
  Id_Almacen CHAR(10) NOT NULL,
  CONSTRAINT pk_Id_Ingrediente_Id_Almacen PRIMARY KEY (Id_Ingrediente, Id_Almacen),
  CONSTRAINT fk_Ingrediente_Almacen_Ingrediente
    FOREIGN KEY (Id_Ingrediente) REFERENCES "202601_INGREDIENTE" (Id_Ingrediente),
  CONSTRAINT fk_Ingrediente_Almacen_ALMACEN
  FOREIGN KEY (Id_Almacen) REFERENCES "202601_ALMACEN" (Id_Almacen)
);

-- ------------------------------------------------------------
--  2) CARGA DE DATOS (mismo orden: padres primero)
-- ------------------------------------------------------------

-- 1. INSERCIÓN DE CARGOS
INSERT INTO "202601_CARGO" (Id_Tipo, Nombre, Personal) VALUES ('CARG001', 'Médico Hospital', 1);
INSERT INTO "202601_CARGO" (Id_Tipo, Nombre, Personal) VALUES ('CARG002', 'Público General', 0);

-- 2. INSERCIÓN DE CLIENTES
INSERT INTO "202601_CLIENTE" (DNI, Id_Cliente, Nombre, Apellido, Numero, Especialidad, Id_Tipo) VALUES ('44556677', 'CLI001', 'Gloria', 'Castillo', '999888777', 'Pediatría', 'CARG001');
INSERT INTO "202601_CLIENTE" (DNI, Id_Cliente, Nombre, Apellido, Numero, Especialidad, Id_Tipo) VALUES ('88776655', 'CLI002', 'Juan', 'Pérez', '911222333', 'Emergencias', 'CARG001');

-- 3. INSERCIÓN DE PRODUCTOS Y PLATOS
INSERT INTO "202601_PLATO_CARTA" (Id_Plato_Carta, Nombre, Precio_Venta, Costo, Tipo) VALUES ('PLAT001', 'Menú - Consumo Local', 16.00, 8.50, 'LOC');
INSERT INTO "202601_PLATO_CARTA" (Id_Plato_Carta, Nombre, Precio_Venta, Costo, Tipo) VALUES ('PLAT002', 'Menú - Para Llevar', 17.00, 9.00, 'LLE');
INSERT INTO "202601_PLATO_CARTA" (Id_Plato_Carta, Nombre, Precio_Venta, Costo, Tipo) VALUES ('BOD001', 'Galleta Soda (Bodega)', 1.50, 0.80, 'BOD');

-- 4. INSERCIÓN EN ALMACÉN
INSERT INTO "202601_ALMACEN" (Id_Almacen, Cantidad, Nombre, Ubicacion, Ultimo_Precio) VALUES ('ALM001', 12.5, 'Vitrina Dulces', 'Mostrador', 4.50);

-- 5. REGISTRO DIARIO
INSERT INTO "202601_REGISTRO_DIARIO" (Id_Registro_Diario, Fecha, Caja_Dia) VALUES ('REG001', TO_DATE('2026-07-15', 'YYYY-MM-DD'), 0.00);

-- 6. ESTADOS DE PAGO
INSERT INTO "202601_ESTADO" (Id_Estado, Nombre, Tipo_Pago) VALUES ('EST001', 'Cancelado', 'YAP');
INSERT INTO "202601_ESTADO" (Id_Estado, Nombre, Tipo_Pago) VALUES ('EST002', 'Cancelado', 'PLI');
INSERT INTO "202601_ESTADO" (Id_Estado, Nombre, Tipo_Pago) VALUES ('EST003', 'Pendiente', 'FIA');

-- 7. CUENTAS
INSERT INTO "202601_CUENTA" (Id_Cuenta, Precio_Total, Id_Registro_Diario, Id_Estado, Id_Cliente) VALUES ('CUE001', 16.00, 'REG001', 'EST001', 'CLI001');
INSERT INTO "202601_CUENTA" (Id_Cuenta, Precio_Total, Id_Registro_Diario, Id_Estado, Id_Cliente) VALUES ('CUE002', 34.00, 'REG001', 'EST003', 'CLI001');

-- 8. DETALLES DE CUENTAS
INSERT INTO "202601_DETALLE_CUENTA" (Id_Detalle, Cantidad, Subtotal, Llevar, Id_Cuenta, Id_Plato_Carta) VALUES ('DET001', 1, 16.00, 0, 'CUE001', 'PLAT001');
INSERT INTO "202601_DETALLE_CUENTA" (Id_Detalle, Cantidad, Subtotal, Llevar, Id_Cuenta, Id_Plato_Carta) VALUES ('DET002', 2, 34.00, 1, 'CUE002', 'PLAT002');

-- 9. ADICIONALES
INSERT INTO "202601_ADICIONALES" (Id_Comentario, Precio, Nombre, Descuento, Id_Detalle) VALUES ('COM001', 1.50, 'Porción extra de palta en entrada', 0.00, 'DET001');

-- ------------------------------------------------------------
--  2.1) CARGA DE MAS DATOS
-- ------------------------------------------------------------

-- 10. INGREDIENTES

INSERT INTO "202601_INGREDIENTE"
(Id_Ingrediente, Nombre, Precio)
VALUES ('ING001', 'Arroz', 5.50);

INSERT INTO "202601_INGREDIENTE"
(Id_Ingrediente, Nombre, Precio)
VALUES ('ING002', 'Pollo', 18.00);

INSERT INTO "202601_INGREDIENTE"
(Id_Ingrediente, Nombre, Precio)
VALUES ('ING003', 'Palta', 9.50);

INSERT INTO "202601_INGREDIENTE"
(Id_Ingrediente, Nombre, Precio)
VALUES ('ING004', 'Papa', 4.00);

-- 11. PROVEEDORES

INSERT INTO "202601_PROVEEDOR"
(Id_Proveedor, Nombre, Ruc, Numero)
VALUES ('PRO001', 'Distribuidora San José', '20111111111', '987654321');

INSERT INTO "202601_PROVEEDOR"
(Id_Proveedor, Nombre, Ruc, Numero)
VALUES ('PRO002', 'Mercado Central SAC', '20222222222', '976543210');

-- 12. RELACIÓN PLATO - INGREDIENTE

INSERT INTO "202601_Plato_Ingrediente"
VALUES ('PLAT001','ING001');

INSERT INTO "202601_Plato_Ingrediente"
VALUES ('PLAT001','ING002');

INSERT INTO "202601_Plato_Ingrediente"
VALUES ('PLAT001','ING003');

INSERT INTO "202601_Plato_Ingrediente"
VALUES ('PLAT002','ING001');

INSERT INTO "202601_Plato_Ingrediente"
VALUES ('PLAT002','ING002');

INSERT INTO "202601_Plato_Ingrediente"
VALUES ('PLAT002','ING004');

-- 13. RELACIÓN INGREDIENTE - PROVEEDOR

INSERT INTO "202601_Ingrediente_Proveedor"
VALUES ('ING001','PRO001');

INSERT INTO "202601_Ingrediente_Proveedor"
VALUES ('ING002','PRO001');

INSERT INTO "202601_Ingrediente_Proveedor"
VALUES ('ING003','PRO002');

INSERT INTO "202601_Ingrediente_Proveedor"
VALUES ('ING004','PRO002');


-- 14. RELACIÓN INGREDIENTE - ALMACÉN

INSERT INTO "202601_Ingrediente_Almacen"
VALUES ('ING001','ALM001');

INSERT INTO "202601_Ingrediente_Almacen"
VALUES ('ING002','ALM001');

INSERT INTO "202601_Ingrediente_Almacen"
VALUES ('ING003','ALM001');

INSERT INTO "202601_Ingrediente_Almacen"
VALUES ('ING004','ALM001');


-- 15. COMPROBANTES

INSERT INTO "202601_COMPROBANTE"
(Id_Comprobante, Tipo, Id_Estado)
VALUES (1,'BOL','EST001');

INSERT INTO "202601_COMPROBANTE"
(Id_Comprobante, Tipo, Id_Estado)
VALUES (2,'FAC','EST003');

-- 16. CLIENTE PÚBLICO GENERAL

INSERT INTO "202601_CLIENTE"
(DNI, Id_Cliente, Nombre, Apellido, Numero, Especialidad, Id_Tipo)
VALUES
('77889944','CLI003','Carlos','Ruiz','955111222','Ninguna','CARG002');

-- ------------------------------------------------------------
--  2.2) Prueba de funcionamiento
-- ------------------------------------------------------------

SELECT 
    c.Nombre || ' ' || c.Apellido AS "Médico",
    c.Especialidad AS "Especialidad Médica",
    SUM(cu.Precio_Total) AS "Saldo de Deuda (S/.)"
FROM "202601_CLIENTE" c
JOIN "202601_CUENTA" cu ON c.Id_Cliente = cu.Id_Cliente
JOIN "202601_ESTADO" e ON cu.Id_Estado = e.Id_Estado
WHERE e.Nombre = 'Pendiente'
GROUP BY c.Nombre, c.Apellido, c.Especialidad;

-- ------------------------------------------------------------
--  3) Triggers
-- ------------------------------------------------------------

-- 1. No permitir registrar una cuenta con un precio total menor o igual a 0
CREATE OR REPLACE TRIGGER TRG_VALIDAR_PRECIO_CUENTA
BEFORE INSERT OR UPDATE OF Precio_Total
ON "202601_CUENTA"
FOR EACH ROW
BEGIN
    IF :NEW.Precio_Total <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'El precio total de la cuenta debe ser mayor que cero.'
        );
    END IF;
END;
/


-- 2. Actualizar automáticamente la caja diaria cuando una cuenta sea cancelada
CREATE OR REPLACE TRIGGER TRG_ACTUALIZAR_CAJA
AFTER INSERT OR UPDATE OF Id_Estado
ON "202601_CUENTA"
FOR EACH ROW

DECLARE
    V_ESTADO VARCHAR2(30);

BEGIN

    SELECT Nombre
    INTO V_ESTADO
    FROM "202601_ESTADO"
    WHERE Id_Estado = :NEW.Id_Estado;

    IF V_ESTADO = 'Cancelado' THEN

        UPDATE "202601_REGISTRO_DIARIO"
        SET Caja_Dia = Caja_Dia + :NEW.Precio_Total
        WHERE Id_Registro_Diario = :NEW.Id_Registro_Diario;

    END IF;

END;
/

-- ------------------------------------------------------------
--  4) Procedures
-- ------------------------------------------------------------

--  1. Registra detalle de venta
CREATE OR REPLACE PROCEDURE SP_REGISTRAR_VENTA_DETALLE(
    p_Id_Detalle         IN CHAR,
    p_Cantidad           IN INT,
    p_Llevar             IN FLOAT,
    p_Id_Cuenta          IN CHAR,
    p_Id_Plato_Carta     IN CHAR
)
AS
    v_Precio_Venta NUMBER(10,2);
    v_Subtotal     NUMBER(10,2);
BEGIN
    -- 1. Busca el precio unitario del plato en la carta
    SELECT Precio_Venta INTO v_Precio_Venta
    FROM "202601_PLATO_CARTA"
    WHERE Id_Plato_Carta = p_Id_Plato_Carta;

    -- 2. Calcula el subtotal internamente
    v_Subtotal := v_Precio_Venta * p_Cantidad;

    -- 3. Inserta el registro en el detalle de la cuenta
    INSERT INTO "202601_DETALLE_CUENTA" (Id_Detalle, Cantidad, Subtotal, Llevar, Id_Cuenta, Id_Plato_Carta)
    VALUES (p_Id_Detalle, p_Cantidad, v_Subtotal, p_Llevar, p_Id_Cuenta, p_Id_Plato_Carta);

    -- 4. Actualiza el precio total acumulado de la cuenta principal
    UPDATE "202601_CUENTA"
    SET Precio_Total = Precio_Total + v_Subtotal
    WHERE Id_Cuenta = p_Id_Cuenta;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Detalle de venta registrado correctamente.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: El código de plato ingresado no existe.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error al registrar la venta.');
END;
/

--  2. Reporte de deudores

CREATE OR REPLACE PROCEDURE SP_GENERAR_REPORTE_FIADOS 
AS
    -- Cursor clásico para seleccionar los datos de las cuentas pendientes
    CURSOR C_FIADOS IS
        SELECT 
            cl.Nombre || ' ' || cl.Apellido AS CLIENTE,
            cl.Especialidad AS AREA,
            cu.Id_Cuenta AS COD_CUENTA,
            cu.Precio_Total AS MONTO_PENDIENTE
        FROM "202601_CLIENTE" cl
        JOIN "202601_CUENTA" cu ON cl.Id_Cliente = cu.Id_Cliente
        JOIN "202601_ESTADO" es ON cu.Id_Estado = es.Id_Estado
        WHERE es.Nombre = 'Pendiente'
        ORDER BY cu.Precio_Total DESC;
BEGIN
    DBMS_OUTPUT.PUT_LINE('======================================================');
    DBMS_OUTPUT.PUT_LINE('     REPORTE DE CLIENTES CON CUENTAS FIADAS           ');
    DBMS_OUTPUT.PUT_LINE('======================================================');
    
    -- Bucle FOR estándar para recorrer el cursor
    FOR R IN C_FIADOS LOOP
        DBMS_OUTPUT.PUT_LINE('Cliente: ' || R.CLIENTE || ' | Area: ' || R.AREA || ' | Cuenta: ' || R.COD_CUENTA || ' | Total Deuda: S/. ' || R.MONTO_PENDIENTE);
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('======================================================');
END;
/

-- ------------------------------------------------------------
--  4) FUNCTIONS
-- ------------------------------------------------------------

--  1. Ingredientes en un plato
CREATE OR REPLACE FUNCTION FN_CANTIDAD_INGREDIENTES (
    p_Id_Plato IN CHAR
)
RETURN NUMBER
IS
    v_Cantidad NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_Cantidad
    FROM "202601_Plato_Ingrediente"
    WHERE Id_Plato_Carta = p_Id_Plato;

    RETURN v_Cantidad;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;
/

--  2. Ganancia estimada de un palto

CREATE OR REPLACE FUNCTION FN_GANANCIA_PLATO (
    p_Id_Plato IN CHAR
)
RETURN NUMBER
IS
    v_Ganancia NUMBER(10,2);
BEGIN
    SELECT Precio_Venta - Costo
    INTO v_Ganancia
    FROM "202601_PLATO_CARTA"
    WHERE Id_Plato_Carta = p_Id_Plato;

    RETURN v_Ganancia;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/
------------------------------------------------------
--  5) PRUEBAS DE FUNCIONAMIENTO
------------------------------------------------------

------------------------------------------------------
-- 1. CONSULTAS DE PRUEBA (SELECT)
------------------------------------------------------

-- Listado de clientes
SELECT * FROM "202601_CLIENTE";

-- Listado de cuentas con su estado
SELECT
    c.Nombre,
    c.Apellido,
    cu.Id_Cuenta,
    cu.Precio_Total,
    e.Nombre AS Estado
FROM "202601_CLIENTE" c
JOIN "202601_CUENTA" cu
ON c.Id_Cliente = cu.Id_Cliente
JOIN "202601_ESTADO" e
ON cu.Id_Estado = e.Id_Estado;

-- Ingredientes de cada plato
SELECT
    p.Nombre AS Plato,
    i.Nombre AS Ingrediente
FROM "202601_PLATO_CARTA" p
JOIN "202601_Plato_Ingrediente" pi
ON p.Id_Plato_Carta = pi.Id_Plato_Carta
JOIN "202601_INGREDIENTE" i
ON pi.Id_Ingrediente = i.Id_Ingrediente;

------------------------------------------------------
-- 2. PRUEBAS DE UPDATE
------------------------------------------------------

-- Actualizar teléfono del cliente
UPDATE "202601_CLIENTE"
SET Numero = '900111222'
WHERE Id_Cliente = 'CLI003';

-- Verificar actualización
SELECT *
FROM "202601_CLIENTE"
WHERE Id_Cliente='CLI003';

------------------------------------------------------
-- 3. PRUEBAS DE DELETE
------------------------------------------------------

-- Eliminar un adicional
DELETE FROM "202601_ADICIONALES"
WHERE Id_Comentario='COM001';

-- Verificar eliminación
SELECT *
FROM "202601_ADICIONALES";

------------------------------------------------------
-- 4. PRUEBAS DE TRIGGERS
------------------------------------------------------

-- Trigger de validación de precio (debe producir error)
INSERT INTO "202601_CUENTA"
(Id_Cuenta, Precio_Total, Id_Registro_Diario, Id_Estado, Id_Cliente)
VALUES
('CUE004',0,'REG001','EST001','CLI001');

-- Cambiar una cuenta pendiente a cancelada
UPDATE "202601_CUENTA"
SET Id_Estado='EST001'
WHERE Id_Cuenta='CUE002';

-- Verificar actualización de caja
SELECT *
FROM "202601_REGISTRO_DIARIO";

------------------------------------------------------
-- 5. PRUEBAS DE PROCEDURES
------------------------------------------------------

-- Registrar un nuevo detalle de venta
BEGIN
    SP_REGISTRAR_VENTA_DETALLE(
        'DET003',
        2,
        0,
        'CUE002',
        'PLAT001'
    );
END;
/

-- Verificar detalle insertado
SELECT *
FROM "202601_DETALLE_CUENTA"
WHERE Id_Detalle='DET003';

-- Verificar actualización del total de la cuenta
SELECT *
FROM "202601_CUENTA"
WHERE Id_Cuenta='CUE002';

-- Ejecutar reporte de clientes con deuda
BEGIN
    SP_GENERAR_REPORTE_FIADOS;
END;
/

------------------------------------------------------
-- 6. PRUEBAS DE FUNCTIONS
------------------------------------------------------

-- Cantidad de ingredientes de un plato
SELECT
FN_CANTIDAD_INGREDIENTES('PLAT001') AS TOTAL_INGREDIENTES
FROM DUAL;

-- Ganancia estimada del plato
SELECT
FN_GANANCIA_PLATO('PLAT001') AS GANANCIA
FROM DUAL;

COMMIT;


