#!/usr/bin/env bash

function action_check_dependencies() {
  if ! command -v git >/dev/null 2>&1; then
    echo "Erro: git não está instalado." >&2
    exit 1
  fi
}

function action_create_desktop_entry() {
  local exec_path="$1"
  mkdir -p "$DESKTOP_ENTRY_DIR" "$ICON_DEST_DIR"

  local icon_target="$ICON_PATH"
  if [[ -f "$ICON_PATH" ]]; then
    icon_target="$ICON_DEST_DIR/$APP_NAME.png"
    cp -f "$ICON_PATH" "$icon_target"
  fi

  local desktop_file="$DESKTOP_ENTRY_DIR/$APP_NAME.desktop"
  cat > "$desktop_file" <<EOF
[Desktop Entry]
Name=$APP_DISPLAY_NAME
Type=Application
Exec=$exec_path
Icon=$icon_target
Terminal=false
Categories=Utility;Development;
NoDisplay=false
EOF
  chmod 755 "$desktop_file"

  if command -v xdg-user-dir >/dev/null 2>&1; then
    local desktop_dir
    desktop_dir="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
    if [[ -n "$desktop_dir" && -d "$desktop_dir" ]]; then
      cp -f "$desktop_file" "$desktop_dir/"
    fi
  fi
}

function action_remove_desktop_entry() {
  local desktop_file="$DESKTOP_ENTRY_DIR/$APP_NAME.desktop"
  rm -f "$desktop_file"

  if command -v xdg-user-dir >/dev/null 2>&1; then
    local desktop_dir
    desktop_dir="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
    if [[ -n "$desktop_dir" ]]; then
      rm -f "$desktop_dir/$APP_NAME.desktop"
    fi
  fi
}

function action_install() {
  local install_dir="$1"
  local version="$2"
  local repo_url="$3"

  mkdir -p "$(dirname "$install_dir")"
  if [[ -e "$install_dir" && -n "$(ls -A "$install_dir" 2>/dev/null)" ]]; then
    echo "Erro: o diretório de instalação já existe e não está vazio: $install_dir" >&2
    return 1
  fi

  echo "Clonando $repo_url na versão '$version'..."
  git clone --branch "$version" --depth 1 "$repo_url" "$install_dir"

  local shell_path="$install_dir/notohiis.sh"
  if [[ -f "$shell_path" ]]; then
    chmod +x "$shell_path"
    action_create_desktop_entry "$shell_path"
    echo "Instalação concluída em: $install_dir"
    echo "Atalho criado em: $DESKTOP_ENTRY_DIR/$APP_NAME.desktop"
  else
    echo "Instalação concluída em: $install_dir"
    echo "Aviso: não foi encontrado $shell_path para criar o atalho." >&2
  fi
}

function action_uninstall() {
  local install_dir="$1"

  if [[ ! -d "$install_dir" ]]; then
    echo "Nenhuma instalação encontrada em: $install_dir" >&2
    return 1
  fi

  rm -rf "$install_dir"
  action_remove_desktop_entry
  echo "Instalação removida: $install_dir"
}
