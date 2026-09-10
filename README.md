# Sistema del Restaurante — Flask + Oracle

Versión corregida para tablas del esquema `SYSTEM` y servicio Oracle `XE`.

## Pasos

1. Ejecuta `BaseDatos_SYSTEM.sql` en Oracle SQL Developer conectado como `SYSTEM`.
2. Abre `.env` y reemplaza `COLOCA_AQUI_TU_CONTRASENA` por tu contraseña de Oracle.
3. Ejecuta `INICIAR_GUI.bat`, o desde una terminal:

```bash
python -m pip install -r requirements.txt
python app.py
```

4. Abre `http://127.0.0.1:5000`.

## Corrección del registro de ventas

Los identificadores Oracle definidos como `CHAR(10)` pueden llegar con espacios de relleno. Esta versión normaliza el código seleccionado y compara los códigos recuperados desde Oracle antes de insertar la cuenta y el detalle. Además, reutiliza el identificador original devuelto por Oracle para respetar la clave foránea.

Al iniciar debe verse en la terminal:

```text
Iniciando GUI Restaurante - versión 2026.07-VENTAS-CORREGIDAS
```

Esto confirma que se está ejecutando el archivo corregido.
