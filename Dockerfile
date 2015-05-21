FROM siutoba/docker-web:v1.1
MAINTAINER smarconi@siu.edu.ar

COPY toba_editor.sh /entrypoint.d/

ENV JASPER_HOST jasper
ENV JASPER_PORT 8081

RUN chmod +x /entrypoint.d/*.sh

