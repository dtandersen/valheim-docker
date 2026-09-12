# valheim

Valheim dedicated server image, published as `ghcr.io/dtandersen/valheim`.

It runs non-root (UID/GID 568, the TrueCharts default) and contains the
server's runtime libraries plus SteamCMD. The game itself is never baked in —
SteamCMD installs app `896660` into `/data` on start.

```console
$ docker run --rm -v valheim-data:/data -e SERVER_PW=changeme ghcr.io/dtandersen/valheim
```

## Entrypoint

1. Updates SteamCMD itself, then installs/updates app `896660` into `/data`,
   unless `STEAMCMD_UPDATE` is false.
2. Appends SteamCMD's `validate`, unless `STEAMCMD_VALIDATE` is false. `validate`
   re-reads the whole install, so disabling it makes startup much faster.
3. Prepends `<install dir>/linux64` to `LD_LIBRARY_PATH`.
4. Runs `/data/start_server_bepinex.sh` when BepInEx is present, otherwise
   `/data/valheim_server.x86_64`, with:

   ```text
   -batchmode -nographics -name … -port … -world … -public … -savedir …
   [-password …] [-saveinterval …] [-backups …] [-backupshort …] [-backuplong …]
   [-crossplay]
   ```

   Empty values omit their flag, so exporting `SERVER_BACKUPS=` drops `-backups`
   and letting Valheim apply its own default.

The entrypoint `exec`s the server, so it stays PID 1 and receives signals
directly. `STEAMCMD_UPDATE` and `STEAMCMD_VALIDATE` accept booleans: `1`/`true`,
`yes`, `on` (any case) are true, anything else is false.

### SteamCMD

| Env | Default |
|---|---|
| `STEAMCMD_UPDATE` | `true` |
| `STEAMCMD_VALIDATE` | `true` |

SteamCMD is fixed at `/opt/steamcmd/steamcmd.sh`, installs into `/data` and logs
in anonymously. The app id (`896660`), install directory (`/data`) and save
directory (`worlds`) are not configurable, because the image is Valheim-specific.

### Server

| Env | Default |
|---|---|
| `SERVER_NAME` | `Valheim` |
| `SERVER_PORT` | `2456` |
| `SERVER_PUBLIC` | `1` |
| `SERVER_WORLD_NAME` | `Dedicated` |
| `SERVER_PW` | empty → random 8-char generated |
| `SERVER_SAVE_INTERVAL` | `1800` |
| `SERVER_BACKUPS` | `4` |
| `SERVER_BACKUP_SHORT` | `7200` |
| `SERVER_BACKUP_LONG` | `43200` |
| `SERVER_CROSSPLAY` | `false` |
| `ADDITIONAL_ARGS` | empty |

`SERVER_PUBLIC` is passed straight to the server's `-public` flag, so it takes
`0` or `1`. `SERVER_PW` is empty by default; when it is empty the entrypoint
generates a random 8-character alphanumeric password and prints it, so it shows
up in `kubectl logs`/`docker logs`. A password you set yourself is never logged.
Set it explicitly to pin one — Valheim
requires at least 5 characters. `SERVER_CROSSPLAY`
adds `-crossplay`, which routes through PlayFab so console players can join.

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
