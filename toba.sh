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
if [ -z "$TOBA_INSTALACION_DIR" ]; then
    export TOBA_INSTALACION_DIR=/var/local/docker-data/toba
fi
if [ -z "$TOBA_ES_PRODUCCION" ]; then
    export TOBA_ES_PRODUCCION=0
fi
if [ -z "$TOBA_INSTANCIA" ]; then
    if [ "$TOBA_ES_PRODUCCION" == "0" ]; then
        export TOBA_INSTANCIA=desarrollo
    else
        export TOBA_INSTANCIA=produccion
    fi
fi
if [ -z "$TOBA_USUARIO_ADMIN" ]; then
    export TOBA_USUARIO_ADMIN=toba
fi
if [ -z "$TOBA_INSTALAR_EDITOR" ]; then
    export TOBA_INSTALAR_EDITOR=True
fi
if [ -z "$TOBA_INSTALAR_REFERENCIA" ]; then
    export TOBA_INSTALAR_REFERENCIA=True
fi
if [ -z "$TOBA_INSTALAR_USUARIOS" ]; then
    export TOBA_INSTALAR_USUARIOS=True
fi
if [ -z "$TOBA_BASE_HOST" ]; then
    export TOBA_BASE_HOST=pg
fi
if [ -z "$TOBA_BASE_USER" ]; then
    export TOBA_BASE_USER=postgres
fi
if [ -z "$TOBA_BASE_PASS" ]; then
    export TOBA_BASE_PASS=postgres
fi
if [ -z "$TOBA_BASE_PORT" ]; then
    export TOBA_BASE_PORT=5432
fi


## Si no existe la carpeta INSTALACION, asume que hay que instalarlo
if [ -z "$(ls -A "$TOBA_INSTALACION_DIR")" ]; then

	if [ -z "$DOCKER_WAIT_FOR" ]; then
		echo "Esperando 8 segundos para que levante postgres..."
		for i in 8 7 6 5 4 3 2 1
		do
			echo "Intentando en $i.."
			sleep 1
		done
	fi

    echo -n ${TOBA_BASE_PASS} > /tmp/clave_pg;
    echo -n ${TOBA_PASS} > /tmp/clave_toba;

    find /var/local -maxdepth 3 -name composer.json -execdir composer install --no-interaction \;

    ${TOBA_DIR}/bin/toba instalacion_silenciosa instalar \
        -d ${TOBA_ID_DESARROLLADOR} \
        -t ${TOBA_ES_PRODUCCION} \
        -h ${TOBA_BASE_HOST} \
        -p ${TOBA_BASE_PORT} \
        -u ${TOBA_BASE_USER} \
        -b ${TOBA_BASE_NOMBRE} \
        -c /tmp/clave_pg \
        -k /tmp/clave_toba \
        -n ${TOBA_NOMBRE_INSTALACION} \
        --no-interactive \
        --usuario-admin ${TOBA_USUARIO_ADMIN}

    #Instala toba_editor, toba_referencia y toba_usuarios
    if [ "$TOBA_INSTALAR_EDITOR" = True ]; then
        ${TOBA_DIR}/bin/toba proyecto cargar -p toba_editor -a 1
    fi
    if [ "$TOBA_INSTALAR_USUARIOS" = True ]; then
        ${TOBA_DIR}/bin/toba proyecto cargar -p toba_usuarios -a 1
    fi
    if [ "$TOBA_INSTALAR_REFERENCIA" = True ]; then
        ${TOBA_DIR}/bin/toba proyecto cargar -p toba_referencia -a 1
        ${TOBA_DIR}/bin/toba proyecto instalar -p toba_referencia
    fi

    ## Si se define un TOBA_PROYECTO puntual, se carga
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

        #Si existe ARAI-Registry se registra
        if [ -f "$TOBA_PROYECTO_DIR/arai.json" ] &&  [ -n "$ARAI_REGISTRY_URL" ]; then
            echo "Conectando con ARAI-Registry..."
            $TOBA_PROYECTO_DIR/vendor/bin/arai-cli registry:add \
                --maintainer-email  $ARAI_REGISTRY_MAINTAINER_EMAIL \
                --maintainer $ARAI_REGISTRY_MAINTAINER_NAME \
                $ARAI_REGISTRY_URL
        fi
    fi


fi

#Permite a Toba guardar los logs
chown -R www-data ${TOBA_INSTALACION_DIR}/i__${TOBA_INSTANCIA}

#Permite al usuario HOST editar los archivos
chmod -R a+w ${TOBA_INSTALACION_DIR}

#Publica el alias de toba
ln -s ${TOBA_INSTALACION_DIR}/toba.conf /etc/apache2/sites-enabled/toba.conf;

#Cada vez que se loguea por bash al container, carga las variables de entorno toba
SCRIPT_ENTORNO_TOBA=${TOBA_INSTALACION_DIR}/entorno_toba.env
echo ". ${SCRIPT_ENTORNO_TOBA}" >> /root/.bashrc
if [ -z "$TOBA_PROYECTO_DIR" ]; then
    echo "cd ${TOBA_DIR};" >> /root/.bashrc
else
    echo "cd ${TOBA_PROYECTO_DIR};" >> /root/.bashrc
fi

#Se deja el ID del container dentro de la configuracion de toba, para luego poder usarlo desde el Host
echo "TOBA_DOCKER_ID=$HOSTNAME" > ${TOBA_INSTALACION_DIR}/toba_docker.env



