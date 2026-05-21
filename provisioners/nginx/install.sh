#!/bin/bash
# =============================================================================
# provisioners/nginx/install.sh
# Instala Nginx 1.24+ o migra desde una version incorrecta
# =============================================================================
# IDEMPOTENTE: si Nginx >= 1.24 ya esta instalado, no hace nada.
#
# Escenarios:
#   A) Nginx no instalado          -> instala Nginx desde apt
#   B) Nginx >= 1.24 instalado     -> no hace nada -> OK
#   C) Version inferior a 1.24     -> backup /etc/nginx/ -> purga -> instala
#
# Diferencia clave vs el referente Apache:
#   Apache requiere a2enmod ssl/wsgi/headers/rewrite. Nginx en Ubuntu
#   24.04 trae ssl, http_v2, http_realip, gzip, etc. compilados en core.
#   No hay paso _ensure_modules_active.
#
# Nginx tampoco necesita libapache2-mod-wsgi-py3 (D-WS + D-BACKEND-
# AGNOSTIC: este server no embebe ningun backend).
#
# Uso:
#   sudo bash provisioners/nginx/install.sh
#
# Requiere: root, Ubuntu 24.04, apt.
#
# Modelo de cuentas (D-CUENTAS):
#   Invocar como cuenta `deploy` (UID 1000) con sudo. Las cuentas
#   `infra`, `develop`, `svc-backups` no pueden ejecutar este script
#   (la primera no tiene `bash` en su whitelist NOPASSWD; las otras
#   no tienen sudo).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
export PROJECT_ROOT

source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/core.sh"
source "${PROJECT_ROOT}/utils/network.sh"
source "${PROJECT_ROOT}/utils/validation.sh"

readonly NGINX_TARGET_MAJOR="1"
readonly NGINX_TARGET_MINOR="24"
readonly NGINX_TARGET_SERIES="${NGINX_TARGET_MAJOR}.${NGINX_TARGET_MINOR}"

# Paquetes apt a instalar (Nginx core en Ubuntu 24.04)
readonly NGINX_PACKAGES=("nginx")

# Paquetes a purgar si la version instalada no cumple
readonly NGINX_PURGE_PACKAGES=("nginx" "nginx-common" "nginx-core"
                              "nginx-extras" "nginx-full" "nginx-light")

# =============================================================================
# Helpers de apt -- privados, solo para este script
# =============================================================================
_apt_install() {
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

_apt_purge() {
    DEBIAN_FRONTEND=noninteractive apt-get purge -y "$@" 2>/dev/null || true
}

# =============================================================================
# Detectar la version de Nginx instalada
# Retorna "major.minor.patch" (ej: "1.24.0") o cadena vacia si no esta
# instalado.
#
# Nginx escribe la version a stderr, no stdout (a diferencia de Apache).
# =============================================================================
_detect_installed_version() {
    local version_str
    version_str=$(nginx -v 2>&1 \
        | grep -oE 'nginx/[0-9]+\.[0-9]+\.[0-9]+' \
        | head -1)
    [[ -z "$version_str" ]] && echo "" && return
    echo "$version_str" | cut -d/ -f2
}

# =============================================================================
# Comparar version instalada vs target. Retorna 0 si cumple
# (instalada >= target), 1 si no.
# =============================================================================
_version_meets_target() {
    local installed="$1"
    [[ -z "$installed" ]] && return 1

    local installed_major installed_minor
    installed_major=$(echo "$installed" | cut -d. -f1)
    installed_minor=$(echo "$installed" | cut -d. -f2)

    if (( installed_major > NGINX_TARGET_MAJOR )); then
        return 0
    fi
    if (( installed_major == NGINX_TARGET_MAJOR )) \
       && (( installed_minor >= NGINX_TARGET_MINOR )); then
        return 0
    fi
    return 1
}

# =============================================================================
# PASO: Verificar requisitos
# =============================================================================
_check_requisites() {
    log_header "PASO: Verificando requisitos"

    validate_root || {
        log_error "  Ejecuta con: sudo bash provisioners/nginx/install.sh"
        exit 1
    }
    log_success "Corriendo como root"

    validate_ubuntu "24.04" || {
        log_error "  Se requiere Ubuntu 24.04"
        exit 1
    }
    log_success "Ubuntu 24.04 confirmado"

    command_exists apt-get || {
        log_error "apt-get no encontrado -- se requiere Ubuntu/Debian"
        exit 1
    }
    log_success "apt disponible"

    # Acceso a internet -- necesario para descargar paquetes
    if ! tcp_is_reachable "archive.ubuntu.com" 80 5; then
        log_warn "Sin acceso a archive.ubuntu.com:80"
        log_warn "  Si los paquetes estan en cache local puede continuar"
    else
        log_success "Acceso a archive.ubuntu.com"
    fi
}

# =============================================================================
# PASO: Detectar version instalada y decidir escenario
# =============================================================================
_check_current_version() {
    log_header "PASO: Detectando version instalada"

    local installed_version
    installed_version=$(_detect_installed_version)

    if [[ -z "$installed_version" ]]; then
        log_info "Nginx no instalado -- instalacion desde cero (Escenario A)"
        return 0
    fi

    log_info "Instalado: Nginx ${installed_version}"

    if _version_meets_target "$installed_version"; then
        log_success "Nginx ${installed_version} cumple el minimo ${NGINX_TARGET_SERIES}.x"
        log_info "  (Escenario B: ya correcto)"
        echo ""
        log_separator 60 "="
        log_success "Nginx ${installed_version} ya instalado. Sin cambios."
        echo ""
        log_info "Siguientes pasos:"
        log_info "  Activar virtualhosts:"
        log_info "    sudo bash provisioners/nginx/setup_vhost.sh"
        exit 0
    fi

    # Version inferior a 1.24 -- Escenario C
    log_warn "Version instalada: Nginx ${installed_version}"
    log_warn "  Se requiere: Nginx ${NGINX_TARGET_SERIES}.x+"
    log_warn "  Nginx no almacena datos del proyecto -- se purgara e instalara"
}

# =============================================================================
# PASO: Backup de configuracion antes de purgar
# Guarda en backups/ del repositorio (no en /tmp/ que se pierde al reiniciar).
#
# En produccion WSL2 este directorio ${PROJECT_ROOT}/backups es un bind-
# mount a /srv/backups/project (Clase B, owner svc-backups), no un
# directorio dentro del .vhdx de codigo (Clase A). Asi 'git clean -fdx'
# no puede destruir los backups.
# =============================================================================
_backup_nginx_config() {
    log_header "PASO: Backup de configuracion Nginx"

    local backup_dir="${PROJECT_ROOT}/backups"
    local backup_file="${backup_dir}/nginx-config-$(date +%Y%m%d_%H%M%S).tar.gz"

    if [[ ! -d /etc/nginx ]]; then
        log_info "  /etc/nginx no existe -- no hay configuracion que respaldar"
        return 0
    fi

    mkdir -p "$backup_dir"
    if tar -czf "$backup_file" /etc/nginx/ 2>/dev/null; then
        log_success "Backup creado: ${backup_file}"
    else
        log_warn "No se pudo crear el backup de /etc/nginx/"
        log_warn "  Continuando sin backup -- la instalacion es segura"
    fi
}

# =============================================================================
# PASO: Purgar version incorrecta (Escenario C)
# =============================================================================
_purge_wrong_version() {
    log_header "PASO: Purgando version incorrecta de Nginx"

    # Detener el servicio si esta corriendo
    if svc_is_active nginx; then
        log_info "  Deteniendo Nginx..."
        svc_stop nginx || true
    fi

    # Purgar todos los paquetes nginx relacionados
    _apt_purge "${NGINX_PURGE_PACKAGES[@]}" > /dev/null
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y > /dev/null 2>&1 || true

    log_success "Version incorrecta purgada"
}

# =============================================================================
# PASO: Instalar Nginx
# =============================================================================
_install_nginx() {
    log_header "PASO: Instalando Nginx (target: ${NGINX_TARGET_SERIES}.x+)"

    log_info "  Actualizando indice de paquetes..."
    DEBIAN_FRONTEND=noninteractive apt-get update -qq 2>/dev/null \
        || log_warn "  apt-get update retorno error -- continuando"

    log_info "  Instalando ${NGINX_PACKAGES[*]}..."
    if ! _apt_install "${NGINX_PACKAGES[@]}" > /dev/null; then
        log_error "No se pudo instalar nginx"
        exit 1
    fi

    log_success "Nginx instalado"

    # Habilitar inicio automatico al boot
    log_info "  Habilitando inicio automatico..."
    svc_enable nginx

    # Arrancar el servicio
    if ! svc_is_active nginx; then
        log_info "  Arrancando Nginx..."
        svc_start nginx || {
            log_error "No se pudo arrancar Nginx"
            log_error "  Revisa: journalctl -u nginx -n 50"
            exit 1
        }
    fi

    log_success "Servicio nginx activo"
}

# =============================================================================
# PASO: Verificar instalacion
# =============================================================================
_verify_installation() {
    log_header "PASO: Verificando instalacion"

    # validate_nginx_version (de utils/validation.sh) consulta nginx -v
    if validate_nginx_version "$NGINX_TARGET_MAJOR" "$NGINX_TARGET_MINOR"; then
        local version_str
        version_str=$(_detect_installed_version)
        log_success "Nginx ${version_str} instalado correctamente"
    else
        log_error "La verificacion de version fallo tras la instalacion"
        log_error "  apt instalo una version inferior al minimo esperado"
        log_error "  Verifica: nginx -v"
        exit 1
    fi

    # Validar que la config por defecto no tiene errores
    if nginx -t >/dev/null 2>&1; then
        log_success "Config Nginx valida (nginx -t)"
    else
        log_warn "nginx -t reporta errores en la config por defecto:"
        nginx -t 2>&1 | sed 's/^/  /'
        log_warn "  Esto NO bloquea la instalacion; setup_vhost.sh aplicara"
        log_warn "  la config del repo y validara antes de recargar."
    fi

    # Comprobar que escucha en :80 (default Ubuntu vhost)
    if tcp_is_reachable 127.0.0.1 80 3; then
        log_success "Nginx escuchando en :80"
    else
        log_warn "Nginx NO escuchando en :80 todavia"
        log_warn "  Sin systemd o tras boot reciente puede tardar unos segundos"
    fi
}

# =============================================================================
# MAIN
# =============================================================================
log_header "Instalacion Nginx -- template-ecomerce-ui-server"
log_info "  Objetivo: Nginx ${NGINX_TARGET_SERIES}.x+ (sin mod_wsgi, D-WS)"
echo ""

_check_requisites;      echo ""
_check_current_version; echo ""

# Si llegamos aqui: Escenario A (no instalado) o C (version incorrecta)
installed_version=$(_detect_installed_version)
if [[ -n "$installed_version" ]] && ! _version_meets_target "$installed_version"; then
    _backup_nginx_config; echo ""
    _purge_wrong_version; echo ""
fi

_install_nginx;       echo ""
_verify_installation; echo ""

log_separator 60 "="
log_success "Nginx instalado y arrancado."
echo ""
log_info "Siguientes pasos:"
log_info "  Configurar firewall:"
log_info "    sudo bash provisioners/firewall/setup_firewall.sh"
log_info "  Configurar fail2ban:"
log_info "    sudo bash provisioners/security/setup_fail2ban.sh"
log_info "  Endurecer SSH (CON CUIDADO):"
log_info "    sudo bash provisioners/security/setup_ssh_hardening.sh"
log_info "  Obtener certificado SSL:"
log_info "    sudo bash provisioners/ssl/setup_ssl.sh"
log_info "  Activar virtualhosts (DESPUES de SSL):"
log_info "    sudo bash provisioners/nginx/setup_vhost.sh"
log_info "  Verificar entorno:"
log_info "    bash scripts/verify.sh"
