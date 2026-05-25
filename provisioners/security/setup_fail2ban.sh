#!/bin/bash
# =============================================================================
# provisioners/security/setup_fail2ban.sh
# Instala y configura fail2ban con jails de Nginx + SSH
# =============================================================================
# Portado del referente jcg-admin/e-comerce-server/provisioners/security/
# setup_fail2ban.sh (356 LOC) con adaptaciones a Nginx documentadas en
# progreso F6 (4 hallazgos de inspeccion previa al codigo).
#
# IDEMPOTENTE: si fail2ban ya esta activo con la configuracion correcta
# y las jails corriendo, no hace nada.
#
# Jails configuradas (3, vs 2 en el referente):
#
#   sshd:                Monitorea /var/log/auth.log.
#                        Banea IPs con intentos fallidos de auth SSH.
#                        Variables: F2B_SSH_MAXRETRY, _FINDTIME, _BANTIME
#                        Defaults:  5 intentos / 600 s / 3600 s (1 hora)
#
#   nginx-limit-req:     Monitorea el error_log de Nginx HTTPS.
#                        Banea IPs que generan 503 (rate-limit excedido).
#                        Filtro provisto por el paquete fail2ban de Ubuntu.
#                        Variables: F2B_NGINX_LIMIT_REQ_MAXRETRY, _FINDTIME,
#                                   _BANTIME
#                        Defaults:  10 intentos / 600 s / 1800 s (30 min)
#
#   nginx-botsearch:     Monitorea los access logs de Nginx.
#                        Banea IPs que prueban paths conocidos de scanners
#                        (wp-admin, phpmyadmin, xmlrpc.php, .git, .env).
#                        Filtro provisto por el paquete fail2ban de Ubuntu.
#                        Variables: F2B_NGINX_BOTSEARCH_MAXRETRY, _FINDTIME,
#                                   _BANTIME
#                        Defaults:  2 intentos / 600 s / 86400 s (24 horas)
#
# El banaction usa UFW -- consistente con el firewall del servidor
# (provisioners/firewall/setup_firewall.sh en F7). Las IPs baneadas se
# anaden como reglas de denegacion en UFW y se eliminan automaticamente
# al expirar el ban.
#
# Uso:
#   sudo bash provisioners/security/setup_fail2ban.sh
#
# Variables opcionales en .env (con defaults seguros):
#   SSH_PORT
#   F2B_SSH_MAXRETRY, F2B_SSH_FINDTIME, F2B_SSH_BANTIME
#   F2B_NGINX_LIMIT_REQ_MAXRETRY, _FINDTIME, _BANTIME
#   F2B_NGINX_BOTSEARCH_MAXRETRY, _FINDTIME, _BANTIME
#
# Requiere: root, Ubuntu 24.04, apt.
# Modelo de cuentas (D-CUENTAS): invocar como `deploy` (UID 1000).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
export PROJECT_ROOT

source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/core.sh"
source "${PROJECT_ROOT}/utils/validation.sh"

init_log "operations"

# =============================================================================
# Cargar .env (opcional -- las variables tienen defaults seguros)
# =============================================================================
ENV_FILE="${PROJECT_ROOT}/.env"
[[ -f "$ENV_FILE" ]] && { set -a; source "$ENV_FILE"; set +a; }

# Valores con defaults seguros
SSH_PORT="${SSH_PORT:-22}"
F2B_SSH_MAXRETRY="${F2B_SSH_MAXRETRY:-5}"
F2B_SSH_FINDTIME="${F2B_SSH_FINDTIME:-600}"
F2B_SSH_BANTIME="${F2B_SSH_BANTIME:-3600}"
F2B_NGINX_LIMIT_REQ_MAXRETRY="${F2B_NGINX_LIMIT_REQ_MAXRETRY:-10}"
F2B_NGINX_LIMIT_REQ_FINDTIME="${F2B_NGINX_LIMIT_REQ_FINDTIME:-600}"
F2B_NGINX_LIMIT_REQ_BANTIME="${F2B_NGINX_LIMIT_REQ_BANTIME:-1800}"
F2B_NGINX_BOTSEARCH_MAXRETRY="${F2B_NGINX_BOTSEARCH_MAXRETRY:-2}"
F2B_NGINX_BOTSEARCH_FINDTIME="${F2B_NGINX_BOTSEARCH_FINDTIME:-600}"
F2B_NGINX_BOTSEARCH_BANTIME="${F2B_NGINX_BOTSEARCH_BANTIME:-86400}"

# Ruta del archivo de configuracion de jails
readonly JAIL_CONF="/etc/fail2ban/jail.d/template-ecommerce-server.conf"

# Logs de Nginx (configurados en config/nginx/template-*.conf F3)
readonly NGINX_HTTP_ACCESS_LOG="/var/log/nginx/template-http-access.log"
readonly NGINX_HTTPS_ACCESS_LOG="/var/log/nginx/template-https-access.log"
readonly NGINX_HTTPS_ERROR_LOG="/var/log/nginx/template-https-error.log"

# Lista de jails para iteracion (factorizada vs hardcoded del referente)
readonly JAILS=("sshd" "nginx-limit-req" "nginx-botsearch")

# =============================================================================
# Genera el contenido esperado del archivo de jails
# La salida se usa tanto para escribir como para comparar (idempotencia)
# =============================================================================
_generate_jail_conf() {
    cat << JAILEOF
# ${JAIL_CONF}
# Generado por provisioners/security/setup_fail2ban.sh
# No editar manualmente -- ejecutar setup_fail2ban.sh para aplicar cambios.

[DEFAULT]
# banaction = ufw: las IPs baneadas se agregan como reglas de denegacion
# en UFW. Consistente con el firewall del servidor (setup_firewall.sh F7).
banaction = ufw

[sshd]
enabled  = true
port     = ${SSH_PORT}
filter   = sshd
logpath  = /var/log/auth.log
maxretry = ${F2B_SSH_MAXRETRY}
findtime = ${F2B_SSH_FINDTIME}
bantime  = ${F2B_SSH_BANTIME}

[nginx-limit-req]
# Banea IPs que generan errores 503 por sobrepasar limit_req del vhost.
# Lee del error_log de Nginx (donde aparecen los 503), no del access_log.
enabled  = true
port     = http,https
filter   = nginx-limit-req
logpath  = ${NGINX_HTTPS_ERROR_LOG}
maxretry = ${F2B_NGINX_LIMIT_REQ_MAXRETRY}
findtime = ${F2B_NGINX_LIMIT_REQ_FINDTIME}
bantime  = ${F2B_NGINX_LIMIT_REQ_BANTIME}

[nginx-botsearch]
# Banea IPs que prueban paths conocidos de scanners (wp-admin, phpmyadmin,
# xmlrpc.php, .git, .env). Complementa el deny block en template-https.conf.
# Lee de ambos access logs (HTTP y HTTPS) porque los bots prueban por los
# dos puertos.
enabled  = true
port     = http,https
filter   = nginx-botsearch
logpath  = ${NGINX_HTTP_ACCESS_LOG}
           ${NGINX_HTTPS_ACCESS_LOG}
maxretry = ${F2B_NGINX_BOTSEARCH_MAXRETRY}
findtime = ${F2B_NGINX_BOTSEARCH_FINDTIME}
bantime  = ${F2B_NGINX_BOTSEARCH_BANTIME}
JAILEOF
}

# =============================================================================
# PASO: Verificar requisitos
# =============================================================================
_check_requisites() {
    log_header "PASO: Verificando requisitos"

    validate_root || {
        log_error "  Ejecuta con: sudo bash provisioners/security/setup_fail2ban.sh"
        exit 1
    }
    log_success "Corriendo como root"

    command_exists apt-get || {
        log_error "apt-get no encontrado -- se requiere Ubuntu/Debian"
        exit 1
    }
    log_success "apt disponible"
}

# =============================================================================
# PASO: Verificar estado actual (idempotencia)
# =============================================================================
_check_current_state() {
    log_header "PASO: Estado actual de fail2ban"

    # Si fail2ban no esta instalado, continuar con la instalacion
    if ! command_exists fail2ban-client; then
        log_info "fail2ban no instalado -- se instalara"
        return 0
    fi

    # Si el archivo de configuracion no existe, continuar
    if [[ ! -f "$JAIL_CONF" ]]; then
        log_info "Configuracion no encontrada -- se creara"
        return 0
    fi

    # Comparar configuracion esperada con la actual
    local expected
    expected=$(_generate_jail_conf)
    local current
    current=$(cat "$JAIL_CONF")

    if [[ "$expected" != "$current" ]]; then
        log_info "Configuracion desactualizada -- se aplicara"
        return 0
    fi

    # Sin systemd: no podemos validar daemon corriendo. Si la config
    # coincide y fail2ban-client -d es OK, declaramos idempotente.
    if ! is_systemd; then
        if fail2ban-client -d >/dev/null 2>&1; then
            log_success "Configuracion correcta y sintaxis OK -- sin cambios (sin systemd)"
            log_info "  Arranque manual del daemon: fail2ban-server -b"
            exit 0
        fi
        log_info "Configuracion presente pero fail2ban-client -d advirtio -- se reescribira"
        return 0
    fi

    # Configuracion correcta -- verificar que el servicio este activo
    if ! svc_is_active fail2ban; then
        log_info "Configuracion correcta pero servicio inactivo -- se activara"
        return 0
    fi

    # Verificar que las jails esten corriendo
    local jails_ok=true
    for jail in "${JAILS[@]}"; do
        if ! fail2ban-client status "$jail" &>/dev/null; then
            log_info "Jail '${jail}' no activa -- se activara"
            jails_ok=false
            break
        fi
    done

    if [[ "$jails_ok" == "true" ]]; then
        log_success "fail2ban activo con configuracion y jails correctas -- sin cambios"
        for jail in "${JAILS[@]}"; do
            log_success "  Jail ${jail}: activa"
        done
        exit 0
    fi
}

# =============================================================================
# PASO: Instalar fail2ban
# =============================================================================
_install_fail2ban() {
    log_header "PASO: Instalando fail2ban"

    if command_exists fail2ban-client; then
        log_success "fail2ban ya instalado: $(fail2ban-client --version 2>/dev/null | head -1)"
        return 0
    fi

    log_info "  Actualizando indice de paquetes..."
    DEBIAN_FRONTEND=noninteractive apt-get update -qq 2>/dev/null || \
        log_warn "  apt-get update retorno error -- continuando"

    log_info "  Instalando fail2ban..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        fail2ban > /dev/null || {
        log_error "No se pudo instalar fail2ban"
        exit 1
    }

    log_success "fail2ban instalado: $(fail2ban-client --version 2>/dev/null | head -1)"
}

# =============================================================================
# PASO: Escribir configuracion de jails
# =============================================================================
_write_jail_conf() {
    log_header "PASO: Escribiendo configuracion de jails"

    # Crear el directorio si no existe
    mkdir -p /etc/fail2ban/jail.d

    # Generar y escribir la configuracion
    _generate_jail_conf > "$JAIL_CONF"
    log_success "Configuracion escrita: ${JAIL_CONF}"

    log_info "  Jail sshd:"
    log_info "    Puerto:    ${SSH_PORT}/tcp"
    log_info "    Log:       /var/log/auth.log"
    log_info "    Max retry: ${F2B_SSH_MAXRETRY} intentos en ${F2B_SSH_FINDTIME}s"
    log_info "    Ban:       ${F2B_SSH_BANTIME}s"

    log_info "  Jail nginx-limit-req:"
    log_info "    Log:       ${NGINX_HTTPS_ERROR_LOG}"
    log_info "    Max retry: ${F2B_NGINX_LIMIT_REQ_MAXRETRY} intentos en ${F2B_NGINX_LIMIT_REQ_FINDTIME}s"
    log_info "    Ban:       ${F2B_NGINX_LIMIT_REQ_BANTIME}s"

    log_info "  Jail nginx-botsearch:"
    log_info "    Logs:      ${NGINX_HTTP_ACCESS_LOG}"
    log_info "               ${NGINX_HTTPS_ACCESS_LOG}"
    log_info "    Max retry: ${F2B_NGINX_BOTSEARCH_MAXRETRY} intentos en ${F2B_NGINX_BOTSEARCH_FINDTIME}s"
    log_info "    Ban:       ${F2B_NGINX_BOTSEARCH_BANTIME}s (24h por defecto -- bots reincidentes)"
}

# =============================================================================
# PASO: Habilitar y arrancar fail2ban
# =============================================================================
_enable_fail2ban() {
    log_header "PASO: Activando fail2ban"

    # Habilitar inicio automatico (solo aplica con systemd)
    svc_enable fail2ban

    # Sin systemd (contenedor / CI): fail2ban depende de UFW y de los logs
    # de Nginx/SSH que pueden no existir aun. En lugar de fallar, validamos
    # la sintaxis con fail2ban-client -d y dejamos el arranque documentado.
    if ! is_systemd; then
        log_warn "  Sin systemd detectado -- omitiendo arranque del daemon."
        if fail2ban-client -d >/dev/null 2>&1; then
            log_success "  Configuracion valida (fail2ban-client -d OK)"
        else
            log_warn "  fail2ban-client -d reporto advertencias -- revisa la salida"
        fi
        log_manual_start fail2ban "fail2ban-server -b"
        return 0
    fi

    # Arrancar o reiniciar segun el estado actual
    if svc_is_active fail2ban; then
        log_info "  Reiniciando fail2ban para aplicar nueva configuracion..."
        svc_restart fail2ban || {
            log_error "No se pudo reiniciar fail2ban"
            log_error "  Revisa la configuracion: fail2ban-client -d"
            exit 1
        }
        log_success "fail2ban reiniciado"
    else
        log_info "  Arrancando fail2ban..."
        svc_start fail2ban || {
            log_error "No se pudo arrancar fail2ban"
            log_error "  Revisa la configuracion: fail2ban-client -d"
            exit 1
        }
        log_success "fail2ban arrancado"
    fi
}

# =============================================================================
# PASO: Verificar que las jails estan activas
# =============================================================================
_verify_jails() {
    log_header "PASO: Verificando jails"

    # Sin systemd no hay daemon corriendo -- saltar verificacion de runtime.
    if ! is_systemd; then
        log_info "  Sin systemd -- omitiendo verificacion runtime de jails."
        log_info "  En el host con systemd:"
        for jail in "${JAILS[@]}"; do
            log_info "    fail2ban-client status ${jail}"
        done
        return 0
    fi

    # fail2ban puede tardar unos segundos en inicializar las jails
    local retries=5
    local i=0
    while (( i < retries )); do
        if fail2ban-client status &>/dev/null; then
            break
        fi
        i=$(( i + 1 ))
        log_info "  Esperando que fail2ban inicialice... (${i}/${retries})"
        sleep 2
    done

    local all_ok=true
    for jail in "${JAILS[@]}"; do
        if fail2ban-client status "$jail" &>/dev/null; then
            log_success "  Jail '${jail}': activa"
        else
            log_error "  Jail '${jail}': NO activa"
            all_ok=false
        fi
    done

    if [[ "$all_ok" == "false" ]]; then
        log_error "Una o mas jails no estan activas"
        log_error "  Diagnostico: fail2ban-client -d"
        log_error "  Logs: journalctl -u fail2ban --no-pager | tail -20"
        exit 1
    fi
}

# =============================================================================
# MAIN
# =============================================================================
log_header "Configuracion de fail2ban -- template-ecommerce-server"
log_info "  SSH_PORT:                      ${SSH_PORT}"
log_info "  sshd:              ${F2B_SSH_MAXRETRY}/${F2B_SSH_FINDTIME}s/${F2B_SSH_BANTIME}s"
log_info "  nginx-limit-req:   ${F2B_NGINX_LIMIT_REQ_MAXRETRY}/${F2B_NGINX_LIMIT_REQ_FINDTIME}s/${F2B_NGINX_LIMIT_REQ_BANTIME}s"
log_info "  nginx-botsearch:   ${F2B_NGINX_BOTSEARCH_MAXRETRY}/${F2B_NGINX_BOTSEARCH_FINDTIME}s/${F2B_NGINX_BOTSEARCH_BANTIME}s"
echo ""

_check_requisites;    echo ""
_check_current_state; echo ""
_install_fail2ban;    echo ""
_write_jail_conf;     echo ""
_enable_fail2ban;     echo ""
_verify_jails;        echo ""

log_separator 60 "="
log_success "fail2ban configurado. Jails activas: ${JAILS[*]}"
echo ""
log_info "Operaciones comunes:"
log_info "  Estado:                     sudo fail2ban-client status"
log_info "  Estado jail SSH:            sudo fail2ban-client status sshd"
log_info "  Estado jail nginx-limit:    sudo fail2ban-client status nginx-limit-req"
log_info "  Estado jail nginx-bot:      sudo fail2ban-client status nginx-botsearch"
log_info "  Desbanear IP:               sudo fail2ban-client set <jail> unbanip <IP>"
log_info "  Logs:                       sudo journalctl -u fail2ban"
log_info "  Verificar:                  bash scripts/verify.sh"
