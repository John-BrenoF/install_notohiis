#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$ROOT_DIR/src/config.sh"
source "$ROOT_DIR/src/api.sh"
source "$ROOT_DIR/src/ui.sh"
source "$ROOT_DIR/src/actions.sh"

config_init "$ROOT_DIR"

action_check_dependencies

function install_flow() {
  api_fetch_tags

  local versions=("main")
  if [[ ${#TAGS[@]} -gt 0 ]]; then
    versions+=("${TAGS[@]}")
  fi

  ui_menu_select "Selecione a versão para clonar:" "${versions[@]}"
  local selected_version="$UI_SELECTED_OPTION"

  action_install "$INSTALL_DIR" "$selected_version" "$REPO_URL"
}

function uninstall_flow() {
  if ui_confirm "Deseja realmente remover a instalação em $INSTALL_DIR?"; then
    action_uninstall "$INSTALL_DIR"
  else
    echo "Desinstalação cancelada."
  fi
}

function change_destination_flow() {
  if ui_prompt_directory; then
    config_set_install_dir "$UI_SELECTED_OPTION"
    echo "Diretório de destino alterado para: $UI_SELECTED_OPTION"
  fi
}

function main_menu() {
  ui_menu_select "Menu Principal:" \
    "Instalar Notohiis" \
    "Desinstalar Notohiis" \
    "Alterar diretório de destino" \
    "Sair"
}

while true; do
  main_menu
  case "$UI_SELECTED_OPTION" in
    "Instalar Notohiis")
      install_flow
      ;;
    "Desinstalar Notohiis")
      uninstall_flow
      ;;
    "Alterar diretório de destino")
      change_destination_flow
      ;;
    "Sair")
      echo "Saindo.";
      exit 0
      ;;
    *)
      echo "Opção desconhecida.";
      ;;
  esac
  echo
  read -rp "Pressione ENTER para voltar ao menu..." _
done
