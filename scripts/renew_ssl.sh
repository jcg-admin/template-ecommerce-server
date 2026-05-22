#!/bin/bash
# =============================================================================
# scripts/renew_ssl.sh
# Renueva el certificado SSL via acme.sh
# =============================================================================
# Portado del referente jcg-admin/e-comerce-server/scripts/renew_ssl.sh
# (186 LOC). Adaptaciones cosmeticas unicas: cambio de marca, comentario
# 'Apache' -> 'Nginx' en la nota del reloadcmd, ejemplo de cron usa
# PROJECT_ROOT en lugar de path hardcoded.
#
# IDEMPOTENTE: acme.sh solo renueva si el certificado tiene menos de 30
# dias de vida restante. Si tiene mas, el script termina sin hacer nada.
#
# El reload de Nginx ocurre automaticamente si acme.sh renueva -- esta
# configurado via --reloadcmd 'nginx -s reload' en provisioners/ssl/
# setup_ssl.sh F5/T-501 (no se invoca aqui directamente).
#
# Comportamiento segun el resultado de acme.sh:
#   Codigo 0  -> certificado renovado o ya vigente (acme.sh no distingue)
#   Codigo 2  -> renovacion no necesaria (cert tiene mas de 30 dias de vida)
#   Otro      -> error -- el script sale con codigo 1 para que cron notifique
#
# Cron semanal sugerido (ejecutar como root):
#   0 2 * * 1 /bin/bash /opt/template-ecomerce-ui-server/scripts/renew_ssl.sh
#
# El resultado de cada ejecucion se registra en logs/renew_ssl.log.
#
# Uso:
#   bash scripts/renew_ssl.sh
#
# Variables requeridas en .env:
#   DOMAIN, SSL_CERT_DIR, SSL_CERT_DAYS_WARN, SSL_CERT_DAYS_ERR
#
# Requiere: acme.sh instalado (provisioners/ssl/setup_ssl.sh), root para
#           el --reloadcmd 'nginx -s reload' (si acme.sh renueva).
# Modelo de cuentas (D-CUENTAS): si se invoca manual, usar `deploy`. El
# cron tipicamente se instala bajo root user directo.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export PROJECT_ROOT

source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/core.sh"
source "${PROJECT_ROOT}/utils/validation.sh"

# =============================================================================
# Cargar .env -- requerido
# =============================================================================
ENV_FILE="${PROJECT_ROOT}/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: Archivo .env no encontrado en ${PROJECT_ROOT}" >&2
    echo "  Crea tu configuracion: cp .env.example .env" >&2
    exit 1
fi
set -a; source "$ENV_FILE"; set +a

# Defaults para variables de umbral
SSL_CERT_DAYS_WARN="${SSL_CERT_DAYS_WARN:-30}"
SSL_CERT_DAYS_ERR="${SSL_CERT_DAYS_ERR:-7}"

# Inicializar log -- a partir de aqui los mensajes van a consola y al archivo
mkdir -p "${PROJECT_ROOT}/logs"
init_log "renew_ssl"

# Ruta al binario de acme.sh
ACME_CMD="${HOME}/.acme.sh/acme.sh"

# =============================================================================
# PASO: Verificar prerequisitos
# =============================================================================
_check_requisites() {
    log_header "PASO: Verificando prerequisitos"

    [[ -n "${DOMAIN:-}" ]] || {
        log_error "DOMAIN no definido en .env"
        exit 1
    }
    log_success "DOMAIN: ${DOMAIN}"

    [[ -n "${SSL_CERT_DIR:-}" ]] || {
        log_error "SSL_CERT_DIR no definido en .env"
        exit 1
    }
    log_success "SSL_CERT_DIR: ${SSL_CERT_DIR}"

    [[ -f "$ACME_CMD" ]] || {
        log_error "acme.sh no encontrado: ${ACME_CMD}"
        log_error "  Instala con: sudo bash provisioners/ssl/setup_ssl.sh"
        exit 1
    }
    log_success "acme.sh: ${ACME_CMD}"
}

# =============================================================================
# PASO: Verificar estado actual del certificado
# =============================================================================
_check_current_cert() {
    log_header "PASO: Estado actual del certificado"

    local cert_file="${SSL_CERT_DIR}/cert.pem"
    validate_ssl_cert "$cert_file" "$SSL_CERT_DAYS_WARN" "$SSL_CERT_DAYS_ERR"

    case "$SSL_CERT_STATUS" in
        OK)
            log_success "Certificado vigente"
            log_info "  acme.sh verificara si requiere renovacion"
            ;;
        WARN)
            log_warn "Certificado proximo a vencer -- renovando"
            ;;
        ERR)
            log_error "Certificado vencido o no encontrado -- intentando renovar"
            ;;
    esac
}

# =============================================================================
# PASO: Renovar certificado via acme.sh
# =============================================================================
_renew_certificate() {
    log_header "PASO: Renovando certificado para ${DOMAIN}"

    log_info "  Ejecutando: acme.sh --renew -d ${DOMAIN}"

    # acme.sh sale con codigo 2 si el cert no requiere renovacion aun.
    # Con set -euo pipefail, esto mataria el script sin || exit_code=$?
    local acme_exit=0
    "$ACME_CMD" --renew -d "${DOMAIN}" 2>>"${PROJECT_ROOT}/logs/renew_ssl.log" \
        || acme_exit=$?

    case "$acme_exit" in
        0)
            log_success "Certificado renovado correctamente"
            log_info "  Nginx recargado via --reloadcmd configurado en setup_ssl.sh"
            ;;
        2)
            log_success "Certificado no requiere renovacion aun"
            log_info "  El certificado tiene suficientes dias de vida restante"
            ;;
        *)
            log_error "acme.sh fallo con codigo ${acme_exit}"
            log_error "  Revisa el log: ${PROJECT_ROOT}/logs/renew_ssl.log"
            log_error "  O ejecuta manualmente: ${ACME_CMD} --renew -d ${DOMAIN}"
            exit 1
            ;;
    esac
}

# =============================================================================
# PASO: Verificar el certificado tras la renovacion
# =============================================================================
_verify_after_renewal() {
    log_header "PASO: Verificando certificado tras la renovacion"

    local cert_file="${SSL_CERT_DIR}/cert.pem"
    validate_ssl_cert "$cert_file" "$SSL_CERT_DAYS_WARN" "$SSL_CERT_DAYS_ERR"

    case "$SSL_CERT_STATUS" in
        OK)
            log_success "Certificado verificado -- vigente"
            ;;
        WARN)
            log_warn "Certificado proximo a vencer -- puede que la renovacion no funciono"
            log_warn "  Revisa: ${PROJECT_ROOT}/logs/renew_ssl.log"
            ;;
        ERR)
            log_error "Certificado en estado ERR tras la renovacion"
            log_error "  Revisa: ${PROJECT_ROOT}/logs/renew_ssl.log"
            exit 1
            ;;
    esac
}

# =============================================================================
# MAIN
# =============================================================================
log_header "Renovacion de certificado SSL -- template-ecomerce-ui-server"
log_info "  Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

_check_requisites;     echo ""
_check_current_cert;   echo ""
_renew_certificate;    echo ""
_verify_after_renewal; echo ""

log_separator 60 "="
log_success "Proceso de renovacion completado."
log_info "  Log completo: ${PROJECT_ROOT}/logs/renew_ssl.log"
