#!/bin/bash

if [ -z "$TOBA_ID_DESARROLLADOR" ]; then
    echo "Notice: Se utiliza el id_desarrollador default (0)";
    TOBA_ID_DESARROLLADOR=0;
fi
if [ -z "$TOBA_PASS" ]; then
    echo "Warning: Se utiliza el password default (toba)";
    TOBA_PASS=toba;
fi
if [ -z "$TOBA_NOMBRE_INSTALACION" ]; then
	echo "Notice: Se utiliza el nombre de instalacion por default (Toba Editor)";	
    TOBA_NOMBRE_INSTALACION="Toba Editor";
fi
if [ -z "$TOBA_DIR" ]; then
    export TOBA_DIR=/var/local/toba
fi
if [ -z "$TOBA_BASE_NOMBRE" ]; then
    export TOBA_BASE_NOMBRE=toba
fi
if [ -z "$TOBA_BASE_NOMBRE" ]; then
    export TOBA_BASE_NOMBRE=toba
fi
if [ -z "$TOBA_INSTALACION_DIR" ]; then
    export TOBA_INSTALACION_DIR=${TOBA_DIR}/docker-data/instalacion
fi
if [ -z "$TOBA_INSTANCIA" ]; then
    export TOBA_INSTANCIA=desarrollo
fi

## Si no existe la carpeta INSTALACION, asume que hay que instalarlo
if [ -z "$(ls -A "$TOBA_INSTALACION_DIR")" ]; then

	if [ -z "$DOCKER_WAIT_FOR" ]; then
		echo "Esperando 5 segundos para que levante postgres..."
		for i in 5 4 3 2 1
		do
			echo "Intentando en $i.."
			sleep 1
		done
	fi

    echo -n postgres > /tmp/clave_pg;
    echo -n ${TOBA_PASS} > /tmp/clave_toba;

    find /var/local -maxdepth 3 -name composer.json -execdir composer install --no-interaction \;

    ${TOBA_DIR}/bin/instalar -d ${TOBA_ID_DESARROLLADOR} -t 0 -h pg -p 5432 -u postgres -b $TOBA_BASE_NOMBRE -c /tmp/clave_pg -k /tmp/clave_toba -n ${TOBA_NOMBRE_INSTALACION} --no-interactive

    ## Si se define el TOBA_PROYECTO, se carga
    if [ -n "$TOBA_PROYECTO" ]; then
        if [ -z "$TOBA_PROYECTO_DIR" ]; then
            echo "Notice: Se utiliza la carpeta de proyecto por default (toba/proyectos)";
            export TOBA_PROYECTO_DIR=${TOBA_DIR}/proyectos/${TOBA_PROYECTO}
        fi
        CARGAR_ALIAS=""
        if [ -n "$TOBA_PROYECTO_ALIAS" ]; then
            CARGAR_ALIAS="--alias-nombre $TOBA_PROYECTO_ALIAS"
        fi

        ${TOBA_DIR}/bin/toba proyecto cargar -p $TOBA_PROYECTO -a 1 -d $TOBA_PROYECTO_DIR  $CARGAR_ALIAS

        # Si se define TOBA_PROYECTO_INSTALAR, se instala
        if [ "$TOBA_PROYECTO_INSTALAR" = True ]; then
            if [ -z "$TOBA_PROYECTO_INSTALAR_PARAMETROS" ]; then
                TOBA_PROYECTO_INSTALAR_PARAMETROS=""
            fi
            ${TOBA_DIR}/bin/toba proyecto instalar -p $TOBA_PROYECTO $TOBA_PROYECTO_INSTALAR_PARAMETROS
        fi
    fi

    #Permite a Toba guardar los logs
	chown -R www-data ${TOBA_INSTALACION_DIR}/i__${TOBA_INSTANCIA}

    #Permite al usuario HOST editar los archivos
	chmod -R a+w ${TOBA_INSTALACION_DIR}

fi

ln -s ${TOBA_INSTALACION_DIR}/toba.conf /etc/apache2/sites-enabled/toba.conf;

#Se deja el ID del container dentro de la configuraci�n de toba, para luego poder usarlo desde el Host
echo "TOBA_DOCKER_ID=$HOSTNAME" > ${TOBA_INSTALACION_DIR}/toba_docker.env

#Cada vez que se loguea por bash al container, carga las variables de entorno toba
SCRIPT_ENTORNO_TOBA=`find ${TOBA_DIR}/bin/entorno_toba_*.sh`
echo ". ${SCRIPT_ENTORNO_TOBA}" >> /root/.bashrc
echo "cd ${TOBA_INSTALACION_DIR}/../../;" >> /root/.bashrc

