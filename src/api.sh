#!/usr/bin/env bash

GITHUB_TAGS_API="https://api.github.com/repos/John-BrenoF/notohiis/tags"
TAGS=()
WWW_COMMAND=""

function api_initialize() {
  if command -v curl >/dev/null 2>&1; then
    WWW_COMMAND="curl -sL"
  elif command -v wget >/dev/null 2>&1; then
    WWW_COMMAND="wget -qO-"
  else
    echo "Erro: nem curl nem wget estão disponíveis." >&2
    exit 1
  fi
}

function api_fetch_tags() {
  api_initialize

  local response
  response="$($WWW_COMMAND "$GITHUB_TAGS_API" 2>/dev/null || true)"
  TAGS=()

  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      TAGS+=("$line")
    fi
  done < <(
    printf '%s\n' "$response" |
      grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' |
      sed -E 's/.*:[[:space:]]*"([^"]*)".*/\1/'
  )
}
