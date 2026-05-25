#!/bin/bash
# =============================================================================
# scripts/start.sh
# Arranca los daemons del servidor en entornos sin systemd
# =============================================================================
# En entornos con systemd (VPS de produccion), los daemons arrancan
# automaticamente al boot. Este script es util en entornos sin systemd:
# WSL2 sin systemd=true, contenedores, CI runners.
#
# En entornos con systemd, el script detecta que los daemons ya estan
# activos y sale sin hacer nada (idempotente).
#
# Daemons gestionados:
#   1. Nginx    -- via svc_start de utils/core.sh
#   2. fail2ban -- via svc_start de utils/core.sh
#
# Daemons excluidos intencionalmente:
#   sshd -- en WSL2 lo gestiona Windows; en produccion el init del VPS.
#
# Requiere:
#   sudo o root (arrancar daemons requiere privilegios de sistema).
#   Los provisioners deben haberse ejecutado previamente (setup.sh).
#
# Uso:
#   sudo bash scripts/start.sh
#
# Idempotente: seguro de ejecutar multiples veces.
# Si un daemon ya esta activo, se omite sin error.
#
# Iniciativa: INI-SRV-006 crear-start-sh (PROC-GESTION-001 v4.0.0)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export PROJECT_ROOT

source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/core.sh"

# =============================================================================
# _start_daemon <nombre>
#   Arranca un daemon si no esta corriendo. Idempotente.
#
#   Flujo:
#     1. Verificar que el daemon este instalado (command_exists).
#        Si no: WARN y retornar 0 (no aborta; el otro daemon puede estar bien).
#     2. Verificar si ya esta activo (svc_is_active).
#        Si si: INFO y retornar 0.
#     3. Arrancar (svc_start).
#     4. Esperar 1 segundo para que el daemon se inicialice.
#     5. Verificar post-arranque (svc_is_active).
#        Si falla: ERROR y retornar 1.
#
#   Retorna:
#     0 si el daemon quedo activo (o ya lo estaba, o no esta instalado).
#     1 si el arranque fallo.
# =============================================================================
_start_daemon() {
    local name="$1"
    local _failed=0

    log_header "Daemon: ${name}"

    # 1. Verificar instalacion
    if ! command_exists "${name}"; then
        log_warn "  ${name} no esta instalado -- omitiendo"
        log_warn "  Ejecuta el provisioner correspondiente antes de usar start.sh"
        return 0
    fi

    # 2. Verificar si ya esta activo
    if svc_is_active "${name}" 2>/dev/null; then
        log_info  "  ${name}: ya activo -- omitiendo"
        return 0
    fi

    # 3. Arrancar
    log_info "  ${name}: arrancando..."
    if ! svc_start "${name}" 2>/dev/null; then
        log_error "  ${name}: fallo al arrancar"
        return 1
    fi

    # 4. Dar tiempo al daemon para inicializarse o fallar (R-1)
    sleep 1

    # 5. Verificacion post-arranque
    if svc_is_active "${name}" 2>/dev/null; then
        log_success "  ${name}: activo"
    else
        log_error "  ${name}: arranco pero no esta activo"
        log_error "  Verifica los logs del daemon para diagnosticar el problema."
        _failed=1
    fi

    return "${_failed}"
}

# =============================================================================
# MAIN
# =============================================================================
log_header "start.sh -- Arranque de daemons"

# Verificar sudo / root
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    log_error "Este script requiere privilegios de root."
    log_info  "Ejecuta con: sudo bash scripts/start.sh"
    exit 1
fi

# Arrancar en orden: nginx primero, fail2ban despues.
# El orden importa: las jails nginx-* de fail2ban monitorizan
# los logs de nginx (D-NO-SSHD: sshd excluido intencionalmente).
_nginx_ok=0
_fail2ban_ok=0

_start_daemon nginx    || _nginx_ok=1
echo ""
_start_daemon fail2ban || _fail2ban_ok=1
echo ""

# Resumen final
log_header "Resumen"
if [[ "${_nginx_ok}" -eq 0 ]]; then
    log_success "  nginx:    OK"
else
    log_error   "  nginx:    FALLO"
fi
if [[ "${_fail2ban_ok}" -eq 0 ]]; then
    log_success "  fail2ban: OK"
else
    log_error   "  fail2ban: FALLO"
fi
echo ""

if [[ "${_nginx_ok}" -eq 1 || "${_fail2ban_ok}" -eq 1 ]]; then
    log_error "Uno o mas daemons no pudieron arrancarse."
    log_info  "Ejecuta: bash scripts/verify.sh para un diagnostico completo."
    exit 1
fi

log_success "Todos los daemons activos."
log_info    "Ejecuta: bash scripts/verify.sh para verificar el entorno completo."
