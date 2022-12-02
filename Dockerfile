ARG JACKETT_VER=0.20.2313

FROM mcr.microsoft.com/dotnet/sdk:6.0-alpine AS dotnet

ARG JACKETT_VER

WORKDIR /tmp
RUN wget -O- https://github.com/Jackett/Jackett/archive/v${JACKETT_VER}.tar.gz \
        | tar xz --strip-components=1 \
 && cd src \
    # Prevents the following crash on startup:
    #   Process terminated. Couldn't find a valid ICU package installed on the
    #   system. Set the configuration flag System.Globalization.Invariant to
    #   true if you want to run with no globalization support.
 && echo '{"configProperties":{"System.Globalization.Invariant":true,"System.Globalization.PredefinedCulturesOnly":false}}' > Jackett.Server/runtimeconfig.template.json \
    # https://github.com/Jackett/Jackett/blob/b695ba285c71faa4804046fd134121654bbccbce/azure-pipelines.yml#L94
 && test "$(uname -m)" = aarch64 && ARCH=arm64 || ARCH=x64 \
 && dotnet publish Jackett.Server \
        --self-contained \
        -f net6.0 \
        -c Release \
        -r linux-musl-${ARCH} \
        /p:AssemblyVersion=${JACKETT_VER} \
        /p:FileVersion=${JACKETT_VER} \
        /p:InformationalVersion=${JACKETT_VER} \
        /p:Version=${JACKETT_VER} \
        /p:TrimUnusedDependencies=true \
        /p:PublishTrimmed=true \
        -o /out \
    \
    # Clean up!
 && apk --no-cache add binutils \
 && cd /out \
 && rm -f *.pdb \
 && chmod +x jackett \
 && strip -s /out/*.so

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FROM spritsail/alpine:3.16

ARG JACKETT_VER
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

COPY --from=dotnet /out .
COPY entrypoint.sh /usr/bin/entrypoint

RUN apk add --no-cache libcurl libgcc libstdc++ libintl \
 && chmod +x /usr/bin/entrypoint

VOLUME ["/config"]

EXPOSE 9117

HEALTHCHECK --start-period=10s --timeout=5s \
    CMD wget -qO /dev/null 'http://localhost:9117/torznab/all'

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/entrypoint"]
CMD ["/jackett/jackett", "-x", "-d", "/config", "--NoUpdates"]
