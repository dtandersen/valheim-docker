#!/usr/bin/env bash
set -euo pipefail

STEAMCMD="${STEAMCMD_BIN:-/opt/steamcmd/steamcmd.sh}"
# The dedicated server app SteamCMD installs. This is not the id the server
# process hands to Steam: SteamAppId is the game id (892970), set by the image.
APP_ID="${STEAMCMD_APP_ID:-896660}"
INSTALL_DIR="${STEAMCMD_INSTALL_DIR:-/data}"
LOGIN="${STEAMCMD_LOGIN:-anonymous}"

SERVER_NAME="${SERVER_NAME:-Valheim}"
SERVER_PORT="${SERVER_PORT:-2456}"
SERVER_PUBLIC="${SERVER_PUBLIC:-1}"
SERVER_WORLD_NAME="${SERVER_WORLD_NAME:-Dedicated}"
SERVER_PW="${SERVER_PW:-}"
SERVER_LOG_PATH="${SERVER_LOG_PATH:-logs/outputlog_server.txt}"
SERVER_SAVE_DIR="${SERVER_SAVE_DIR:-Worlds}"
SCREEN_QUALITY="${SCREEN_QUALITY:-Fastest}"
SCREEN_WIDTH="${SCREEN_WIDTH:-640}"
SCREEN_HEIGHT="${SCREEN_HEIGHT:-480}"
ADDITIONAL_ARGS="${ADDITIONAL_ARGS:-}"

# Valheim's bundled libraries live beside the server binary.
export LD_LIBRARY_PATH="${INSTALL_DIR}/linux64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

if [ -z "${SERVER_PW}" ]; then
  echo "SERVER_PW is required" >&2
  exit 1
fi

echo "SteamCMD app ${APP_ID}; SteamAppId ${SteamAppId:-unset}"

if [ "${STEAMCMD_UPDATE:-1}" = "1" ]; then
  "${STEAMCMD}" +quit
  "${STEAMCMD}" \
    +force_install_dir "${INSTALL_DIR}" \
    +login "${LOGIN}" \
    +app_update "${APP_ID}" validate \
    +quit
fi

cd "${INSTALL_DIR}"
mkdir -p "$(dirname "${SERVER_LOG_PATH}")" "${SERVER_SAVE_DIR}"

server_args=(
  -batchmode
  -nographics
  -screen-width "${SCREEN_WIDTH}"
  -screen-height "${SCREEN_HEIGHT}"
  -screen-quality "${SCREEN_QUALITY}"
  -logFile "${SERVER_LOG_PATH}"
  -name "${SERVER_NAME}"
  -port "${SERVER_PORT}"
  -world "${SERVER_WORLD_NAME}"
  -password "${SERVER_PW}"
  -public "${SERVER_PUBLIC}"
  -savedir "${SERVER_SAVE_DIR}"
)

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
