GUI FINAL DEL RESTAURANTE - BASE SYSTEM
=======================================

Esta versión utiliza la nueva base de datos creada dentro del usuario SYSTEM.
El archivo incluido con la estructura completa es:

    BaseDatos_SYSTEM.sql

CONFIGURACIÓN
-------------

1. Abre el archivo .env.
2. Cambia únicamente la contraseña:

   DB_PASSWORD=TU_CONTRASEÑA_REAL

3. La conexión está configurada así:

   DB_USER=SYSTEM
   DB_DSN=localhost:1521/XE
   DB_SCHEMA=SYSTEM

4. Instala las dependencias:

   python -m pip install -r requirements.txt

5. Ejecuta la aplicación:

   python app.py

6. Abre en el navegador:

   http://127.0.0.1:5000

7. Para comprobar la conexión y las tablas:

   http://127.0.0.1:5000/diagnostico

IMPORTANTE
----------

No fue necesario modificar los módulos de la GUI porque el nuevo script conserva
los mismos nombres de tablas, columnas, funciones y procedimientos que la base
anterior. El cambio principal es que ahora los objetos pertenecen al esquema SYSTEM.

Si modificas el archivo .env, detén Flask con Ctrl+C y vuelve a ejecutar python app.py.
