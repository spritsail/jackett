ARG JACKETT_VER=0.18.512

FROM mcr.microsoft.com/dotnet/core/sdk:5.0.100-preview.3-alpine AS dotnet

ARG JACKETT_VER

WORKDIR /tmp
RUN wget -O- https://github.com/Jackett/Jackett/archive/v${JACKETT_VER}.tar.gz \
        | tar xz --strip-components=1 \
 && cd src \
 && echo '{"configProperties":{"System.Globalization.Invariant":true}}' > Jackett.Server/runtimeconfig.template.json \
 && dotnet publish Jackett.Server -f net5.0 --self-contained -c Release -r linux-musl-x64 /p:TrimUnusedDependencies=true /p:PublishTrimmed=true -o /out \
    \
    # Clean up!
 && apk --no-cache add binutils \
 && cd /out \
 && rm -f *.pdb \
 && chmod +x jackett \
 && strip -s /out/*.so

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FROM spritsail/alpine:3.12

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
