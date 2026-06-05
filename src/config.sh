#!/usr/bin/env bash

: "${CONFIG_FILE:=}"
: "${ROOT_DIR:=}"
: "${REPO_URL:=}"
: "${INSTALL_DIR:=}"
: "${APP_NAME:=}"
: "${APP_DISPLAY_NAME:=}"
: "${ICON_PATH:=}"
: "${DESKTOP_ENTRY_DIR:=}"
: "${ICON_DEST_DIR:=}"

function config_init() {
  ROOT_DIR="${1:-${ROOT_DIR:-$(pwd)}}"
  CONFIG_FILE="$ROOT_DIR/.installer_config"

  REPO_URL="https://github.com/John-BrenoF/notohiis.git"
  INSTALL_DIR="$HOME/notohiis"
  APP_NAME="notohiis"
  APP_DISPLAY_NAME="notohiis 0.4alfa"
  ICON_PATH="$ROOT_DIR/midia/icons/nth.png"
  DESKTOP_ENTRY_DIR="$HOME/.local/share/applications"
  ICON_DEST_DIR="$HOME/.local/share/icons"

  if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
  fi

  if [[ "$INSTALL_DIR" == ~* ]]; then
    INSTALL_DIR="${INSTALL_DIR/#~/$HOME}"
  fi

  if [[ "$ICON_PATH" != /* ]]; then
    ICON_PATH="$ROOT_DIR/$ICON_PATH"
  fi
}

function config_escape() {
  local value="$1"
  printf '%s' "$value" | sed "s/'/'\"'\"'/g"
}

function config_save() {
  mkdir -p "$(dirname "$CONFIG_FILE")"
  cat > "$CONFIG_FILE" <<EOF
REPO_URL='$(config_escape "$REPO_URL")'
INSTALL_DIR='$(config_escape "$INSTALL_DIR")'
APP_NAME='$(config_escape "$APP_NAME")'
APP_DISPLAY_NAME='$(config_escape "$APP_DISPLAY_NAME")'
ICON_PATH='$(config_escape "$ICON_PATH")'
DESKTOP_ENTRY_DIR='$(config_escape "$DESKTOP_ENTRY_DIR")'
ICON_DEST_DIR='$(config_escape "$ICON_DEST_DIR")'
EOF
}

function config_set_install_dir() {
  local new_dir="$1"
  INSTALL_DIR="$new_dir"
  config_save
}

function config_get_install_dir() {
  printf '%s' "$INSTALL_DIR"
}

function config_list_directories() {
  local current_dir="$1"
  if [[ ! -d "$current_dir" ]]; then
    return 0
  fi

  local entry
  for entry in "$current_dir"/*; do
    if [[ -d "$entry" ]]; then
      printf '%s\n' "$(basename "$entry")/"
    fi
  done | sort
}

function config_normalize_path() {
  local path="$1"
  if [[ "$path" == ~* ]]; then
    path="${path/#~/$HOME}"
  fi
  printf '%s' "$path"
}
