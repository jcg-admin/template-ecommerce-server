#!/bin/bash
# =============================================================================
# scripts/setup.sh
# Punto de entrada unificado para aprovisionar template-ecommerce-server
# =============================================================================
# Orquesta los 8 pasos de aprovisionamiento en el orden correcto.
# Resuelve el problema del lockout SSH mediante dos fases separadas
# por una pausa de reconexion.
#
# FASES:
#   Fase 1 (por defecto):
#     1. provisioners/nginx/install.sh
#     2. provisioners/security/setup_ssh_hardening.sh
#     -> PAUSA: el operador reconecta SSH en el nuevo puerto
#
#   Fase 2 (--continue):
#     3. provisioners/firewall/setup_firewall.sh
#     4. provisioners/security/setup_fail2ban.sh
#     5. provisioners/ssl/setup_ssl.sh
#     6. provisioners/nginx/setup_vhost.sh
#     7. scripts/verify.sh
#
# Flags:
#   --continue     Retoma desde Fase 2 tras reconectar SSH.
#   --skip-ssh     Omite setup_ssh_hardening.sh y suprime la pausa.
#                  Uso: WSL2, CI, entornos sin sshd nativo.
#   --ssl-dev      Pasa --dev a setup_ssl.sh (self-signed, sin DNS).
#   --ssl-staging  Pasa --staging a setup_ssl.sh (LE staging).
#   Sin --ssl-*    Modo produccion: Let's Encrypt real.
#
# Prerequisitos (responsabilidad del operador):
#   1. Repo clonado y ubicado en su directorio raiz.
#   2. .env creado: cp .env.example .env && nano .env
#   3. Clave SSH en ~/.ssh/authorized_keys (guard anti-lockout).
#   4. Ejecutar con sudo o como root.
#
# Uso:
#   sudo bash scripts/setup.sh
#   sudo bash scripts/setup.sh --continue
#   sudo bash scripts/setup.sh --skip-ssh --ssl-dev
#
# Idempotente: seguro de ejecutar multiples veces.
# Los provisioners que orquesta ya son idempotentes.
#
# Iniciativa: crear-setup-sh (PROC-GESTION-001 v4.0.0)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export PROJECT_ROOT

source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/core.sh"

# Variables globales de flags
_CONTINUE=false
_SKIP_SSH=false
_SSL_FLAG=""

# =============================================================================
# _usage
# Imprime ayuda completa con flags, prerequisitos y flujos de uso.
# =============================================================================
_usage() {
    cat << 'USAGE'
Uso: sudo bash scripts/setup.sh [FLAGS]

Aprovisiona template-ecommerce-server desde cero en dos fases.

FLAGS:
  --continue     Retoma desde Fase 2 tras reconectar SSH en el nuevo
                 puerto. Usar solo despues de haber ejecutado Fase 1.
  --skip-ssh     Omite setup_ssh_hardening.sh. Suprime la pausa de
                 reconexion. Uso: WSL2, CI, entornos sin sshd nativo.
  --ssl-dev      Genera certificado self-signed con OpenSSL.
                 No requiere dominio publico ni red.
  --ssl-staging  Usa Let's Encrypt staging. Rate-limit amigable;
                 el cert no es confiable por navegadores.
  Sin --ssl-*    Modo produccion: Let's Encrypt real (requiere DNS).
  --help, -h     Muestra esta ayuda.

COMBINACIONES INVALIDAS:
  --skip-ssh + --continue: incompatibles. Con --skip-ssh no hay
  pausa de reconexion SSH y por tanto no se necesita --continue.

PREREQUISITOS (responsabilidad del operador):
  1. Clonar el repo y ubicarse en su directorio raiz.
  2. Crear y editar .env:
       cp .env.example .env
       nano .env   # DOMAIN, UI_DIST, SSL_EMAIL, SSH_PORT...
  3. Tener al menos una clave SSH en ~/.ssh/authorized_keys
     antes de Fase 1. Sin ella quedarias bloqueado fuera del
     server tras el hardening SSH.
  4. Ejecutar con sudo o como root.

FLUJO NORMAL (servidor de produccion):
  sudo bash scripts/setup.sh              # Fase 1
  # Reconectar: ssh -p $SSH_PORT usuario@servidor
  sudo bash scripts/setup.sh --continue   # Fase 2

FLUJO WSL2 / CI (sin SSH nativo):
  sudo bash scripts/setup.sh --skip-ssh --ssl-dev

FLUJO STAGING (validar ACME antes de produccion):
  sudo bash scripts/setup.sh              # Fase 1
  # Reconectar en nuevo puerto
  sudo bash scripts/setup.sh --continue --ssl-staging

USAGE
}

# =============================================================================
# _parse_flags
# Parsea los argumentos de linea de comandos y detecta combinaciones
# invalidas antes de ejecutar cualquier accion.
# =============================================================================
_parse_flags() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --continue)    _CONTINUE=true ;;
            --skip-ssh)    _SKIP_SSH=true ;;
            --ssl-dev)     _SSL_FLAG="--dev" ;;
            --ssl-staging) _SSL_FLAG="--staging" ;;
            --help|-h)     _usage; exit 0 ;;
            *)
                log_error "Flag desconocido: $1"
                log_info  "Ejecuta: bash scripts/setup.sh --help"
                exit 1
                ;;
        esac
        shift
    done

    # Combinacion invalida: --skip-ssh + --continue
    if [[ "$_SKIP_SSH" == "true" && "$_CONTINUE" == "true" ]]; then
        log_error "--skip-ssh y --continue son incompatibles."
        log_error "  Con --skip-ssh no hay pausa de reconexion SSH;"
        log_error "  por tanto no se necesita --continue."
        log_info  "Uso correcto sin SSH hardening:"
        log_info  "  sudo bash scripts/setup.sh --skip-ssh"
        exit 1
    fi
}

# =============================================================================
# _check_prerequisites
# Verifica sudo/root, existencia de .env y variables requeridas.
# Carga .env en el entorno para que las fases puedan leerlo.
# =============================================================================
_check_prerequisites() {
    log_header "Verificando prerequisitos"

    # 1. Verificar sudo / root
    if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
        log_error "Este script requiere privilegios de root."
        log_info  "Ejecuta con: sudo bash scripts/setup.sh $*"
        exit 1
    fi
    log_info "Ejecutando como root: OK"

    # 2. Verificar que .env existe
    local env_file="${PROJECT_ROOT}/.env"
    if [[ ! -f "$env_file" ]]; then
        log_error ".env no encontrado en ${PROJECT_ROOT}"
        log_info  "Crea tu configuracion:"
        log_info  "  cp .env.example .env"
        log_info  "  nano .env   # editar DOMAIN, UI_DIST, SSL_EMAIL, SSH_PORT"
        exit 1
    fi
    log_info ".env encontrado: OK"

    # 3. Cargar .env
    set -a; source "$env_file"; set +a

    # 4. Verificar variables requeridas
    local required_vars=(DOMAIN UI_DIST SSL_EMAIL SSL_CERT_DIR SSH_PORT)
    local missing=0
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Variable requerida no definida en .env: ${var}"
            missing=$(( missing + 1 ))
        fi
    done

    if [[ "$missing" -gt 0 ]]; then
        log_error "${missing} variable(s) requerida(s) faltante(s) en .env"
        log_info  "Edita .env y completa las variables faltantes."
        exit 1
    fi
    log_info "Variables de .env: OK (DOMAIN=${DOMAIN}, SSH_PORT=${SSH_PORT})"
}

# =============================================================================
# _check_ssh_key
# Guard anti-lockout: verifica que existe al menos una clave SSH
# autorizada antes de ejecutar ssh_hardening, que desactiva la
# autenticacion por contrasena. Sin clave SSH el operador quedaria
# bloqueado fuera del servidor.
# Mismo guard que setup_ssh_hardening.sh (D-GUARD-SSH-KEY).
# =============================================================================
_check_ssh_key() {
    log_header "Guard anti-lockout: verificando clave SSH autorizada"

    local auth_keys="${HOME}/.ssh/authorized_keys"

    if [[ ! -f "$auth_keys" ]]; then
        log_error "No se encontro ${auth_keys}"
        log_error ""
        log_error "RIESGO DE LOCKOUT: setup_ssh_hardening.sh desactiva"
        log_error "la autenticacion por contrasena. Sin clave SSH"
        log_error "perderias el acceso al servidor."
        log_info  ""
        log_info  "Agrega tu clave publica antes de continuar:"
        log_info  "  mkdir -p ~/.ssh && chmod 700 ~/.ssh"
        log_info  "  echo 'ssh-ed25519 AAAA...' >> ${auth_keys}"
        log_info  "  chmod 600 ${auth_keys}"
        exit 1
    fi

    if ! grep -qE "^(ssh-|ecdsa-|sk-)" "$auth_keys" 2>/dev/null; then
        log_error "${auth_keys} existe pero no contiene claves SSH validas."
        log_error "Agrega tu clave publica antes de continuar."
        exit 1
    fi

    log_info "Clave SSH autorizada encontrada en ${auth_keys}: OK"
}

# =============================================================================
# _check_nginx_installed
# Guard para --continue: verifica que Fase 1 se ejecuto previamente.
# Si nginx no esta instalado, Fase 2 no tiene sentido.
# =============================================================================
_check_nginx_installed() {
    log_header "Guard --continue: verificando Fase 1 previa"

    if ! command_exists nginx; then
        log_error "Nginx no esta instalado."
        log_error "Fase 2 requiere que Fase 1 se haya ejecutado antes."
        log_info  "Ejecuta Fase 1 primero (sin --continue):"
        log_info  "  sudo bash scripts/setup.sh"
        exit 1
    fi
    log_info "Nginx instalado (Fase 1 confirmada): OK"
}

# =============================================================================
# _run_fase1
# Fase 1: instala Nginx y (si no se usa --skip-ssh) endurece SSH.
# Con --skip-ssh: continua directamente a Fase 2 sin pausa.
# Sin --skip-ssh: pausa obligatoria de reconexion SSH antes de Fase 2.
# =============================================================================
_run_fase1() {
    # Total de pasos depende de si se omite SSH hardening
    local _fase1_total=2
    [[ "$_SKIP_SSH" == "true" ]] && _fase1_total=1

    log_header "FASE 1 — Instalacion de Nginx"

    log_step "1" "$_fase1_total" "Nginx (provisioners/nginx/install.sh)"
    bash "${PROJECT_ROOT}/provisioners/nginx/install.sh"

    if [[ "$_SKIP_SSH" == "true" ]]; then
        log_warn "SSH hardening omitido (--skip-ssh)"
        log_info "Continuando directamente con Fase 2..."
        echo ""
        _run_fase2
        return
    fi

    log_header "FASE 1 — SSH hardening"

    log_step "2" "$_fase1_total" "SSH hardening (provisioners/security/setup_ssh_hardening.sh)"
    bash "${PROJECT_ROOT}/provisioners/security/setup_ssh_hardening.sh"

    # Pausa obligatoria de reconexion
    echo ""
    log_warn "================================================================"
    log_warn "  PAUSA OBLIGATORIA - Reconexion SSH requerida"
    log_warn "================================================================"
    log_warn ""
    log_warn "  El puerto SSH ha cambiado a: ${SSH_PORT:-2222}"
    log_warn ""
    log_warn "  1. Desde otra terminal, reconecta:"
    log_warn "       ssh -p ${SSH_PORT:-2222} ${SUDO_USER:-deploy}@<ip>"
    log_warn ""
    log_warn "  2. Una vez reconectado, ejecuta Fase 2:"
    log_warn "       sudo bash scripts/setup.sh --continue"
    log_warn ""
    log_warn "================================================================"
    echo ""

    exit 0
}

# =============================================================================
# _run_fase2
# Fase 2: firewall, fail2ban, SSL, vhosts Nginx y verificacion final.
# =============================================================================
_run_fase2() {
    log_header "FASE 2 — Firewall, fail2ban, SSL, vhosts"

    log_step "1" "5" "Firewall UFW (provisioners/firewall/setup_firewall.sh)"
    bash "${PROJECT_ROOT}/provisioners/firewall/setup_firewall.sh"

    log_step "2" "5" "fail2ban (provisioners/security/setup_fail2ban.sh)"
    bash "${PROJECT_ROOT}/provisioners/security/setup_fail2ban.sh"

    local ssl_modo="${_SSL_FLAG:-"produccion (Let's Encrypt real)"}"
    log_step "3" "5" "SSL ${ssl_modo} (provisioners/ssl/setup_ssl.sh)"
    # shellcheck disable=SC2086
    bash "${PROJECT_ROOT}/provisioners/ssl/setup_ssl.sh" ${_SSL_FLAG}

    log_step "4" "5" "Nginx vhosts (provisioners/nginx/setup_vhost.sh)"
    bash "${PROJECT_ROOT}/provisioners/nginx/setup_vhost.sh"

    log_step "5" "5" "Verificacion final (scripts/verify.sh)"
    bash "${PROJECT_ROOT}/scripts/verify.sh"

    echo ""
    log_success "================================================================"
    log_success "  Server aprovisionado correctamente."
    log_success "  Dominio: ${DOMAIN}"
    log_success "  Verifica el entorno: bash scripts/verify.sh"
    log_success "================================================================"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================
_parse_flags "$@"
_check_prerequisites "$@"

if [[ "$_CONTINUE" == "true" ]]; then
    log_header "setup.sh — Modo --continue (Fase 2)"
    _check_nginx_installed
    _run_fase2
else
    log_header "setup.sh — Fase 1"
    _check_ssh_key
    _run_fase1
fi
