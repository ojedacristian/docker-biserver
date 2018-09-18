# Pentaho BI Server en Docker

Imagen de Docker para Pentaho BI Server.

## Construcción de la imagen

La construcción de esta imagen sigue el procedimiento estándar de Docker con el comando `docker build`, no obstante, para facilitar el proceso se
dispone de un [Makefile](https://en.wikipedia.org/wiki/Makefile) con las siguientes tareas:

 * **`make build-image`**: construye la imagen.
 * **`make save-image`**: exporta en el directorio `./dist/` un tarball de la imagen.
 * **`make save-standalone`**: exporta en el directorio `./dist/` un tarball de la instalación con una estructura similar a la que podemos encontrar
   en los ZIP de Pentaho BI Server en Sourceforge.
 * **`make build`**: ejecuta las tareas `build-image`, `save-image` y `save-standalone`.

## Argumentos del Dockerfile

 * **`TOMCAT_MAJOR_VERSION` (`8` por defecto)**: versión mayor de Tomcat.
 * **`TOMCAT_MINOR_VERSION` (`5` por defecto)**: versión menor de Tomcat.
 * **`TOMCAT_PATCH_VERSION` (`latest` por defecto)**: versión parche de Tomcat.
 * **`BISERVER_VERSION` (`7.1.0.0-12` por defecto)**: versión de Pentaho BI Server.
 * **`BISERVER_MAVEN_REPO` (`https://nexus.pentaho.org/content/groups/omni/` por defecto)**: repositorio de Maven del que se descargan las
   dependencias necesarias para la instalación de Pentaho BI Server.
 * **`KETTLE_DIRNAME` (`kettle` por defecto)**: nombre que tendrá el directorio `./kettle/`.
 * **`SOLUTIONS_DIRNAME` (`pentaho-solutions` por defecto)**: nombre que tendrá el directorio `./pentaho-solutions/`.
 * **`DATA_DIRNAME` (`data` por defecto)**: nombre que tendrá el directorio `./data/`.
 * **`WEBAPP_PENTAHO_DIRNAME` (`pentaho` por defecto)**: nombre que tendrá el directorio `./tomcat/webapps/pentaho/`.
 * **`WEBAPP_PENTAHO_STYLE_DIRNAME` (`pentaho-style` por defecto)**: nombre que tendrá el directorio `./tomcat/webapps/pentaho-style/`

## Variables de entorno

 * **`KETTLE_DIRNAME` (por defecto el mismo valor que el argumento)**: si el valor es distinto al argumento, el directorio será renombrado.
 * **`SOLUTIONS_DIRNAME` (por defecto el mismo valor que el argumento)**: si el valor es distinto al argumento, el directorio será renombrado.
 * **`DATA_DIRNAME` (por defecto el mismo valor que el argumento)**: si el valor es distinto al argumento, el directorio será renombrado.
 * **`WEBAPP_PENTAHO_DIRNAME` (por defecto el mismo valor que el argumento)**: si el valor es distinto al argumento, el directorio será renombrado.
 * **`WEBAPP_PENTAHO_STYLE_DIRNAME` (por defecto el mismo valor que el argumento)**: si el valor es distinto al argumento, el directorio será
   renombrado.
 * **`FQSU_PROTOCOL` (`http` por defecto)**: protocolo del Fully Qualified Server URL.
 * **`FQSU_DOMAIN` (`localhost` por defecto)**: dominio del Fully Qualified Server URL.
 * **`FQSU_PORT` (`8080` por defecto)**: puerto del Fully Qualified Server URL.
 * **`HSQLDB_PORT` (`9001` por defecto)**: puerto de HSQLDB.
 * **`STORAGE_TYPE` (`local` por defecto)**: tipo de almacenamiento, admite los valores `local` o `postgres`.
 * **`POSTGRES_HOST`**: host para la conexión con la BBDD.
 * **`POSTGRES_PORT`**: puerto para la conexión con la BBDD.
 * **`POSTGRES_USER`**: usuario para la conexión con la BBDD.
 * **`POSTGRES_PASSWORD`**: contraseña para la conexión con la BBDD.
 * **`POSTGRES_DATABASE`**: nombre de la BBDD inicial (no se realizará ninguna operación sobre ella).
 * **`POSTGRES_JACKRABBIT_USER` (`jcr_user` por defecto)**: nombre del usuario de Jackrabbit.
 * **`POSTGRES_JACKRABBIT_PASSWORD` (`${POSTGRES_PASSWORD}` por defecto)**: contraseña del usuario de Jackrabbit.
 * **`POSTGRES_JACKRABBIT_DATABASE` (`jackrabbit` por defecto)**: nombre de la BBDD de Jackrabbit (se creará si no existe).
 * **`POSTGRES_HIBERNATE_USER` (`hibuser` por defecto)**: nombre del usuario de Hibernate.
 * **`POSTGRES_HIBERNATE_PASSWORD` (`${POSTGRES_PASSWORD}` por defecto)**: contraseña del usuario de Hibernate.
 * **`POSTGRES_HIBERNATE_DATABASE` (`hibernate` por defecto)**: nombre de la BBDD de Hibernate (se creará si no existe).
 * **`POSTGRES_QUARTZ_USER` (`pentaho_user` por defecto)**: nombre del usuario de Quartz.
 * **`POSTGRES_QUARTZ_PASSWORD` (`${POSTGRES_PASSWORD}` por defecto)**: contraseña del usuario de Quartz.
 * **`POSTGRES_QUARTZ_DATABASE` (`quartz` por defecto)**: nombre de la BBDD de Quartz (se creará si no existe).

## JSON de configuración (múltiples Pentaho BI Server en el mismo Tomcat)

Por defecto esta imagen despliega únicamente un Pentaho BI Server en el mismo Tomcat. Si se desea una configuración más compleja, es posible definir
la variable de entorno `SETUP_JSON` con un valor que presente la siguiente estructura:

```json
{
  "root": "pentaho", // El usuario será redireccionado a esta instancia si accede desde la raíz.
  "servers": [ // Definición de cada instancia.
    {
      "name": "pentaho", // Nombre de la instancia.
      "enabled": true, // Si el valor es "false", la instancia no será configurada.
      "env": { // Variables de entorno para configurar la instancia.
          "STORAGE_TYPE": "postgres",
          "POSTGRES_HOST": "postgres.local",
          "POSTGRES_USER": "postgres",
          "POSTGRES_PASSWORD": "1234",
          "POSTGRES_DATABASE": "postgres",
          // ...
      }
    },
    {
      "name": "lincebi",
      "enabled": false,
      "env": {}
    },
    // ...
  ]
}
```

## Instalación de plugins y ejecución de scripts personalizados

Es posible instalar plugins o ejecutar scripts personalizados antes de iniciar Tomcat por primera vez. Los archivos contenidos en el directorio
`./config/biserver.init.d/` son tratados de diferentes maneras según su extensión.

 * **`*.sh` y `*.run`:** son ejecutados desde el directorio de trabajo `${BISERVER_HOME}`. Tendrán disponibles todas las variables de entorno
   anteriormente documentadas.
 * **`*.tar`, `*.tar.gz`, `*.tar.bz2`, `*.tar.xz`, `*.zip`, `*.kar`**:
   * **`*.__webapp__.*`**: son extraídos en `"${CATALINA_BASE}/webapps/${WEBAPP_PENTAHO_DIRNAME}`.
   * **`*.__style_webapp__.*`**: son extraídos en `${CATALINA_BASE}/webapps/${WEBAPP_PENTAHO_STYLE_DIRNAME}`.
   * **`*.__solutions__.*`**: son extraídos en `"${BISERVER_HOME}/${SOLUTIONS_DIRNAME}`.
   * **`*.__data__.*`**: son extraídos en `${BISERVER_HOME}/${DATA_DIRNAME}`.
   * **Todos los demás**: son considerados plugins estándar de Pentaho y son extraídos en `"${BISERVER_HOME}/${SOLUTIONS_DIRNAME}/system/`.

Los archivos posicionados directamente en `./config/biserver.init.d/` son aplicados a todas las instancias de Pentaho BI Server, es posible aplicar un
archivo a una sola instancia creando un subdirectorio con el nombre de esta y colocando en él los archivos.

Para añadir estos archivos a una imagen ya construida, se debe montar en el contenedor el directorio `/etc/biserver.init.d/`.

```sh
docker run \
  # ...
  --mount type=bind,src='/ruta/a/mis/plugins/',dst='/etc/biserver.init.d/',ro \
  # ...
```

## Ejemplos de despliegue

El ejemplo más simple es el despliegue de un contenedor con almacenamiento local.

```sh
docker run --detach \
  --name pentaho-biserver \
  --publish '8080:8080/tcp' \
  --publish '8009:8009/tcp' \
  --mount type=volume,src=pentaho-biserver-jackrabbit,dst=/var/lib/biserver/pentaho-solutions/system/jackrabbit/repository/ \
  --mount type=volume,src=pentaho-biserver-hsqldb,dst=/var/lib/biserver/data/hsqldb/ \
  --mount type=volume,src=pentaho-biserver-logs,dst=/var/lib/biserver/tomcat/logs/ \
  stratebi/pentaho-biserver:latest
```

Para despliegues más complejos, en el directorio `./examples/` se encuentran varios scripts en shell con otros casos comunes.
