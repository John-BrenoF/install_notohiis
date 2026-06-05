#!/usr/bin/env bash

UI_OPTIONS=()
UI_SELECTED_INDEX=0
UI_SELECTED_OPTION=""
UI_PROMPT_MESSAGE=""

function ui_restore_terminal() {
  tput cnorm 2>/dev/null || true
  stty echo 2>/dev/null || true
}

function ui_draw_menu() {
  clear
  echo "$UI_PROMPT_MESSAGE"
  echo
  for index in "${!UI_OPTIONS[@]}"; do
    if [[ "$index" -eq "$UI_SELECTED_INDEX" ]]; then
      printf "\e[7m  %s  \e[0m\n" "${UI_OPTIONS[$index]}"
    else
      printf "    %s\n" "${UI_OPTIONS[$index]}"
    fi
  done
  echo
  echo "Use as setas ↑ ↓ para navegar e ENTER para confirmar. Ctrl+C para sair."
}

function ui_menu_select() {
  UI_PROMPT_MESSAGE="$1"
  shift
  UI_OPTIONS=("$@")
  UI_SELECTED_INDEX=0

  trap 'ui_restore_terminal; exit' INT TERM
  tput civis 2>/dev/null || true
  stty -echo 2>/dev/null || true

  ui_draw_menu
  while true; do
    IFS= read -rsn1 key
    if [[ "$key" == $'\x1b' ]]; then
      IFS= read -rsn2 -t 0.1 rest || true
      key+="$rest"
    fi

    case "$key" in
      $'\x1b[A'|$'\x1bOA')
        (( UI_SELECTED_INDEX = (UI_SELECTED_INDEX - 1 + ${#UI_OPTIONS[@]}) % ${#UI_OPTIONS[@]} ))
        ui_draw_menu
        ;;
      $'\x1b[B'|$'\x1bOB')
        (( UI_SELECTED_INDEX = (UI_SELECTED_INDEX + 1) % ${#UI_OPTIONS[@]} ))
        ui_draw_menu
        ;;
      "")
        break
        ;;
    esac
  done

  ui_restore_terminal
  UI_SELECTED_OPTION="${UI_OPTIONS[$UI_SELECTED_INDEX]}"
}

function ui_prompt_directory() {
  ui_restore_terminal
  echo
  read -rp "Digite o novo diretório de destino: " new_dir
  if [[ -z "$new_dir" ]]; then
    echo "Diretório não alterado."
    return 1
  fi
  if [[ "$new_dir" == ~* ]]; then
    new_dir="${new_dir/#~/$HOME}"
  fi
  UI_SELECTED_OPTION="$new_dir"
  return 0
}

function ui_confirm() {
  ui_restore_terminal
  echo
  read -rp "$1 [s/N]: " answer
  case "${answer,,}" in
    s|sim|y|yes) return 0 ;; 
    *) return 1 ;;
  esac
}
