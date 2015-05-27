FROM siutoba/docker-web:latest
MAINTAINER smarconi@siu.edu.ar

COPY toba_editor.sh /entrypoint.d/

ENV JASPER_HOST jasper
ENV JASPER_PORT 8081

#En lugar de utilizar http://localhost:puerto usa http://ip_interna, para poder hacer comunicaciones internas server-to-server
#RUN echo "UseCanonicalName On" >> /etc/apache2/apache2.conf

RUN chmod +x /entrypoint.d/*.sh

