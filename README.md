# docker-toba
Contenedor Docker para instalar un entorno de desarrollo Toba, listo para crear o cargar un nuevo proyecto. 
Solo necesario para crear nuevas imagenes de Toba, para instalar punutalmente [descargarlo desde el repositorio](https://repositorio.siu.edu.ar/trac/toba/wiki/Descargar) 
y seguir las [instrucciones de instalación con Docker](https://repositorio.siu.edu.ar/trac/toba/wiki/Instalacion#GuíaDockerrecomendado)

## Requerimientos
 * Se debe tener instalado [Docker](https://docs.docker.com/installation/)

## Build
Hay un archivo `toba.sh` que contiene el script de instalación de toba, ante cualquier cambio a este script (o al Dockerfile), ejecutar lo siguiente para re-generar la imagen 
```
docker build -t="siutoba/docker-toba" .
```
Una vez hecho el push a github automáticamente se va a actualizar la imagen en el índice de [hub.docker.com](hub.docker.com)

