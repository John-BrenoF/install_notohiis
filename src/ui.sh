#!/usr/bin/env bash

UI_OPTIONS=()
UI_SELECTED_INDEX=0
UI_SELECTED_OPTION=""
UI_PROMPT_MESSAGE=""
UI_STATUS=""
UI_PROGRESS=""

UI_RESET=$'\e[0m'
UI_BOLD=$'\e[1m'
UI_CYAN=$'\e[36m'
UI_GREEN=$'\e[32m'
UI_BLUE=$'\e[34m'
UI_WHITE=$'\e[97m'
UI_REVERSE=$'\e[7m'

function ui_restore_terminal() {
  tput cnorm 2>/dev/null || true
  stty echo 2>/dev/null || true
}

function ui_draw_menu() {
  clear
  local width=68
  local content_width=$((width - 4))
  local border_top="┌$(printf '─%.0s' $(seq 1 $((width - 2))))┐"
  local border_bot="└$(printf '─%.0s' $(seq 1 $((width - 2))))┘"

  echo -e "${UI_BLUE}${border_top}${UI_RESET}"
  # Header with app name and status
  local title="${APP_DISPLAY_NAME:-notohiis}"
  printf "%s│ ${UI_BOLD}${UI_WHITE}%-${content_width}s${UI_RESET}${UI_BLUE} │%s\n" "$UI_BLUE" "$title" "$UI_RESET"
  echo -e "${UI_BLUE}├$(printf '─%.0s' $(seq 1 $((width - 2))))┤${UI_RESET}"

  for index in "${!UI_OPTIONS[@]}"; do
    local line="  ${UI_OPTIONS[$index]}"
    if [[ "$index" -eq "$UI_SELECTED_INDEX" ]]; then
      printf "%s│ ${UI_REVERSE}${UI_CYAN}%-${content_width}s${UI_RESET}${UI_BLUE} │%s\n" "$UI_BLUE" "$line" "$UI_RESET"
    else
      printf "%s│ ${UI_WHITE}%-${content_width}s${UI_RESET}${UI_BLUE} │%s\n" "$UI_BLUE" "$line" "$UI_RESET"
    fi
  done
  echo -e "${UI_BLUE}${border_bot}${UI_RESET}"
  if [[ -n "$UI_STATUS" ]]; then
    echo -e "${UI_GREEN}${UI_STATUS}${UI_RESET}"
  fi
  if [[ -n "$UI_PROGRESS" ]]; then
    echo -e "${UI_CYAN}${UI_PROGRESS}${UI_RESET}"
  fi
  echo -e "${UI_GREEN}Use ↑ ↓ para navegar, ENTER para confirmar. Ctrl+C para sair.${UI_RESET}"
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

function ui_draw_browser() {
  clear
  local width=68
  local content_width=$((width - 4))
  local border_top="┌$(printf '─%.0s' $(seq 1 $((width - 2))))┐"
  local border_mid="├$(printf '─%.0s' $(seq 1 $((width - 2))))┤"
  local border_bot="└$(printf '─%.0s' $(seq 1 $((width - 2))))┘"

  echo -e "${UI_BLUE}${border_top}${UI_RESET}"
  # Header: current directory and optional status
  printf "%s│ ${UI_BOLD}${UI_WHITE}%-${content_width}s${UI_RESET}${UI_BLUE} │%s\n" "$UI_BLUE" "$UI_PROMPT_MESSAGE" "$UI_RESET"
  echo -e "${UI_BLUE}${border_mid}${UI_RESET}"

  for index in "${!UI_OPTIONS[@]}"; do
    local item="${UI_OPTIONS[$index]}"
    if [[ "$index" -eq "$UI_SELECTED_INDEX" ]]; then
      printf "%s│ ${UI_REVERSE}${UI_CYAN}%-${content_width}s${UI_RESET}${UI_BLUE} │%s\n" "$UI_BLUE" "$item" "$UI_RESET"
    else
      printf "%s│ ${UI_WHITE}%-${content_width}s${UI_RESET}${UI_BLUE} │%s\n" "$UI_BLUE" "$item" "$UI_RESET"
    fi
  done

  echo -e "${UI_BLUE}${border_bot}${UI_RESET}"
  if [[ -n "$UI_STATUS" ]]; then
    echo -e "${UI_GREEN}${UI_STATUS}${UI_RESET}"
  fi
  if [[ -n "$UI_PROGRESS" ]]; then
    echo -e "${UI_CYAN}${UI_PROGRESS}${UI_RESET}"
  fi
  echo -e "${UI_GREEN}Use ↑ ↓ para navegar, ENTER para entrar/selecionar, Ctrl+C para sair.${UI_RESET}"
}

function ui_set_status() {
  UI_STATUS="$1"
}

function ui_set_progress() {
  UI_PROGRESS="$1"
}

function ui_clear_status() {
  UI_STATUS=""
  UI_PROGRESS=""
}

function ui_prompt_directory() {
  local current_path="${1:-$HOME}"
  while true; do
    UI_PROMPT_MESSAGE="Diretório atual: $current_path"
    UI_OPTIONS=()

    if [[ "$current_path" != "/" ]]; then
      UI_OPTIONS+=("../")
    fi

    while IFS= read -r entry; do
      UI_OPTIONS+=("$entry")
    done < <(config_list_directories "$current_path")

    UI_OPTIONS+=("[ Selecionar esta pasta ]")
    UI_SELECTED_INDEX=0

    trap 'ui_restore_terminal; exit' INT TERM
    tput civis 2>/dev/null || true
    stty -echo 2>/dev/null || true

    ui_draw_browser
    while true; do
      IFS= read -rsn1 key
      if [[ "$key" == $'\x1b' ]]; then
        IFS= read -rsn2 -t 0.1 rest || true
        key+="$rest"
      fi

      case "$key" in
        $'\x1b[A'|$'\x1bOA')
          (( UI_SELECTED_INDEX = (UI_SELECTED_INDEX - 1 + ${#UI_OPTIONS[@]}) % ${#UI_OPTIONS[@]} ))
          ui_draw_browser
          ;;
        $'\x1b[B'|$'\x1bOB')
          (( UI_SELECTED_INDEX = (UI_SELECTED_INDEX + 1) % ${#UI_OPTIONS[@]} ))
          ui_draw_browser
          ;;
        "")
          break
          ;;
      esac
    done

    ui_restore_terminal
    local choice="${UI_OPTIONS[$UI_SELECTED_INDEX]}"

    if [[ "$choice" == "[ Selecionar esta pasta ]" ]]; then
      UI_SELECTED_OPTION="$current_path"
      return 0
    elif [[ "$choice" == "../" ]]; then
      current_path="$(dirname "$current_path")"
    else
      current_path="$current_path/${choice%/}"
    fi
  done
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
