#!/bin/bash

if [ -z "$TOBA_ID_DESARROLLADOR" ]; then
    TOBA_ID_DESARROLLADOR=0;
fi

if [ -z "$TOBA_PASS" ]; then
    echo "Warning: Se utiliza el password default de toba (OjO)";
    TOBA_PASS=toba;
fi

if [ -z "$TOBA_NOMBRE_INSTALACION" ]; then
    TOBA_NOMBRE_INSTALACION="Toba";
fi

echo "date.timezone=America/Argentina/Buenos_Aires" > php.ini;

HOME_TOBA=/var/local/toba

if [ -z "$(ls -A "$HOME_TOBA/instalacion")" ]; then
    echo -n postgres > /tmp/clave_pg;
    echo -n ${TOBA_PASS} > /tmp/clave_toba;
    ${HOME_TOBA}/bin/instalar -d ${TOBA_ID_DESARROLLADOR} -t 0 -h pg -p 5432 -u postgres -b toba -c /tmp/clave_pg -k /tmp/clave_toba -n ${TOBA_NOMBRE_INSTALACION};
	chown -R www-data ${HOME_TOBA}/instalacion/i__desarrollo;
fi

ln -s ${HOME_TOBA}/instalacion/toba.conf /etc/apache2/sites-enabled/toba.conf;

