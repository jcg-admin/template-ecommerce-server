#!/bin/bash
# =============================================================================
# provisioners/nginx/setup_vhost.sh
# Activa los virtualhosts en Nginx
# =============================================================================
# Lee variables de .env, sustituye placeholders %%VAR%% en los templates
# config/nginx/template-*.conf, los copia a /etc/nginx/sites-available/,
# crea symlinks en sites-enabled/, valida con `nginx -t` y recarga.
#
# Proceso: COPIAR -> SUSTITUIR -> VERIFICAR -> ENLAZAR -> nginx -t -> reload
#
# Por que se copia en lugar de symlink al template:
#   Los archivos template tienen placeholders %%VARIABLE%% que Nginx no
#   parsea. Nginx requiere archivos con valores reales en
#   /etc/nginx/sites-available/. Un symlink al template provocaria un
#   error en `nginx -t` y el server no recargaria.
#
# Verificacion previa a la activacion:
#   `nginx -t` valida la sintaxis del CONJUNTO de configs activas antes
#   de recargar. Si falla, el script revierte (quita symlinks + elimina
#   archivos generados + restaura `default` si estaba activo) y sale
#   con codigo 1 sin tocar el servidor en produccion.
#
# Manejo de API_UPSTREAM vacio:
#   Si la variable esta vacia o no esta seteada en .env, comentar el
#   bloque `location ^~ /api/ { ... }` entero al generar el config
#   final. Asi el server queda sirviendo UI estatico unicamente. Si el
#   operador completa API_UPSTREAM despues, re-ejecutar este script
#   activa el bloque.
#
# Uso:
#   sudo bash provisioners/nginx/setup_vhost.sh
#
# Variables requeridas en .env:
#   DOMAIN, UI_DIST, SSL_CERT_DIR
#
# Variables opcionales en .env:
#   API_UPSTREAM  (vacio -> /api/ devuelve 502 hasta que se configure)
#
# Requiere: root, Nginx instalado (provisioners/nginx/install.sh).
# Requiere: SSL configurado (provisioners/ssl/setup_ssl.sh) para que
# nginx -t no falle al cargar ssl_certificate.
#
# Modelo de cuentas (D-CUENTAS):
#   Invocar como cuenta `deploy` (UID 1000) con sudo.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
export PROJECT_ROOT

source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/core.sh"
source "${PROJECT_ROOT}/utils/validation.sh"

init_log "operations"

# Nombres canonicos de los vhosts en Nginx sites-available
readonly VHOST_HTTP_NAME="template-http.conf"
readonly VHOST_HTTPS_NAME="template-https.conf"

readonly SITES_AVAILABLE="/etc/nginx/sites-available"
readonly SITES_ENABLED="/etc/nginx/sites-enabled"
readonly DEFAULT_VHOST="default"  # default vhost de Ubuntu

# Path canonico para el challenge ACME (mismo que template-*-http.conf)
readonly ACME_CHALLENGE_DIR="/var/www/acme-challenge"

# =============================================================================
# Cargar .env -- requerido
# =============================================================================
ENV_FILE="${PROJECT_ROOT}/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    log_error "Archivo .env no encontrado en ${PROJECT_ROOT}"
    log_error "  Crea tu configuracion: cp .env.example .env"
    exit 1
fi
set -a; source "$ENV_FILE"; set +a

# =============================================================================
# PASO: Verificar prerequisitos y variables
# =============================================================================
_check_required_vars() {
    log_header "PASO: Verificando prerequisitos"

    validate_root || {
        log_error "  Ejecuta con: sudo bash provisioners/nginx/setup_vhost.sh"
        exit 1
    }
    log_success "Corriendo como root"

    command_exists nginx || {
        log_error "nginx no encontrado -- instala primero:"
        log_error "  sudo bash provisioners/nginx/install.sh"
        exit 1
    }
    log_success "Nginx instalado"

    # Variables requeridas (API_UPSTREAM NO esta aqui: es opcional)
    local missing=()
    for var in DOMAIN UI_DIST SSL_CERT_DIR; do
        [[ -z "${!var:-}" ]] && missing+=("$var")
    done

    if (( ${#missing[@]} > 0 )); then
        log_error "Variables requeridas no definidas en .env:"
        for v in "${missing[@]}"; do
            log_error "  ${v}"
        done
        log_error "  Edita .env y completa los valores."
        exit 1
    fi
    log_success "Variables requeridas presentes: DOMAIN, UI_DIST, SSL_CERT_DIR"

    # Validar formato de DOMAIN
    validate_domain "$DOMAIN" || exit 1
    log_success "DOMAIN tiene formato valido: ${DOMAIN}"

    # Avisar (no fatal) si UI_DIST no existe todavia. F11 (despliegue
    # del UI) lo crea con npm run build.
    if [[ ! -d "$UI_DIST" ]]; then
        log_warn "UI_DIST no existe todavia: ${UI_DIST}"
        log_warn "  Nginx arrancara pero servira 404 hasta que el bundle exista."
        log_warn "  Ejecuta 'npm run build' en template-ecommerce-ui."
    else
        log_success "UI_DIST existe: ${UI_DIST}"
    fi

    # SSL: avisar si el cert no existe. nginx -t fallaria al cargar.
    if [[ ! -f "${SSL_CERT_DIR}/key.pem" ]]; then
        log_error "Certificado SSL no encontrado en ${SSL_CERT_DIR}/key.pem"
        log_error "  Obtenlo antes: sudo bash provisioners/ssl/setup_ssl.sh"
        exit 1
    fi
    log_success "Certificado SSL presente en ${SSL_CERT_DIR}"

    # API_UPSTREAM puede estar vacio
    if [[ -z "${API_UPSTREAM:-}" ]]; then
        log_warn "API_UPSTREAM vacio -- el bloque location /api/ se COMENTARA."
        log_warn "  Configura .env y vuelve a ejecutar cuando tengas backend."
    else
        log_success "API_UPSTREAM: ${API_UPSTREAM}"
    fi
}

# =============================================================================
# PASO: Asegurar directorio para ACME challenge
# Lo crea provisioners/ssl/setup_ssl.sh, pero por idempotencia lo
# garantizamos aqui tambien (no danya si ya existe).
# =============================================================================
_ensure_acme_dir() {
    if [[ ! -d "$ACME_CHALLENGE_DIR" ]]; then
        log_info "  Creando ${ACME_CHALLENGE_DIR}"
        mkdir -p "$ACME_CHALLENGE_DIR"
        chmod 0755 "$ACME_CHALLENGE_DIR"
        chown root:root "$ACME_CHALLENGE_DIR"
    fi
}

# =============================================================================
# PASO: Sustituir placeholders %%VAR%% en un archivo
#   $1 = path del archivo (in-place modification)
#
# Si API_UPSTREAM esta vacio, comentar el bloque `location ^~ /api/ { }`
# entero ANTES de sustituir %%API_UPSTREAM%%, asi no queda una directiva
# proxy_pass invalida.
# =============================================================================
_substitute_vars() {
    local file="$1"

    # 1) Manejo de API_UPSTREAM vacio: comentar el bloque location /api/
    if [[ -z "${API_UPSTREAM:-}" ]]; then
        # Patron: desde "location ^~ /api/ {" hasta la "}" de cierre del
        # bloque. Usamos sed para anteponer "# " a cada linea entre la
        # apertura y el cierre.
        #
        # IMPORTANTE: el cierre `}` es la primera `}` solitaria (con
        # indentacion) tras la apertura. En nuestro template-https.conf
        # los locations estan indentados 4 espacios y cierran con "    }".
        sed -i '/^    location ^~ \/api\//,/^    }/ {
            s/^/# /
        }' "$file"

        # API_UPSTREAM queda con el placeholder pero dentro de comentarios.
        # Setear un valor dummy para que la sustitucion no deje %%API_UPSTREAM%%
        # libre (auditable abajo en grep de remanentes).
        API_UPSTREAM="${API_UPSTREAM:-http://127.0.0.1:1}"
    fi

    # 2) Sustitucion estandar de placeholders
    sed -i \
        -e "s|%%DOMAIN%%|${DOMAIN}|g" \
        -e "s|%%UI_DIST%%|${UI_DIST}|g" \
        -e "s|%%API_UPSTREAM%%|${API_UPSTREAM}|g" \
        -e "s|%%SSL_CERT_DIR%%|${SSL_CERT_DIR}|g" \
        "$file"

    # 3) Verificar que no queden placeholders sin sustituir.
    #    Filtrar lineas de comentario (que empiezan con #) para evitar
    #    falso positivo del comentario explicativo "%%VARIABLE%%" en el
    #    header del template.
    local remaining
    remaining=$(grep -vE '^[[:space:]]*#' "$file" 2>/dev/null \
                  | grep -oE '%%[A-Z_]+%%' \
                  | sort -u || echo "")
    if [[ -n "$remaining" ]]; then
        log_error "Placeholders sin sustituir en ${file}:"
        echo "$remaining" | while IFS= read -r ph; do
            log_error "  ${ph}"
        done
        log_error "  Agrega la variable a _substitute_vars() en setup_vhost.sh"
        exit 1
    fi
}

# =============================================================================
# PASO: Copiar template, sustituir variables y devolver path destino
# =============================================================================
_setup_conf() {
    local template_name="$1"
    local src="${PROJECT_ROOT}/config/nginx/${template_name}"
    local dst="${SITES_AVAILABLE}/${template_name}"

    log_info "  Procesando ${template_name}"

    [[ -f "$src" ]] || {
        log_error "Template no encontrado: ${src}"
        exit 1
    }

    # Asegurar que sites-available existe (default en Ubuntu, pero por
    # idempotencia)
    mkdir -p "$SITES_AVAILABLE" "$SITES_ENABLED"

    cp "$src" "$dst"
    _substitute_vars "$dst"
    log_success "  Generado: ${dst}"
}

# =============================================================================
# PASO: Activar (crear symlink en sites-enabled)
# =============================================================================
_enable_vhost() {
    local name="$1"
    local target="${SITES_AVAILABLE}/${name}"
    local link="${SITES_ENABLED}/${name}"

    if [[ ! -f "$target" ]]; then
        log_error "No se puede activar -- archivo no existe: ${target}"
        exit 1
    fi

    # Symlink relativo para portabilidad
    ln -sf "../sites-available/${name}" "$link"
    log_success "  Activado: ${link}"
}

# =============================================================================
# PASO: Desactivar default vhost si esta activo
# =============================================================================
_disable_default_if_active() {
    if [[ -L "${SITES_ENABLED}/${DEFAULT_VHOST}" ]]; then
        log_info "  Desactivando default vhost de Ubuntu"
        rm -f "${SITES_ENABLED}/${DEFAULT_VHOST}"
        DEFAULT_WAS_ACTIVE=true
    else
        DEFAULT_WAS_ACTIVE=false
    fi
}

# =============================================================================
# PASO: Revertir cambios si nginx -t falla
# =============================================================================
_revert() {
    log_warn "Revirtiendo cambios..."

    rm -f \
        "${SITES_ENABLED}/${VHOST_HTTP_NAME}" \
        "${SITES_ENABLED}/${VHOST_HTTPS_NAME}"
    rm -f \
        "${SITES_AVAILABLE}/${VHOST_HTTP_NAME}" \
        "${SITES_AVAILABLE}/${VHOST_HTTPS_NAME}"

    if [[ "${DEFAULT_WAS_ACTIVE:-false}" == "true" ]]; then
        if [[ -f "${SITES_AVAILABLE}/${DEFAULT_VHOST}" ]]; then
            ln -sf "../sites-available/${DEFAULT_VHOST}" \
                   "${SITES_ENABLED}/${DEFAULT_VHOST}"
            log_info "  ${DEFAULT_VHOST} restaurado"
        fi
    fi

    log_error "Setup revertido. Corrige los errores y vuelve a ejecutar."
}

# =============================================================================
# PASO: Validar configuracion completa
# =============================================================================
_validate_nginx_config() {
    log_header "PASO: Validando configuracion (nginx -t)"

    if nginx -t >/tmp/nginx_t.out 2>&1; then
        log_success "Configuracion Nginx valida"
        if grep -qE "warn|deprecated" /tmp/nginx_t.out; then
            log_warn "  nginx -t reporto warnings:"
            sed 's/^/    /' /tmp/nginx_t.out
        fi
        rm -f /tmp/nginx_t.out
    else
        log_error "nginx -t FALLO:"
        sed 's/^/  /' /tmp/nginx_t.out
        rm -f /tmp/nginx_t.out
        _revert
        exit 1
    fi
}

# =============================================================================
# PASO: Recargar Nginx (sin downtime)
# =============================================================================
_reload_nginx() {
    log_header "PASO: Recargando Nginx"

    if svc_is_active nginx; then
        log_info "  svc_reload nginx (graceful)"
        if svc_reload nginx; then
            log_success "Nginx recargado sin downtime"
        else
            log_error "svc_reload nginx fallo"
            log_error "  Revisa: journalctl -u nginx -n 50"
            exit 1
        fi
    else
        log_warn "Nginx no estaba activo -- arrancando ahora"
        if svc_start nginx; then
            log_success "Nginx arrancado"
        else
            log_error "svc_start nginx fallo"
            exit 1
        fi
    fi
}

# =============================================================================
# MAIN
# =============================================================================
log_header "Setup de virtualhosts -- template-ecommerce-server"
log_info "  Dominio:  ${DOMAIN:-<no definido>}"
log_info "  UI_DIST:  ${UI_DIST:-<no definido>}"
log_info "  API:      ${API_UPSTREAM:-<vacio -- /api/ comentado>}"
log_info "  SSL dir:  ${SSL_CERT_DIR:-<no definido>}"
echo ""

_check_required_vars; echo ""
_ensure_acme_dir;     echo ""

log_header "PASO: Generando vhosts desde templates"
_setup_conf "${VHOST_HTTP_NAME}"
_setup_conf "${VHOST_HTTPS_NAME}"
echo ""

log_header "PASO: Activando vhosts"
_disable_default_if_active
_enable_vhost "${VHOST_HTTP_NAME}"
_enable_vhost "${VHOST_HTTPS_NAME}"
echo ""

_validate_nginx_config; echo ""
_reload_nginx;          echo ""

log_separator 60 "="
log_success "Virtualhosts activos y sirviendo."
echo ""
log_info "Pruebas rapidas:"
log_info "  curl -I http://${DOMAIN}        # debe 301 a https"
log_info "  curl -Ik https://${DOMAIN}      # debe 200 con cert valido"
if [[ -n "${API_UPSTREAM:-}" ]] && [[ "${API_UPSTREAM}" != "http://127.0.0.1:1" ]]; then
    log_info "  curl -Ik https://${DOMAIN}/api/ # debe llegar a upstream"
fi
log_info "Verificacion completa:"
log_info "  bash scripts/verify.sh"
