# Build su-exec without leaving compiler tools in the final image
FROM debian:bookworm-slim AS su-exec-builder
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential wget ca-certificates && \
    wget -O /tmp/su-exec.tar.gz https://github.com/ncopa/su-exec/archive/v0.2.tar.gz && \
    cd /tmp && tar -xf su-exec.tar.gz && \
    cd su-exec-0.2 && make && \
    rm -rf /var/lib/apt/lists/*

FROM eclipse-temurin:21-jre-jammy

# Install runtime dependencies; download and initialise JDownloader
RUN apt-get update && \
    apt-get install -y --no-install-recommends tini ffmpeg wget jq && \
    mkdir -p /opt/JDownloader/libs && \
    wget -O /opt/JDownloader/JDownloader.jar \
        --user-agent="https://github.com/KrX3D/headless-jd2-docker" \
        http://installer.jdownloader.org/JDownloader.jar && \
    java -Djava.awt.headless=true -jar /opt/JDownloader/JDownloader.jar && \
    mkdir -p /tmp/ && chmod 1777 /tmp && \
    apt-get remove -y wget && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

COPY --from=su-exec-builder /tmp/su-exec-0.2/su-exec /usr/bin/su-exec

# Sevenzipbindings and entrypoint
COPY common/* /opt/JDownloader/
RUN chmod +x /opt/JDownloader/entrypoint.sh

VOLUME /opt/JDownloader/cfg
VOLUME /opt/JDownloader/Downloads

ENTRYPOINT ["tini", "-g", "--", "/opt/JDownloader/entrypoint.sh"]
CMD ["java", "-Djava.awt.headless=true", "-jar", "/opt/JDownloader/JDownloader.jar"]
