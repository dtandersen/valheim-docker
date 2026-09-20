#!/usr/bin/env bash
set -euo pipefail

is_true() {
  case "${1,,}" in
    1|true|yes|on) return 0 ;;
    *) return 1 ;;
  esac
}

STEAMCMD=/opt/steamcmd/steamcmd.sh
INSTALL_DIR=/data
LOGIN=anonymous
SAVE_DIR=worlds
# The dedicated server app SteamCMD installs. This is not the id the server
# process hands to Steam: SteamAppId is the game id (892970), set by the image.
APP_ID=896660

SERVER_NAME="${SERVER_NAME:-Valheim}"
SERVER_PORT="${SERVER_PORT:-2456}"
SERVER_PUBLIC="${SERVER_PUBLIC:-1}"
SERVER_WORLD_NAME="${SERVER_WORLD_NAME:-Dedicated}"
SERVER_PW="${SERVER_PW:-}"
SERVER_SAVE_INTERVAL="${SERVER_SAVE_INTERVAL-1800}"
SERVER_BACKUPS="${SERVER_BACKUPS-4}"
SERVER_BACKUP_SHORT="${SERVER_BACKUP_SHORT-7200}"
SERVER_BACKUP_LONG="${SERVER_BACKUP_LONG-43200}"
SERVER_CROSSPLAY="${SERVER_CROSSPLAY:-false}"
SERVER_ADMINS="${SERVER_ADMINS:-}"
ADDITIONAL_ARGS="${ADDITIONAL_ARGS:-}"

# Valheim's bundled libraries live beside the server binary.
export LD_LIBRARY_PATH="${INSTALL_DIR}/linux64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

echo "SteamCMD app ${APP_ID}; SteamAppId ${SteamAppId:-unset}"

# Rebuild Steam's app metadata/install state on every start. Valheim saves are
# kept separately in /data/worlds, so removing steamapps does not remove them.
echo "Removing ${INSTALL_DIR}/steamapps"
rm -rf -- "${INSTALL_DIR}/steamapps"

if is_true "${STEAMCMD_UPDATE:-true}"; then
  "${STEAMCMD}" +quit

  update_args=()
  if is_true "${STEAMCMD_VALIDATE:-true}"; then
    update_args=(validate)
  fi

  "${STEAMCMD}" \
    +force_install_dir "${INSTALL_DIR}" \
    +login "${LOGIN}" \
    +app_update "${APP_ID}" "${update_args[@]}" \
    +quit
fi

cd "${INSTALL_DIR}"
mkdir -p "${SAVE_DIR}"

# Ensure each configured admin is listed once, keeping whatever is already
# there (including the file's own comment header).
if [ -n "${SERVER_ADMINS}" ]; then
  for id in ${SERVER_ADMINS}; do
    case "${id}" in
      *[!0-9]*|"")
        echo "Ignoring non-numeric admin id: ${id}" >&2
        continue
        ;;
    esac
    grep -qxF "${id}" "${SAVE_DIR}/adminlist.txt" 2>/dev/null \
      || echo "${id}" >> "${SAVE_DIR}/adminlist.txt"
  done
fi

server_args=(
  -batchmode
  -nographics
  -name "${SERVER_NAME}"
  -port "${SERVER_PORT}"
  -world "${SERVER_WORLD_NAME}"
  -public "${SERVER_PUBLIC}"
  -savedir "${SAVE_DIR}"
)

if [ -n "${SERVER_PW}" ]; then
  server_args+=(-password "${SERVER_PW}")
fi
if [ -n "${SERVER_SAVE_INTERVAL}" ]; then
  server_args+=(-saveinterval "${SERVER_SAVE_INTERVAL}")
fi
if [ -n "${SERVER_BACKUPS}" ]; then
  server_args+=(-backups "${SERVER_BACKUPS}")
fi
if [ -n "${SERVER_BACKUP_SHORT}" ]; then
  server_args+=(-backupshort "${SERVER_BACKUP_SHORT}")
fi
if [ -n "${SERVER_BACKUP_LONG}" ]; then
  server_args+=(-backuplong "${SERVER_BACKUP_LONG}")
fi
if is_true "${SERVER_CROSSPLAY:-false}"; then
  server_args+=(-crossplay)
fi

extra_args=()
if [ -n "${ADDITIONAL_ARGS}" ]; then
  # shellcheck disable=SC2206
  extra_args=(${ADDITIONAL_ARGS})
fi

if [ -f ./start_server_bepinex.sh ]; then
  exec /bin/bash ./start_server_bepinex.sh "${server_args[@]}" "${extra_args[@]}"
fi

if [ -x ./valheim_server.x86_64 ]; then
  exec ./valheim_server.x86_64 "${server_args[@]}" "${extra_args[@]}"
fi

echo "no Valheim server in ${INSTALL_DIR}" >&2
exit 1
