import os
from decimal import Decimal
from functools import wraps

import oracledb
from dotenv import load_dotenv
from flask import Flask, flash, redirect, render_template, request, url_for

load_dotenv()

APP_VERSION = "2026.07-VENTAS-CORREGIDAS"

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "clave-local-restaurante")

DB_USER = os.getenv("DB_USER", "SYSTEM").strip()
DB_PASSWORD = os.getenv("DB_PASSWORD", "").strip()
DB_DSN = os.getenv("DB_DSN", "localhost:1521/XE").strip()

# Déjalo vacío cuando las tablas pertenecen al mismo usuario de DB_USER.
# Si fueron creadas por otro usuario, coloca por ejemplo: RESTAURANTE
DB_SCHEMA = os.getenv("DB_SCHEMA", "SYSTEM").strip().upper() or "SYSTEM"


def conectar():
    return oracledb.connect(
        user=DB_USER,
        password=DB_PASSWORD,
        dsn=DB_DSN
    )


def tabla(nombre):
    """
    Devuelve una tabla Oracle con comillas dobles.
    Esto es obligatorio porque los nombres comienzan con números
    y algunos tienen mezcla de mayúsculas/minúsculas.
    """
    nombre_seguro = nombre.replace('"', '')
    if DB_SCHEMA:
        return f'{DB_SCHEMA}."{nombre_seguro}"'
    return f'"{nombre_seguro}"'


T_CARGO = tabla("202601_CARGO")
T_CLIENTE = tabla("202601_CLIENTE")
T_PLATO = tabla("202601_PLATO_CARTA")
T_REGISTRO = tabla("202601_REGISTRO_DIARIO")
T_ESTADO = tabla("202601_ESTADO")
T_CUENTA = tabla("202601_CUENTA")
T_DETALLE = tabla("202601_DETALLE_CUENTA")
T_PLATO_ING = tabla("202601_Plato_Ingrediente")


def limpiar(valor):
    return valor.strip() if isinstance(valor, str) else valor


def filas_diccionario(cursor):
    columnas = [col[0].lower() for col in cursor.description]
    return [
        {columnas[i]: limpiar(valor) for i, valor in enumerate(fila)}
        for fila in cursor.fetchall()
    ]


def siguiente_codigo(conexion, tabla_sql, columna, prefijo, digitos=3):
    sql = f"""
        SELECT MAX(
            TO_NUMBER(
                REGEXP_SUBSTR(TRIM({columna}), '[0-9]+$')
            )
        )
        FROM {tabla_sql}
        WHERE TRIM({columna}) LIKE :prefijo
    """
    with conexion.cursor() as cursor:
        cursor.execute(sql, prefijo=f"{prefijo}%")
        ultimo = cursor.fetchone()[0] or 0
    return f"{prefijo}{int(ultimo) + 1:0{digitos}d}"


@app.context_processor
def contexto_global():
    return {
        "db_user": DB_USER,
        "db_schema": DB_SCHEMA or DB_USER,
    }


@app.route("/")
def inicio():
    indicadores = {
        "clientes": 0,
        "platos": 0,
        "fiados": 0,
        "caja": Decimal("0.00"),
    }

    consultas = {
        "clientes": f"SELECT COUNT(*) FROM {T_CLIENTE}",
        "platos": f"SELECT COUNT(*) FROM {T_PLATO}",
        "fiados": f"""
            SELECT COUNT(*)
            FROM {T_CUENTA} cu
            JOIN {T_ESTADO} es
              ON cu.Id_Estado = es.Id_Estado
            WHERE UPPER(TRIM(es.Nombre)) = 'PENDIENTE'
        """,
        "caja": f"SELECT NVL(SUM(Caja_Dia), 0) FROM {T_REGISTRO}",
    }

    errores = []
    try:
        with conectar() as conexion:
            with conexion.cursor() as cursor:
                for clave, sql in consultas.items():
                    try:
                        cursor.execute(sql)
                        indicadores[clave] = cursor.fetchone()[0] or 0
                    except oracledb.Error as error:
                        errores.append(f"{clave}: {error}")
    except oracledb.Error as error:
        errores.append(f"conexión: {error}")

    if errores:
        flash(
            "Algunos indicadores no pudieron cargarse: " + " | ".join(errores),
            "error",
        )

    return render_template("index.html", indicadores=indicadores)


@app.route("/conexion")
def probar_conexion():
    try:
        with conectar() as conexion:
            with conexion.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT
                        USER,
                        SYS_CONTEXT('USERENV', 'SERVICE_NAME')
                    FROM DUAL
                    """
                )
                usuario, servicio = cursor.fetchone()

        flash(
            f"Conexión correcta. Usuario: {usuario}; servicio: {servicio}.",
            "success",
        )
    except oracledb.Error as error:
        flash(f"Error de conexión: {error}", "error")

    return redirect(url_for("inicio"))


@app.route("/diagnostico")
def diagnostico():
    datos = {
        "usuario": None,
        "servicio": None,
        "tablas_usuario": [],
        "tablas_accesibles": [],
        "esperadas": [
            "202601_CARGO",
            "202601_CLIENTE",
            "202601_PLATO_CARTA",
            "202601_REGISTRO_DIARIO",
            "202601_ESTADO",
            "202601_CUENTA",
            "202601_DETALLE_CUENTA",
            "202601_Plato_Ingrediente",
        ],
        "pruebas": [],
    }

    try:
        with conectar() as conexion:
            with conexion.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT USER, SYS_CONTEXT('USERENV', 'SERVICE_NAME')
                    FROM DUAL
                    """
                )
                datos["usuario"], datos["servicio"] = cursor.fetchone()

                cursor.execute(
                    """
                    SELECT TABLE_NAME
                    FROM USER_TABLES
                    WHERE TABLE_NAME LIKE '202601%'
                    ORDER BY TABLE_NAME
                    """
                )
                datos["tablas_usuario"] = [fila[0] for fila in cursor.fetchall()]

                cursor.execute(
                    """
                    SELECT OWNER, TABLE_NAME
                    FROM ALL_TABLES
                    WHERE TABLE_NAME LIKE '202601%'
                    ORDER BY OWNER, TABLE_NAME
                    """
                )
                datos["tablas_accesibles"] = [
                    {"owner": fila[0], "table_name": fila[1]}
                    for fila in cursor.fetchall()
                ]

                pruebas = [
                    ("Clientes", T_CLIENTE),
                    ("Platos", T_PLATO),
                    ("Cuentas", T_CUENTA),
                    ("Estados", T_ESTADO),
                    ("Caja diaria", T_REGISTRO),
                ]

                for etiqueta, tabla_sql in pruebas:
                    try:
                        cursor.execute(f"SELECT COUNT(*) FROM {tabla_sql}")
                        total = cursor.fetchone()[0]
                        datos["pruebas"].append(
                            {"nombre": etiqueta, "tabla": tabla_sql, "ok": True, "total": total}
                        )
                    except oracledb.Error as error:
                        datos["pruebas"].append(
                            {"nombre": etiqueta, "tabla": tabla_sql, "ok": False, "error": str(error)}
                        )

    except oracledb.Error as error:
        flash(f"No fue posible ejecutar el diagnóstico: {error}", "error")

    return render_template("diagnostico.html", datos=datos)


@app.route("/clientes", methods=["GET", "POST"])
def clientes():
    if request.method == "POST":
        try:
            with conectar() as conexion:
                id_cliente = request.form["id_cliente"].strip().upper()
                dni = request.form["dni"].strip()
                nombre = request.form["nombre"].strip()
                apellido = request.form["apellido"].strip()
                numero = request.form["numero"].strip()
                especialidad = request.form["especialidad"].strip()
                id_tipo = request.form["id_tipo"].strip().upper()

                if not all(
                    [id_cliente, dni, nombre, apellido, numero, especialidad, id_tipo]
                ):
                    flash("Completa todos los campos del cliente.", "error")
                    return redirect(url_for("clientes"))

                sql = f"""
                    INSERT INTO {T_CLIENTE}
                    (
                        DNI, Id_Cliente, Nombre, Apellido,
                        Numero, Especialidad, Id_Tipo
                    )
                    VALUES
                    (
                        :dni, :id_cliente, :nombre, :apellido,
                        :numero, :especialidad, :id_tipo
                    )
                """

                with conexion.cursor() as cursor:
                    cursor.execute(
                        sql,
                        dni=dni,
                        id_cliente=id_cliente,
                        nombre=nombre,
                        apellido=apellido,
                        numero=numero,
                        especialidad=especialidad,
                        id_tipo=id_tipo,
                    )
                conexion.commit()

            flash("Cliente registrado correctamente.", "success")

        except oracledb.Error as error:
            flash(f"No se pudo registrar el cliente: {error}", "error")

        return redirect(url_for("clientes"))

    lista = []
    cargos = []
    codigo_sugerido = "CLI001"

    try:
        with conectar() as conexion:
            codigo_sugerido = siguiente_codigo(
                conexion, T_CLIENTE, "Id_Cliente", "CLI"
            )

            with conexion.cursor() as cursor:
                cursor.execute(
                    f"""
                    SELECT
                        TRIM(c.Id_Cliente) AS Id_Cliente,
                        TRIM(c.DNI) AS DNI,
                        c.Nombre,
                        c.Apellido,
                        TRIM(c.Numero) AS Numero,
                        c.Especialidad,
                        TRIM(c.Id_Tipo) AS Id_Tipo,
                        ca.Nombre AS Cargo
                    FROM {T_CLIENTE} c
                    JOIN {T_CARGO} ca
                      ON c.Id_Tipo = ca.Id_Tipo
                    ORDER BY c.Nombre, c.Apellido
                    """
                )
                lista = filas_diccionario(cursor)

                cursor.execute(
                    f"""
                    SELECT TRIM(Id_Tipo) AS Id_Tipo, Nombre
                    FROM {T_CARGO}
                    ORDER BY Nombre
                    """
                )
                cargos = filas_diccionario(cursor)

    except oracledb.Error as error:
        flash(f"Error al listar clientes: {error}", "error")

    return render_template(
        "clientes.html",
        clientes=lista,
        cargos=cargos,
        codigo_sugerido=codigo_sugerido,
    )


@app.post("/clientes/eliminar/<id_cliente>")
def eliminar_cliente(id_cliente):
    try:
        with conectar() as conexion:
            with conexion.cursor() as cursor:
                cursor.execute(
                    f"DELETE FROM {T_CLIENTE} WHERE Id_Cliente = :id",
                    id=id_cliente,
                )
            conexion.commit()
        flash("Cliente eliminado.", "success")
    except oracledb.Error as error:
        flash(
            "No se puede eliminar el cliente si tiene cuentas relacionadas. "
            f"Detalle: {error}",
            "error",
        )
    return redirect(url_for("clientes"))


@app.route("/platos", methods=["GET", "POST"])
def platos():
    if request.method == "POST":
        try:
            with conectar() as conexion:
                datos = {
                    "id_plato": request.form["id_plato"].strip().upper(),
                    "nombre": request.form["nombre"].strip(),
                    "precio": request.form["precio"].strip(),
                    "costo": request.form["costo"].strip(),
                    "tipo": request.form["tipo"].strip().upper(),
                }

                if not all(datos.values()):
                    flash("Completa todos los campos del plato.", "error")
                    return redirect(url_for("platos"))

                with conexion.cursor() as cursor:
                    cursor.execute(
                        f"""
                        INSERT INTO {T_PLATO}
                        (Id_Plato_Carta, Nombre, Precio_Venta, Costo, Tipo)
                        VALUES
                        (:id_plato, :nombre, :precio, :costo, :tipo)
                        """,
                        **datos,
                    )
                conexion.commit()

            flash("Plato registrado correctamente.", "success")

        except (oracledb.Error, ValueError) as error:
            flash(f"No se pudo registrar el plato: {error}", "error")

        return redirect(url_for("platos"))

    lista = []
    codigo_sugerido = "PLAT001"

    try:
        with conectar() as conexion:
            codigo_sugerido = siguiente_codigo(
                conexion, T_PLATO, "Id_Plato_Carta", "PLAT"
            )

            with conexion.cursor() as cursor:
                # Las funciones son opcionales: si están inválidas, usamos SQL directo.
                cursor.execute(
                    f"""
                    SELECT
                        TRIM(p.Id_Plato_Carta) AS Id_Plato_Carta,
                        p.Nombre,
                        p.Precio_Venta,
                        p.Costo,
                        TRIM(p.Tipo) AS Tipo,
                        (p.Precio_Venta - p.Costo) AS Ganancia,
                        (
                            SELECT COUNT(*)
                            FROM {T_PLATO_ING} pi
                            WHERE pi.Id_Plato_Carta = p.Id_Plato_Carta
                        ) AS Cantidad_Ingredientes
                    FROM {T_PLATO} p
                    ORDER BY p.Nombre
                    """
                )
                lista = filas_diccionario(cursor)

    except oracledb.Error as error:
        flash(f"Error al listar platos: {error}", "error")

    return render_template(
        "platos.html",
        platos=lista,
        codigo_sugerido=codigo_sugerido,
    )


@app.post("/platos/eliminar/<id_plato>")
def eliminar_plato(id_plato):
    try:
        with conectar() as conexion:
            with conexion.cursor() as cursor:
                cursor.execute(
                    f"DELETE FROM {T_PLATO} WHERE Id_Plato_Carta = :id",
                    id=id_plato,
                )
            conexion.commit()
        flash("Plato eliminado.", "success")
    except oracledb.Error as error:
        flash(
            "No se puede eliminar el plato si tiene ingredientes o ventas relacionadas. "
            f"Detalle: {error}",
            "error",
        )
    return redirect(url_for("platos"))


@app.route("/ventas", methods=["GET", "POST"])
def ventas():
    if request.method == "POST":
        try:
            with conectar() as conexion:
                id_cuenta = request.form["id_cuenta"].strip().upper()
                id_detalle = request.form["id_detalle"].strip().upper()
                id_cliente = request.form["id_cliente"].strip().upper()
                id_estado = request.form["id_estado"].strip().upper()
                id_registro = request.form["id_registro"].strip().upper()
                id_plato = request.form["id_plato"].strip().upper()
                cantidad = int(request.form["cantidad"])
                llevar = int(request.form.get("llevar", "0"))

                if cantidad <= 0:
                    raise ValueError("La cantidad debe ser mayor que cero.")

                with conexion.cursor() as cursor:
                    # Recuperamos todos los códigos y comparamos normalizados en Python.
                    # Esto evita problemas con columnas CHAR(10) rellenadas con espacios.
                    cursor.execute(
                        f"""
                        SELECT Id_Plato_Carta, Precio_Venta
                        FROM {T_PLATO}
                        """
                    )

                    fila_plato = None
                    codigo_buscado = id_plato.strip().upper()

                    for codigo_oracle, precio_oracle in cursor.fetchall():
                        codigo_normalizado = str(codigo_oracle).strip().upper()
                        if codigo_normalizado == codigo_buscado:
                            fila_plato = (codigo_oracle, precio_oracle)
                            break

                    if fila_plato is None:
                        raise ValueError(
                            f"El plato seleccionado no existe. Código recibido: {codigo_buscado}"
                        )

                    id_plato_oracle = fila_plato[0]
                    precio = Decimal(str(fila_plato[1]))
                    subtotal = precio * cantidad

                    # La tabla exige Precio_Total > 0 por el trigger.
                    cursor.execute(
                        f"""
                        INSERT INTO {T_CUENTA}
                        (
                            Id_Cuenta, Precio_Total, Id_Registro_Diario,
                            Id_Estado, Id_Cliente
                        )
                        VALUES
                        (
                            :id_cuenta, :total, :id_registro,
                            :id_estado, :id_cliente
                        )
                        """,
                        id_cuenta=id_cuenta,
                        total=subtotal,
                        id_registro=id_registro,
                        id_estado=id_estado,
                        id_cliente=id_cliente,
                    )

                    cursor.execute(
                        f"""
                        INSERT INTO {T_DETALLE}
                        (
                            Id_Detalle, Cantidad, Subtotal, Llevar,
                            Id_Cuenta, Id_Plato_Carta
                        )
                        VALUES
                        (
                            :id_detalle, :cantidad, :subtotal, :llevar,
                            :id_cuenta, :id_plato
                        )
                        """,
                        id_detalle=id_detalle,
                        cantidad=cantidad,
                        subtotal=subtotal,
                        llevar=llevar,
                        id_cuenta=id_cuenta,
                        id_plato=id_plato_oracle,
                    )

                conexion.commit()

            flash(f"Venta registrada. Total: S/ {subtotal:.2f}", "success")

        except (oracledb.Error, ValueError) as error:
            flash(f"No se pudo registrar la venta: {error}", "error")

        return redirect(url_for("ventas"))

    datos = {
        "clientes": [],
        "estados": [],
        "registros": [],
        "platos": [],
        "cuentas": [],
        "id_cuenta": "CUE001",
        "id_detalle": "DET001",
    }

    try:
        with conectar() as conexion:
            datos["id_cuenta"] = siguiente_codigo(
                conexion, T_CUENTA, "Id_Cuenta", "CUE"
            )
            datos["id_detalle"] = siguiente_codigo(
                conexion, T_DETALLE, "Id_Detalle", "DET"
            )

            with conexion.cursor() as cursor:
                cursor.execute(
                    f"""
                    SELECT
                        TRIM(Id_Cliente) AS Id_Cliente,
                        Nombre || ' ' || Apellido AS Cliente
                    FROM {T_CLIENTE}
                    ORDER BY Nombre, Apellido
                    """
                )
                datos["clientes"] = filas_diccionario(cursor)

                cursor.execute(
                    f"""
                    SELECT
                        TRIM(Id_Estado) AS Id_Estado,
                        Nombre || ' - ' || TRIM(Tipo_Pago) AS Descripcion
                    FROM {T_ESTADO}
                    ORDER BY Id_Estado
                    """
                )
                datos["estados"] = filas_diccionario(cursor)

                cursor.execute(
                    f"""
                    SELECT
                        TRIM(Id_Registro_Diario) AS Id_Registro_Diario,
                        TO_CHAR(Fecha, 'YYYY-MM-DD') AS Fecha
                    FROM {T_REGISTRO}
                    ORDER BY Fecha DESC
                    """
                )
                datos["registros"] = filas_diccionario(cursor)

                cursor.execute(
                    f"""
                    SELECT
                        TRIM(Id_Plato_Carta) AS Id_Plato_Carta,
                        Nombre,
                        Precio_Venta
                    FROM {T_PLATO}
                    ORDER BY Nombre
                    """
                )
                datos["platos"] = filas_diccionario(cursor)

                cursor.execute(
                    f"""
                    SELECT
                        TRIM(cu.Id_Cuenta) AS Id_Cuenta,
                        cl.Nombre || ' ' || cl.Apellido AS Cliente,
                        cu.Precio_Total,
                        es.Nombre AS Estado,
                        TO_CHAR(rd.Fecha, 'YYYY-MM-DD') AS Fecha
                    FROM {T_CUENTA} cu
                    JOIN {T_CLIENTE} cl
                      ON cu.Id_Cliente = cl.Id_Cliente
                    JOIN {T_ESTADO} es
                      ON cu.Id_Estado = es.Id_Estado
                    JOIN {T_REGISTRO} rd
                      ON cu.Id_Registro_Diario = rd.Id_Registro_Diario
                    ORDER BY rd.Fecha DESC, cu.Id_Cuenta DESC
                    """
                )
                datos["cuentas"] = filas_diccionario(cursor)

    except oracledb.Error as error:
        flash(f"Error al cargar ventas: {error}", "error")

    return render_template("ventas.html", **datos)


@app.route("/fiados")
def fiados():
    lista = []
    total = Decimal("0.00")

    try:
        with conectar() as conexion:
            with conexion.cursor() as cursor:
                cursor.execute(
                    f"""
                    SELECT
                        TRIM(cu.Id_Cuenta) AS Id_Cuenta,
                        cl.Nombre || ' ' || cl.Apellido AS Cliente,
                        cl.Especialidad,
                        cu.Precio_Total,
                        TRIM(es.Tipo_Pago) AS Tipo_Pago
                    FROM {T_CUENTA} cu
                    JOIN {T_CLIENTE} cl
                      ON cu.Id_Cliente = cl.Id_Cliente
                    JOIN {T_ESTADO} es
                      ON cu.Id_Estado = es.Id_Estado
                    WHERE TRIM(es.Nombre) = 'Pendiente'
                    ORDER BY cu.Precio_Total DESC
                    """
                )
                lista = filas_diccionario(cursor)
                total = sum(
                    (Decimal(str(fila["precio_total"])) for fila in lista),
                    Decimal("0.00"),
                )

    except oracledb.Error as error:
        flash(f"Error al cargar fiados: {error}", "error")

    return render_template("fiados.html", fiados=lista, total=total)


@app.route("/caja")
def caja():
    registros = []
    total = Decimal("0.00")

    try:
        with conectar() as conexion:
            with conexion.cursor() as cursor:
                cursor.execute(
                    f"""
                    SELECT
                        TRIM(Id_Registro_Diario) AS Id_Registro_Diario,
                        TO_CHAR(Fecha, 'YYYY-MM-DD') AS Fecha,
                        Caja_Dia
                    FROM {T_REGISTRO}
                    ORDER BY Fecha DESC
                    """
                )
                registros = filas_diccionario(cursor)
                total = sum(
                    (Decimal(str(fila["caja_dia"])) for fila in registros),
                    Decimal("0.00"),
                )

    except oracledb.Error as error:
        flash(f"Error al consultar la caja: {error}", "error")

    return render_template("caja.html", registros=registros, total=total)


@app.errorhandler(404)
def no_encontrado(_):
    return render_template("404.html"), 404


if __name__ == "__main__":
    print(f"Iniciando GUI Restaurante - versión {APP_VERSION}")
    print(f"Base Oracle: usuario={DB_USER}, DSN={DB_DSN}, esquema={DB_SCHEMA}")
    app.run(debug=True)
