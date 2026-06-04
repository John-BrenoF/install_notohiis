#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$ROOT_DIR/.venv"
PYTHON_EXEC="python3"

# Use python3 if available, fallback to python
if ! command -v "$PYTHON_EXEC" >/dev/null 2>&1; then
  PYTHON_EXEC=python
fi

# Create virtual environment if needed
if [ ! -d "$VENV_DIR" ]; then
  echo "Criando ambiente virtual em $VENV_DIR..."
  "$PYTHON_EXEC" -m venv "$VENV_DIR"
fi

# Ativa o ambiente virtual
# shellcheck source=/dev/null
source "$VENV_DIR/bin/activate"

echo "Ativando ambiente virtual: $VENV_DIR"
python -m pip install --upgrade pip

# Instala dependências necessárias
if [ -f "$ROOT_DIR/requirements.txt" ]; then
  echo "Instalando dependências de requirements.txt..."
  pip install -r "$ROOT_DIR/requirements.txt"
else
  echo "Instalando dependências padrão..."
  pip install watchdog
fi

echo "Executando interface do instalador..."
python "$ROOT_DIR/src/script/ui/ui.py"
