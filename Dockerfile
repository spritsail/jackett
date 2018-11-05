FROM spritsail/mono:4.5

ARG JACKETT_VER=0.10.420

ENV SUID=912 SGID=912 \
    XDG_CONFIG_HOME=/config

LABEL maintainer="Spritsail <jackett@spritsail.io>" \
      org.label-schema.vendor="Spritsail" \
      org.label-schema.name="Jackett" \
      org.label-schema.url="https://github.com/Jackett/Jackett" \
      org.label-schema.description="Adds Torznab support for many torrent indexers" \
      org.label-schema.version=${JACKETT_VER} \
      io.spritsail.version.jackett=${JACKETT_VER}

WORKDIR /jackett

COPY entrypoint.sh /usr/bin/entrypoint

RUN apk add --no-cache libcurl mono-reference-assemblies-facades ca-certificates-mono \
 && wget -O- https://github.com/Jackett/Jackett/releases/download/v${JACKETT_VER}/Jackett.Binaries.Mono.tar.gz | \
      tar xz --strip-components=1 \
 # Take the single DLL requirement out of facades to save space
 && mv /usr/lib/mono/4.5/Facades/System.Runtime.InteropServices.RuntimeInformation.dll . \
 && apk del --no-cache mono-reference-assemblies-facades \
 # Shed some useless fluff
 && rm -f *.pdb install_service_macos JackettUpdater.exe Upstart.config \
 # Fix weird perms on the extracted files
 && chown -R ${SUID}:${SGID} /jackett \
 # Silence error: https://github.com/Jackett/Jackett/blob/master/src/Jackett.Server/Services/ServerService.cs#L157
 && touch /usr/lib/mono/4.5/mono-api-info.exe \
 && chmod +x /usr/bin/entrypoint

VOLUME ["/config"]

EXPOSE 9117

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/entrypoint"]
CMD ["mono", "/jackett/JackettConsole.exe", "-x", "-d", "/config", "--NoUpdates"]
