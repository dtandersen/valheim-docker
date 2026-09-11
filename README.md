# valheim

Valheim dedicated server image, published as `ghcr.io/dtandersen/valheim`.

It runs non-root (UID/GID 568, the TrueCharts default) and contains the
server's runtime libraries plus SteamCMD. The game itself is never baked in —
SteamCMD installs app `896660` into `/data` on start.

```console
$ docker run --rm -v valheim-data:/data -e SERVER_PW=changeme ghcr.io/dtandersen/valheim
```

## Entrypoint

The entrypoint runs SteamCMD (self-update, then `app_update 896660 validate`)
and then launches `/data/start_server_bepinex.sh` when BepInEx is present, or
`/data/valheim_server.x86_64` otherwise.

### SteamCMD

| Env | Default |
|---|---|
| `STEAMCMD_BIN` | `/opt/steamcmd/steamcmd.sh` (`steamcmd` is also on `PATH`) |
| `STEAMCMD_APP_ID` | `896660` |
| `STEAMCMD_INSTALL_DIR` | `/data` |
| `STEAMCMD_LOGIN` | `anonymous` |
| `STEAMCMD_UPDATE` | `1` |

### Server

| Env | Default |
|---|---|
| `SERVER_NAME` | `Valheim` |
| `SERVER_PORT` | `2456` |
| `SERVER_PUBLIC` | `1` |
| `SERVER_WORLD_NAME` | `Dedicated` |
| `SERVER_PW` | required |
| `SERVER_SAVE_DIR` | `Worlds` |
| `ADDITIONAL_ARGS` | empty |

SteamCMD writes to `$HOME` (`/home/steam`) and `/opt/steamcmd`, so the container
needs a writable root filesystem or writable volumes at those paths.

The image sets `SteamAppId=892970` (Valheim's game id, distinct from the
`896660` dedicated server app) so the server registers with Steam.

## Image

- Base: `debian:13-slim`
- Runtime libraries: `libatomic1`, `libpulse0`, `libstdc++6`, `libgcc-s1`
- SteamCMD: official `steamcmd_linux.tar.gz` into `/opt/steamcmd`
- SteamCMD deps: `lib32gcc-s1`, `lib32stdc++6` (i386)

Images are built on every push to `main`, on tags, and on demand. Tags produced:
`latest` (default branch), the git tag, and the short SHA.
