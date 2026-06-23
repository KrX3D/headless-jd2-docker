FROM eclipse-temurin:21-jre-alpine

# Create directory, and start JD2 for the initial update and creation of config files.
RUN apk update && apk upgrade && \
    apk add --no-cache tini su-exec shadow ffmpeg jq wget && \
    mkdir -p /opt/JDownloader/libs && \
    wget -O /opt/JDownloader/JDownloader.jar \
        --user-agent="https://github.com/KrX3D/headless-jd2-docker" \
        http://installer.jdownloader.org/JDownloader.jar && \
    java -Djava.awt.headless=true -jar /opt/JDownloader/JDownloader.jar && \
    mkdir -p /tmp/ && chmod 1777 /tmp

# Sevenzipbindings and entrypoint
COPY common/* /opt/JDownloader/
RUN chmod +x /opt/JDownloader/entrypoint.sh

VOLUME /opt/JDownloader/cfg
VOLUME /opt/JDownloader/Downloads

ENTRYPOINT ["tini", "-g", "--", "/opt/JDownloader/entrypoint.sh"]
CMD ["java", "-Djava.awt.headless=true", "-jar", "/opt/JDownloader/JDownloader.jar"]
