#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="/usr/local/bin"

# --- Funções utilitárias ---
log() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
err() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

# --- Instala dependências ---
install_dependencies() {
  local pkgs=("curl" "jq" "tar" "coreutils")
  local missing=()
  for pkg in "${pkgs[@]}"; do
    if ! command -v "$pkg" &>/dev/null; then
      missing+=("$pkg")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    log "Instalando dependências: ${missing[*]}"
    if command -v apt &>/dev/null; then
      sudo apt update && sudo apt install -y "${missing[@]}"
    elif command -v yum &>/dev/null; then
      sudo yum install -y "${missing[@]}"
    elif command -v brew &>/dev/null; then
      brew install "${missing[@]}"
    else
      err "Gerenciador de pacotes não detectado. Instale manualmente: ${missing[*]}"
    fi
  fi
}

# --- Detecta SO e Arquitetura ---
detect_platform() {
  OS=$(uname | tr '[:upper:]' '[:lower:]')
  case "$OS" in
    linux*) OS="linux" ;;
    darwin*) OS="darwin" ;;
    *) err "SO não suportado: $OS" ;;
  esac

  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *) err "Arquitetura não suportada: $ARCH" ;;
  esac
}

# --- Obtém a última versão ---
get_latest_tag() {
  curl -s https://api.github.com/repos/asdf-vm/asdf/releases/latest | jq -r '.tag_name'
}

# --- Download e verificação de integridade ---
download_asdf() {
  local tag="$1"
  ASSET_NAME="asdf-${tag}-${OS}-${ARCH}.tar.gz"
  ASSET_URL="https://github.com/asdf-vm/asdf/releases/download/${tag}/${ASSET_NAME}"

  log "Baixando ${ASSET_NAME}..."
  curl -L -o "${ASSET_NAME}" "${ASSET_URL}"
  curl -L -o "${ASSET_NAME}.md5" "${ASSET_URL}.md5"

  validate_checksum "${ASSET_NAME}" "${ASSET_NAME}.md5"
}

# --- Valida o checksum ---
validate_checksum() {
  local file="$1"
  local md5_file="$2"
  local expected_md5
  expected_md5=$(tr -d '\n\r' < "$md5_file")

  local file_md5
  if [[ "$OS" == "darwin" ]]; then
    file_md5=$(md5 -q "$file")
  else
    file_md5=$(md5sum "$file" | awk '{print $1}')
  fi

  if [[ "$expected_md5" != "$file_md5" ]]; then
    err "Falha na validação do checksum MD5! Esperado: $expected_md5 | Obtido: $file_md5"
  fi
  log "Checksum MD5 validado com sucesso!"
}

# --- Instalação ---
install_asdf() {
  log "Instalando em ${INSTALL_DIR}..."
  sudo tar --strip-components=1 -xzf "${ASSET_NAME}" -C "${INSTALL_DIR}"
  log "ASDF instalado em ${INSTALL_DIR}/asdf"
}

# --- Fluxo principal ---
main() {
  install_dependencies
  detect_platform
  local latest_tag
  latest_tag=$(get_latest_tag)
  log "Instalando ASDF versão ${latest_tag} para ${OS}-${ARCH}"
  download_asdf "$latest_tag"
  install_asdf
  log "Verifique a instalação com: asdf --version"
}

main "$@"
