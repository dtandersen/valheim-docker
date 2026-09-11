FROM debian:13-slim

RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      lib32gcc-s1 \
      lib32stdc++6 \
      libatomic1 \
      libgcc-s1 \
      libpulse0 \
      libstdc++6 \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --gid 568 steam \
 && useradd --uid 568 --gid 568 --create-home \
      --home-dir /home/steam --shell /usr/sbin/nologin steam \
 && mkdir -p /opt/steamcmd /data \
 && chown -R 568:568 /opt/steamcmd /data \
 && ln -s /opt/steamcmd/steamcmd.sh /usr/local/bin/steamcmd

# The SteamCMD app to install is 896660 (set by the entrypoint). Steam's
# backend expects the game id instead, so the image sets that here.
ENV HOME=/home/steam \
    LANG=C.UTF-8 \
    SteamAppId=892970

USER 568

RUN curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
      | tar -xz -C /opt/steamcmd \
 && /opt/steamcmd/steamcmd.sh +quit

COPY entrypoint.sh /usr/local/bin/valheim-entrypoint

WORKDIR /data

ENTRYPOINT ["/bin/bash", "/usr/local/bin/valheim-entrypoint"]
