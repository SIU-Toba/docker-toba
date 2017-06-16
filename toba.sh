#!/bin/bash
fix_cert_permission()
{
	if [ -f "$1" ]; then
	    echo "Executing chown www-data $1"
		chown www-data $1
		echo "Executing chmod o+x $1"
		chmod o+x $1 # se agrega permisos de ejecución para others por curl
	fi
}

fix_permissions_certs()
{
	fix_cert_permission ${DOCKER_CERT_FILE}
	fix_cert_permission ${DOCKER_KEY_FILE}
	fix_cert_permission ${DOCKER_CHAIN_FILE}
	fix_cert_permission ${TOBA_CERT_API_CLIENTE}
	fix_cert_permission ${TOBA_CERT_API_CLIENTE_KEY}
	fix_cert_permission ${TOBA_CA_CERT_VERIFY}
}

if [ -z "$DIR_RAIZ_CA" ]; then
    DIR_RAIZ_CA="/CAs"
fi
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
    export TOBA_INSTALAR_EDITOR=true
fi
if [ -z "$TOBA_INSTALAR_REFERENCIA" ]; then
    export TOBA_INSTALAR_REFERENCIA=true
fi
if [ -z "$TOBA_INSTALAR_USUARIOS" ]; then
    export TOBA_INSTALAR_USUARIOS=true
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
if [ -z "$TOBA_PROYECTO_CHEQUEA_SVN_SINCRO" ]; then
    export TOBA_PROYECTO_CHEQUEA_SVN_SINCRO=False
fi

## Si no existe la carpeta INSTALACION, asume que hay que instalarlo
if [ -z "$(ls -A "$TOBA_INSTALACION_DIR")" ]; then

	if [ -z "$DOCKER_WAIT_FOR" ]; then
                #Ahora chequeo que se pueda hacer una conexion (pg_isready similar)
                ${TOBA_DIR}/bin/connection_test $TOBA_BASE_HOST $TOBA_BASE_PORT $TOBA_BASE_USER TOBA_BASE_PASS postgres;		
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
    if [ "$TOBA_INSTALAR_EDITOR" = true -o "$TOBA_INSTALAR_EDITOR" = TRUE ]; then
        ${TOBA_DIR}/bin/toba proyecto cargar -p toba_editor -a 1
    fi
    if [ "$TOBA_INSTALAR_USUARIOS" = true -o "$TOBA_INSTALAR_USUARIOS" = TRUE ]; then
        ${TOBA_DIR}/bin/toba proyecto cargar -p toba_usuarios -a 1
    fi
    if [ "$TOBA_INSTALAR_REFERENCIA" = true -o "$TOBA_INSTALAR_REFERENCIA" = TRUE ]; then
        ${TOBA_DIR}/bin/toba proyecto cargar -p toba_referencia -a 1
        ${TOBA_DIR}/bin/toba proyecto instalar -p toba_referencia
    fi
fi

## Si se define un TOBA_PROYECTO puntual y no esta cargado, se carga
if [ -n "$TOBA_PROYECTO" ] && ! egrep -xq "^proyectos = \"[[:alpha:]*[:blank:]*,_]*$TOBA_PROYECTO[[:alpha:]*[:blank:]*,_]*\"$" ${TOBA_INSTALACION_DIR}/i__${TOBA_INSTANCIA}/instancia.ini ; then
    if [ -z "$TOBA_PROYECTO_DIR" ]; then
        echo "Notice: Se utiliza la carpeta de proyecto por default (toba/proyectos)";
        export TOBA_PROYECTO_DIR=${TOBA_DIR}/proyectos/${TOBA_PROYECTO}
    fi
    CARGAR_ALIAS=""
    CARGAR_FULL_URL=""
    if [ -n "$TOBA_PROYECTO_ALIAS" ]; then
        CARGAR_ALIAS="--alias-nombre $TOBA_PROYECTO_ALIAS"
    fi
    CARGAR_PORT=""
    if [ -n "$DOCKER_WEB_PORT" ]; then
        CARGAR_PORT=":$DOCKER_WEB_PORT"
    fi
    if [ -n "$DOCKER_CONTAINER_URL_BASE" ]; then
        CARGAR_FULL_URL="--full-url ${DOCKER_CONTAINER_URL_BASE}${CARGAR_PORT}${TOBA_PROYECTO_ALIAS}"
    fi

    ${TOBA_DIR}/bin/toba proyecto cargar -p $TOBA_PROYECTO -a 1 -d $TOBA_PROYECTO_DIR  $CARGAR_ALIAS $CARGAR_FULL_URL

    # Si se define TOBA_PROYECTO_INSTALAR, se instala
    if [ "$TOBA_PROYECTO_INSTALAR" = true -o  "$TOBA_PROYECTO_INSTALAR" = TRUE ]; then
        if [ -z "$TOBA_PROYECTO_INSTALAR_PARAMETROS" ]; then
            TOBA_PROYECTO_INSTALAR_PARAMETROS=""
        fi
        ${TOBA_DIR}/bin/toba proyecto instalar -p $TOBA_PROYECTO $TOBA_PROYECTO_INSTALAR_PARAMETROS
        if [ "$TOBA_PROYECTO_CHEQUEA_SVN_SINCRO" = true -o "$TOBA_PROYECTO_CHEQUEA_SVN_SINCRO" = TRUE ]; then
            echo 'chequea_sincro_svn = 1' >> ${TOBA_INSTALACION_DIR}/instalacion.ini
        fi
    fi

    if [ -n "$TOBA_CERT_API_CLIENTE" ] && [ -f "$TOBA_CERT_API_CLIENTE" ] && [ -n "$TOBA_CERT_API_CLIENTE_KEY" ] && [ -f "$TOBA_CERT_API_CLIENTE_KEY" ] && [ -n "$TOBA_CA_CERT_VERIFY" ] && [ -f "$TOBA_CA_CERT_VERIFY" ] ; then
        echo "Configurando certificado SSL cliente..."
        ${TOBA_DIR}/bin/toba servicios_web cli_configurar -p ${TOBA_PROYECTO} --tipo_ws rest --cert_cli ${TOBA_CERT_API_CLIENTE} --key_cli ${TOBA_CERT_API_CLIENTE_KEY} -c ${TOBA_CA_CERT_VERIFY} --all 1
        
        if [ "$TOBA_INSTALAR_USUARIOS" = true -o "$TOBA_INSTALAR_USUARIOS" = TRUE ]; then
            ## Agrego el archivo cliente.ini en el proyecto toba_usuarios
            echo "Configurando certificado SSL cliente en Toba-Usuarios..."
            ${TOBA_DIR}/bin/toba servicios_web cli_configurar -p toba_usuarios --tipo_ws rest --cert_cli ${TOBA_CERT_API_CLIENTE} --key_cli ${TOBA_CERT_API_CLIENTE_KEY} -c ${TOBA_CA_CERT_VERIFY} --all 1
        fi
    fi

    if [ -n "$TOBA_API_ENCODING" ]; then
        echo "Configurando API Server..."
        ${TOBA_DIR}/bin/toba servicios_web serv_configurar -p ${TOBA_PROYECTO} --tipo_ws rest --c ${TOBA_CERT_API_CLIENTE} --auth_tipo ssl --encoding ${TOBA_API_ENCODING}    
    fi

    #Si existe ARAI-Registry se registra
    if [ -f "$TOBA_PROYECTO_DIR/arai.json" ] &&  [ -n "$ARAI_REGISTRY_URL" ]; then
        echo "Conectando con ARAI-Registry..."

        $TOBA_PROYECTO_DIR/bin/arai-cli registry:add \
            --maintainer-email  $ARAI_REGISTRY_MAINTAINER_EMAIL \
            --maintainer $ARAI_REGISTRY_MAINTAINER_NAME \
            $ARAI_REGISTRY_URL
    fi
    
    # Permisos de lectura y ejecucion para que Apache pueda ejecutar el codigo del proyecto
    chmod o+rx -R $TOBA_PROYECTO_DIR
    
    # Si existe la carpeta php del proyecto, le damos permiso de escritura a apache para escribir con toba-editor
    if [ -d $TOBA_PROYECTO_DIR/php ]; then
        chmod o+w -R $TOBA_PROYECTO_DIR/php
    fi

    #Si existe la carpeta temporal del proyecto, le damos permisos a apache
    if [ -d $TOBA_PROYECTO_DIR/temp ]; then
        chown -R www-data $TOBA_PROYECTO_DIR/temp
    fi

    if [ -d $TOBA_PROYECTO_DIR/www/temp ]; then
        chown -R www-data $TOBA_PROYECTO_DIR/www/temp
    fi
fi

#Permite a Toba guardar los logs
chown -R www-data ${TOBA_INSTALACION_DIR}/i__${TOBA_INSTANCIA}

#Permite al usuario HOST editar los archivos
chmod -R a+w ${TOBA_INSTALACION_DIR}

#Publica el alias de toba
ln -s ${TOBA_INSTALACION_DIR}/toba.conf /etc/apache2/sites-enabled/toba.conf;

#Cada vez que se loguea por bash al container, carga las variables de entorno toba
if ! grep -q 'entorno_toba' /root/.bashrc; then
    SCRIPT_ENTORNO_TOBA=${TOBA_INSTALACION_DIR}/entorno_toba.env
    echo ". ${SCRIPT_ENTORNO_TOBA}" >> /root/.bashrc
    if [ -z "$TOBA_PROYECTO_DIR" ]; then
        echo "cd ${TOBA_DIR};" >> /root/.bashrc
    else
        echo "cd ${TOBA_PROYECTO_DIR};" >> /root/.bashrc
    fi
fi

#Permite que PHP pueda leer los certificados
#chown -R www-data $DIR_RAIZ_CA
fix_permissions_certs

#Agrega el certificado de la CA al keystore del SO
if [ -n "$TOBA_CA_CERT_VERIFY" ] && [ -f "$TOBA_CA_CERT_VERIFY" ]; then
        #Recupero el nombre del archivo, le saco el .pem si lo tiene.. unicamente sirven .crt
        NOMBRE_ARCHIVO=`basename ${TOBA_CA_CERT_VERIFY} '.cert.pem' `
        if [ ! -f /usr/local/share/ca-certificates/${NOMBRE_ARCHIVO}.crt ]; then
            echo "Copiando archivo de certificado.."
            cp ${TOBA_CA_CERT_VERIFY} /usr/local/share/ca-certificates/${NOMBRE_ARCHIVO}.crt
        fi
        grep -Fxq "${NOMBRE_ARCHIVO}.crt" /etc/ca-certificates.conf
        if [ $? != 0 ]; then
            echo "Configurando certificados raiz.."
            printf "%s\n" "${NOMBRE_ARCHIVO}.crt" >> /etc/ca-certificates.conf
            update-ca-certificates --fresh
        fi
fi



#Se deja el ID del container dentro de la configuracion de toba, para luego poder usarlo desde el Host
echo "TOBA_DOCKER_ID=$HOSTNAME" > ${TOBA_INSTALACION_DIR}/toba_docker.env



