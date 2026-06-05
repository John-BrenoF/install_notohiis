#!/usr/bin/env bash

function action_check_dependencies() {
  if ! command -v git >/dev/null 2>&1; then
    echo "Erro: git não está instalado." >&2
    exit 1
  fi
}

function action_create_desktop_entry() {
  local exec_path="$1"
  local version="${2:-}"
  mkdir -p "$DESKTOP_ENTRY_DIR" "$ICON_DEST_DIR"

  local icon_target="$ICON_PATH"
  if [[ -f "$ICON_PATH" ]]; then
    icon_target="$ICON_DEST_DIR/$APP_NAME.png"
    cp -f "$ICON_PATH" "$icon_target"
  fi

  local desktop_file="$DESKTOP_ENTRY_DIR/$APP_NAME.desktop"
  local name_field="$APP_DISPLAY_NAME"
  if [[ -n "$version" && "$version" != "main" ]]; then
    name_field="$APP_DISPLAY_NAME ($version)"
  fi

  cat > "$desktop_file" <<EOF
[Desktop Entry]
Name=${name_field}
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
  local base_dir="$1"
  local version="$2"
  local repo_url="$3"

  local install_dir="${base_dir%/}/$APP_NAME"

  mkdir -p "$base_dir"
  if [[ -e "$install_dir" && -n "$(ls -A "$install_dir" 2>/dev/null)" ]]; then
    echo "Erro: o diretório de instalação já existe e não está vazio: $install_dir" >&2
    return 1
  fi

  echo -e "${UI_GREEN}Instalando em: ${install_dir}${UI_RESET}"
  echo "Clonando $repo_url na versão '$version'..."
  # Update UI status
  if declare -f ui_set_status >/dev/null 2>&1; then
    ui_set_status "Clonando $repo_url em $install_dir"
  fi

  # Perform git clone with progress parsing (uses stdbuf if available to force line buffering)
  local GIT_CMD=(git clone --progress --branch "$version" --depth 1 "$repo_url" "$install_dir")
  if command -v stdbuf >/dev/null 2>&1; then
    stdbuf -oL -eL "${GIT_CMD[@]}" 2>&1 | while IFS= read -r line; do
      if [[ "$line" =~ ([0-9]{1,3})% ]]; then
        local pct="${BASH_REMATCH[1]}"
        local bar_len=30
        local filled=$((pct * bar_len / 100))
        local empty=$((bar_len - filled))
        local bar="$(printf '%0.s#' $(seq 1 $filled))$(printf '%0.s-' $(seq 1 $empty))"
        if declare -f ui_set_progress >/dev/null 2>&1; then
          ui_set_progress "[${bar}] ${pct}%"
        fi
        printf "\r${UI_CYAN}Progresso: [%s] %s%%${UI_RESET}" "$bar" "$pct"
      else
        printf "\n%s\n" "$line"
      fi
    done
    local git_exit=${PIPESTATUS[0]}
  else
    git clone --progress --branch "$version" --depth 1 "$repo_url" "$install_dir" 2>&1 | while IFS= read -r line; do
      if [[ "$line" =~ ([0-9]{1,3})% ]]; then
        local pct="${BASH_REMATCH[1]}"
        local bar_len=30
        local filled=$((pct * bar_len / 100))
        local empty=$((bar_len - filled))
        local bar="$(printf '%0.s#' $(seq 1 $filled))$(printf '%0.s-' $(seq 1 $empty))"
        if declare -f ui_set_progress >/dev/null 2>&1; then
          ui_set_progress "[${bar}] ${pct}%"
        fi
        printf "\r${UI_CYAN}Progresso: [%s] %s%%${UI_RESET}" "$bar" "$pct"
      else
        printf "\n%s\n" "$line"
      fi
    done
    local git_exit=${PIPESTATUS[0]}
  fi

  printf "\n"
  if [[ "$git_exit" -ne 0 ]]; then
    echo "Erro: falha ao clonar o repositório." >&2
    return $git_exit
  fi

  local shell_path="$install_dir/notohiis.sh"
  if [[ -f "$shell_path" ]]; then
    chmod +x "$shell_path"
    action_create_desktop_entry "$shell_path" "$version"
    echo -e "${UI_GREEN}Instalação concluída em: ${install_dir}${UI_RESET}"
    echo "Atalho criado em: $DESKTOP_ENTRY_DIR/$APP_NAME.desktop"
  else
    echo -e "${UI_GREEN}Instalação concluída em: ${install_dir}${UI_RESET}"
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
