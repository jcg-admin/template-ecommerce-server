#!/bin/bash
# =============================================================================
# provisioners/ssl/setup_ssl.sh
# Obtiene y configura el certificado SSL del template-ecommerce-server
# =============================================================================
# Portado del referente jcg-admin/e-comerce-server/provisioners/ssl/setup_ssl.sh
# (510 LOC) con adaptaciones a Nginx documentadas en progreso F5 (3 hallazgos
# de inspeccion previa al codigo):
#
#   1. Reloadcmd Apache -> Nginx (`nginx -s reload` en lugar de
#      `apache2ctl graceful`).
#   2. Webroot ACME challenge: `/var/www/acme-challenge` (path canonico
#      del repo, dedicado) en lugar de `/var/www/html`.
#   3. Mensajes de error cambian `provisioners/apache/...` ->
#      `provisioners/nginx/...`.
#
# IDEMPOTENTE: si el certificado existe y esta vigente
# (SSL_CERT_STATUS=OK), no hace nada.
#
# Tres rutas de provisioning:
#   --dev      -> self-signed con OpenSSL (sin DNS publico, sin red)
#   --staging  -> Let's Encrypt STAGING (rate-limit friendly; cert no
#                 confiable por navegadores -- solo para validar el
#                 flujo ACME end-to-end). Si el endpoint staging no es
#                 alcanzable, cae automaticamente a self-signed.
#   sin flag   -> Let's Encrypt PRODUCCION (requiere DNS publico).
#
# Escenarios:
#   A) Certificado valido instalado (SSL_CERT_STATUS=OK):
#      No-op. Informa fecha de expiracion y dias restantes.
#
#   B) Sin certificado o expirado (SSL_CERT_STATUS=ERR):
#      Se aplica la ruta correspondiente al flag.
#
#   C) Certificado proximo a vencer (SSL_CERT_STATUS=WARN):
#      Delega a scripts/renew_ssl.sh (F8). El provisioner de setup
#      no renueva -- esa es responsabilidad de renew_ssl.sh que corre
#      via cron.
#
# Uso:
#   sudo bash provisioners/ssl/setup_ssl.sh             # produccion
#   sudo bash provisioners/ssl/setup_ssl.sh --staging   # LE staging
#   sudo bash provisioners/ssl/setup_ssl.sh --dev       # self-signed
#
# Variables requeridas en .env:
#   DOMAIN, SSL_CERT_DIR, SSL_EMAIL (produccion y staging),
#   SSL_CERT_DAYS_WARN, SSL_CERT_DAYS_ERR
#
# Variable de .env equivalente al flag --staging:
#   SSL_STAGING=true   # equivalente a invocar con --staging
#
# Prerequisitos para produccion:
#   - Nginx activo en puerto 80 (para HTTP-01 challenge de Let's Encrypt)
#   - El path /.well-known/acme-challenge/ servido en HTTP sin redirect
#     (ya configurado en template-http.conf + template-https.conf)
#   - Acceso a internet (acme.sh descarga el certificado)
#
# Requiere: root, Ubuntu 24.04.
# Modelo de cuentas (D-CUENTAS): invocar como `deploy` (UID 1000).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
export PROJECT_ROOT

source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/core.sh"
source "${PROJECT_ROOT}/utils/network.sh"
source "${PROJECT_ROOT}/utils/validation.sh"

# Path canonico del webroot ACME (alineado con template-http.conf F3).
readonly ACME_WEBROOT="/var/www/acme-challenge"

# Detectar modo de provisioning desde args o .env. Prioridad:
#   1. --dev en args                -> dev (gana sobre cualquier otra)
#   2. --staging en args            -> staging
#   3. SSL_STAGING=true en .env     -> staging
#   4. Sin nada                     -> production
DEV_MODE=false
STAGING_MODE=false
for arg in "$@"; do
    case "$arg" in
        --dev)     DEV_MODE=true ;;
        --staging) STAGING_MODE=true ;;
    esac
done

# Cargar .env -- requerido
ENV_FILE="${PROJECT_ROOT}/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    log_error "Archivo .env no encontrado en ${PROJECT_ROOT}"
    log_error "  Crea tu configuracion: cp .env.example .env"
    exit 1
fi
set -a; source "$ENV_FILE"; set +a

# SSL_STAGING de .env solo se aplica si --dev no esta activo
if [[ "$DEV_MODE" != "true" && "${SSL_STAGING:-false}" == "true" ]]; then
    STAGING_MODE=true
fi
# --dev gana sobre --staging
if [[ "$DEV_MODE" == "true" ]]; then
    STAGING_MODE=false
fi

# MODE: dev | staging | production -- variable derivada
if   [[ "$DEV_MODE"     == "true" ]]; then MODE="dev"
elif [[ "$STAGING_MODE" == "true" ]]; then MODE="staging"
else                                       MODE="production"
fi

# Defaults para umbrales si no estan en .env
SSL_CERT_DAYS_WARN="${SSL_CERT_DAYS_WARN:-30}"
SSL_CERT_DAYS_ERR="${SSL_CERT_DAYS_ERR:-7}"

# STAGING_FALLBACK_REASON: poblado por _check_requisites si staging no es
# alcanzable, para que MAIN caiga a self-signed.
STAGING_FALLBACK_REASON=""

# =============================================================================
# PASO: Verificar requisitos
# =============================================================================
_check_requisites() {
    log_header "PASO: Verificando requisitos"

    validate_root || {
        log_error "  Ejecuta con: sudo bash provisioners/ssl/setup_ssl.sh"
        exit 1
    }
    log_success "Corriendo como root"

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

    if [[ "$DEV_MODE" == "true" ]]; then
        log_info "Modo: --dev (self-signed con OpenSSL)"
        command_exists openssl || {
            log_error "openssl no encontrado"
            log_error "  Instala con: sudo apt-get install openssl"
            exit 1
        }
        log_success "openssl disponible"
        return 0
    fi

    # Produccion y staging comparten requisitos. La diferencia es el endpoint.
    local le_label le_host
    if [[ "$STAGING_MODE" == "true" ]]; then
        log_info "Modo: --staging (Let's Encrypt STAGING via acme.sh)"
        log_info "  Aviso: los certs de staging NO son confiables por navegadores"
        log_info "  Aviso: usalo SOLO para validar el flujo ACME, no en produccion"
        le_label="Let's Encrypt staging"
        le_host="acme-staging-v02.api.letsencrypt.org"
    else
        log_info "Modo: produccion (Let's Encrypt via acme.sh)"
        le_label="Let's Encrypt"
        le_host="acme-v02.api.letsencrypt.org"
    fi

    [[ -n "${SSL_EMAIL:-}" ]] || {
        log_error "SSL_EMAIL no definido en .env"
        log_error "  ${le_label} requiere un email para notificaciones"
        exit 1
    }
    log_success "SSL_EMAIL: ${SSL_EMAIL}"

    # Nginx debe estar activo en :80 para el HTTP-01 challenge.
    # En staging es opcional: si falta, caemos a self-signed mas adelante.
    if ! tcp_is_reachable "127.0.0.1" 80 3; then
        if [[ "$STAGING_MODE" == "true" ]]; then
            log_warn "Nginx no responde en :80 -- staging caera a self-signed"
            STAGING_FALLBACK_REASON="nginx:80 no responde"
            return 0
        fi
        log_error "Nginx no responde en el puerto 80"
        log_error "  ${le_label} necesita servir el challenge en HTTP"
        log_error "  Asegurate de que Nginx este activo y el vhost HTTP configurado:"
        log_error "    sudo bash provisioners/nginx/install.sh"
        log_error "    sudo bash provisioners/nginx/setup_vhost.sh"
        exit 1
    fi
    log_success "Nginx activo en puerto 80"

    # Acceso a la CA -- en staging es opcional (fallback a self-signed).
    if ! tcp_is_reachable "${le_host}" 443 5; then
        if [[ "$STAGING_MODE" == "true" ]]; then
            log_warn "Sin acceso a ${le_host}:443 -- staging caera a self-signed"
            STAGING_FALLBACK_REASON="${le_host} no alcanzable"
            return 0
        fi
        log_error "Sin acceso a ${le_host}:443"
        log_error "  Se requiere conexion a internet para emitir el certificado"
        exit 1
    fi
    log_success "Acceso a ${le_label}"
}

# =============================================================================
# PASO: Verificar certificado existente
# Determina el escenario (A, B o C) y actua en consecuencia
# =============================================================================
_check_existing_cert() {
    log_header "PASO: Verificando certificado existente"

    # Idempotencia (heredado del referente, ver D-029 en su historia): si
    # el dir existe pero con perms restrictivos de una instalacion anterior
    # (0700 root:root), normalizar a 0755 ANTES de validar el cert. Sin
    # esto, re-correr el script sobre un servidor con el bug original NO
    # converge al estado correcto.
    if [[ -d "$SSL_CERT_DIR" ]]; then
        local current_mode
        current_mode=$(stat -c '%a' "$SSL_CERT_DIR" 2>/dev/null || echo "")
        if [[ -n "$current_mode" && "$current_mode" != "755" ]]; then
            log_warn "  ${SSL_CERT_DIR} con mode ${current_mode} -- normalizando a 755"
            chmod 0755 "$SSL_CERT_DIR"
            log_success "  ${SSL_CERT_DIR} ahora con mode 755"
        fi
    fi

    local cert_file="${SSL_CERT_DIR}/cert.pem"

    validate_ssl_cert "$cert_file" "$SSL_CERT_DAYS_WARN" "$SSL_CERT_DAYS_ERR"

    case "$SSL_CERT_STATUS" in
        OK)
            # Escenario A -- certificado valido, no hacer nada
            log_success "Certificado vigente -- sin accion requerida (Escenario A)"
            echo ""
            log_separator 60 "="
            log_success "Certificado SSL en orden. Sin cambios."
            exit 0
            ;;
        WARN)
            # Escenario C -- proximo a vencer, delegar a renew_ssl.sh
            log_warn "Certificado proximo a vencer (Escenario C)"
            log_warn "  La renovacion es responsabilidad de scripts/renew_ssl.sh"
            local renew_script="${PROJECT_ROOT}/scripts/renew_ssl.sh"
            if [[ -f "$renew_script" ]]; then
                log_info "  Ejecutando scripts/renew_ssl.sh..."
                bash "$renew_script"
            else
                log_warn "  scripts/renew_ssl.sh no encontrado (F8 lo produce) -- renueva manualmente:"
                log_warn "    ~/.acme.sh/acme.sh --renew -d ${DOMAIN}"
                if is_systemd; then
                    log_warn "    sudo systemctl reload nginx"
                else
                    log_warn "    sudo nginx -s reload   # sin systemd"
                fi
            fi
            exit 0
            ;;
        ERR)
            # Escenario B -- sin certificado o expirado, continuar con emision
            log_info "Procediendo con la emision del certificado (Escenario B)"
            ;;
    esac
}

# =============================================================================
# PASO: Crear directorio de certificados
# =============================================================================
_create_cert_dir() {
    log_header "PASO: Preparando directorio de certificados"

    mkdir -p "$SSL_CERT_DIR"
    # 0755 -- el certificado publico debe ser legible por procesos no-root
    # (scripts/verify.sh corre como deploy y necesita stat sobre cert.pem).
    # El secreto vive en key.pem, que se chmod 600 en _generate_self_signed/
    # _install_certificate. Sin o+x en el directorio, '[[ -f cert.pem ]]'
    # devuelve false como non-root incluso si el archivo existe.
    chmod 0755 "$SSL_CERT_DIR"
    log_success "Directorio: ${SSL_CERT_DIR}"
}

# =============================================================================
# PASO: Crear webroot para el ACME challenge
# Adaptado del referente: path canonico de NUESTRO repo (/var/www/acme-
# challenge), no /var/www/html como en el referente.
# =============================================================================
_create_acme_webroot() {
    log_header "PASO: Preparando webroot ACME"

    mkdir -p "${ACME_WEBROOT}/.well-known/acme-challenge"
    chmod 0755 "$ACME_WEBROOT"
    chown root:root "$ACME_WEBROOT"
    log_success "Webroot ACME: ${ACME_WEBROOT}"
}

# =============================================================================
# PASO: Generar certificado self-signed (--dev)
# =============================================================================
_generate_self_signed() {
    log_header "PASO: Generando certificado self-signed (desarrollo)"

    local cert_file="${SSL_CERT_DIR}/cert.pem"
    local key_file="${SSL_CERT_DIR}/key.pem"
    local chain_file="${SSL_CERT_DIR}/fullchain.pem"

    log_info "  Dominio: ${DOMAIN}"
    log_info "  Validez: 365 dias"
    log_info "  Nota: los navegadores mostraran una advertencia de seguridad"

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$key_file" \
        -out    "$cert_file" \
        -subj   "/CN=${DOMAIN}/O=template-ecommerce-server Dev/C=MX" \
        2>/dev/null

    # Para self-signed, fullchain es igual al certificado (sin cadena
    # intermedia).
    cp "$cert_file" "$chain_file"

    chmod 600 "$key_file"
    chmod 644 "$cert_file" "$chain_file"

    log_success "Certificado self-signed generado en ${SSL_CERT_DIR}"
    log_warn "  Valido para: ${DOMAIN}"
    log_warn "  Expiracion: en 365 dias"
    log_warn "  Los navegadores mostraran advertencia -- es esperado en desarrollo"
}

# =============================================================================
# PASO: Instalar acme.sh si no existe (produccion/staging)
# =============================================================================
_install_acme_sh() {
    log_header "PASO: Verificando acme.sh"

    local acme_home="${HOME}/.acme.sh"
    local acme_cmd="${acme_home}/acme.sh"

    if [[ -f "$acme_cmd" ]]; then
        log_success "acme.sh ya instalado: ${acme_cmd}"
        return 0
    fi

    log_info "  Instalando acme.sh..."

    command_exists curl || {
        log_info "  Instalando curl..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl > /dev/null
    }

    # acme.sh requiere cron para auto-renovacion. En contenedores y CI cron
    # suele estar ausente -- usamos --force y dejamos la renovacion
    # documentada manualmente (o via systemd-timer en el host).
    local acme_install_flags=""
    if ! command_exists crontab; then
        log_warn "  crontab no disponible -- usando 'acme.sh --install --force'"
        log_warn "  Configura la renovacion manualmente (cron del operador / systemd timer)"
        acme_install_flags="--force"
    fi

    # get.acme.sh espera el token email=<addr> en PRIMERA posicion (heredado
    # del referente; cambio del bootstrap actual).
    if ! curl -fsSL https://get.acme.sh \
            | sh -s -- email="${SSL_EMAIL}" --install ${acme_install_flags} \
            > /dev/null 2>&1; then
        # Fallback: descarga manual y ejecucion local con --force
        local tmp_dir
        tmp_dir=$(mktemp -d)
        if curl -fsSL https://github.com/acmesh-official/acme.sh/archive/master.tar.gz \
                | tar -xz -C "$tmp_dir" 2>/dev/null \
                && ( cd "${tmp_dir}"/acme.sh-* \
                    && ./acme.sh --install --force \
                        --accountemail "${SSL_EMAIL}" >/dev/null 2>&1 ); then
            rm -rf "$tmp_dir"
        else
            rm -rf "$tmp_dir"
            log_error "No se pudo instalar acme.sh"
            log_error "  Instala manualmente: curl https://get.acme.sh | sh -s email=${SSL_EMAIL}"
            exit 1
        fi
    fi

    # Recargar el PATH para encontrar acme.sh
    # shellcheck source=/dev/null
    [[ -f "${acme_home}/acme.sh.env" ]] && source "${acme_home}/acme.sh.env"

    log_success "acme.sh instalado: ${acme_cmd}"
}

# =============================================================================
# PASO: Emitir certificado Let's Encrypt (produccion/staging)
# Usa HTTP-01 webroot challenge -- Nginx debe estar activo en :80
#
# Adaptacion vs referente: webroot es ${ACME_WEBROOT} (path canonico
# /var/www/acme-challenge) en lugar de /var/www/html del Apache referente.
# =============================================================================
_issue_certificate() {
    log_header "PASO: Emitiendo certificado para ${DOMAIN}"

    local acme_cmd="${HOME}/.acme.sh/acme.sh"

    # El webroot ya esta creado por _create_acme_webroot.

    # Selector de CA: staging usa el endpoint stage para no consumir
    # rate-limit del entorno productivo.
    local ca_label="Let's Encrypt"
    local acme_extra_args=()
    if [[ "$STAGING_MODE" == "true" ]]; then
        ca_label="Let's Encrypt STAGING"
        acme_extra_args+=("--staging")
    fi

    log_info "  Dominio: ${DOMAIN}"
    log_info "  Metodo: HTTP-01 webroot (${ACME_WEBROOT})"
    log_info "  CA: ${ca_label}"

    if ! "$acme_cmd" --issue -d "${DOMAIN}" \
            --webroot "$ACME_WEBROOT" \
            --accountemail "${SSL_EMAIL}" \
            "${acme_extra_args[@]}" \
            2>/dev/null; then
        log_error "No se pudo emitir el certificado contra ${ca_label}"
        log_error "  Verifica que:"
        log_error "    - El dominio ${DOMAIN} resuelve a este servidor"
        log_error "    - Nginx sirve ${ACME_WEBROOT}/.well-known/ en http://${DOMAIN}/"
        log_error "    - No hay firewall bloqueando el puerto 80"
        exit 1
    fi

    log_success "Certificado emitido para ${DOMAIN} (${ca_label})"
}

# =============================================================================
# PASO: Instalar certificado en SSL_CERT_DIR (produccion/staging)
#
# Adaptacion vs referente: --reloadcmd usa `nginx -s reload` en lugar de
# `apache2ctl graceful`. Este reloadcmd se invoca tambien en cada
# renovacion automatica (cron); imprescindible que apunte al binario
# correcto del web server.
# =============================================================================
_install_certificate() {
    log_header "PASO: Instalando certificado en ${SSL_CERT_DIR}"

    local acme_cmd="${HOME}/.acme.sh/acme.sh"

    if ! "$acme_cmd" --install-cert -d "${DOMAIN}" \
            --cert-file      "${SSL_CERT_DIR}/cert.pem" \
            --key-file       "${SSL_CERT_DIR}/key.pem" \
            --fullchain-file "${SSL_CERT_DIR}/fullchain.pem" \
            --reloadcmd      "nginx -s reload" \
            2>/dev/null; then
        log_error "No se pudo instalar el certificado en ${SSL_CERT_DIR}"
        exit 1
    fi

    # Permisos canonicos (D-STORAGE): key.pem 0600 root:root, cert+fullchain 0644.
    # acme.sh aplica permisos correctos, pero los re-aplicamos por idempotencia.
    chmod 600 "${SSL_CERT_DIR}/key.pem"
    chmod 644 "${SSL_CERT_DIR}/cert.pem" "${SSL_CERT_DIR}/fullchain.pem"
    chown root:root \
        "${SSL_CERT_DIR}/key.pem" \
        "${SSL_CERT_DIR}/cert.pem" \
        "${SSL_CERT_DIR}/fullchain.pem"

    log_success "Certificado instalado en ${SSL_CERT_DIR}"
}

# =============================================================================
# PASO: Configurar renovacion automatica via cron (produccion/staging)
# =============================================================================
_configure_renewal() {
    log_header "PASO: Configurando renovacion automatica"

    local acme_cmd="${HOME}/.acme.sh/acme.sh"

    if "$acme_cmd" --install-cronjob 2>/dev/null; then
        log_success "Cron de renovacion automatica configurado"
    else
        log_warn "  No se pudo instalar el cron -- configura manualmente:"
        log_warn "    0 2 * * 1 ${acme_cmd} --cron --home ${HOME}/.acme.sh"
    fi
}

# =============================================================================
# PASO: Verificar certificado instalado
# =============================================================================
_verify_certificate() {
    log_header "PASO: Verificando certificado instalado"

    validate_ssl_cert "${SSL_CERT_DIR}/cert.pem" \
        "$SSL_CERT_DAYS_WARN" "$SSL_CERT_DAYS_ERR"

    if [[ "$SSL_CERT_STATUS" == "OK" ]]; then
        log_success "Certificado verificado correctamente"
    else
        log_error "La verificacion del certificado fallo (SSL_CERT_STATUS=${SSL_CERT_STATUS})"
        exit 1
    fi
}

# =============================================================================
# MAIN
# =============================================================================
log_header "Configuracion SSL -- template-ecommerce-server"
case "$MODE" in
    dev)        log_info "  Modo: --dev (self-signed con OpenSSL)" ;;
    staging)    log_info "  Modo: --staging (Let's Encrypt staging)" ;;
    production) log_info "  Modo: produccion (Let's Encrypt)" ;;
esac
echo ""

_check_requisites;     echo ""
_check_existing_cert;  echo ""
_create_cert_dir;      echo ""

# Fallback de staging: si los prerequisitos no se cumplen, cae a self-signed
# para que el script siempre deje SSL_CERT_DIR poblado con algo valido.
if [[ "$MODE" == "staging" && -n "$STAGING_FALLBACK_REASON" ]]; then
    log_warn "  staging no aplicable (${STAGING_FALLBACK_REASON}) -- emitiendo self-signed"
    MODE="dev"
fi

case "$MODE" in
    dev)
        _generate_self_signed; echo ""
        ;;
    staging|production)
        _create_acme_webroot; echo ""
        _install_acme_sh;     echo ""
        _issue_certificate;   echo ""
        _install_certificate; echo ""
        _configure_renewal;   echo ""
        ;;
esac

_verify_certificate; echo ""

log_separator 60 "="
log_success "Certificado SSL configurado para ${DOMAIN} (modo: ${MODE})"
echo ""
log_info "Siguiente paso -- activar los virtualhosts (si no esta hecho):"
log_info "  sudo bash provisioners/nginx/setup_vhost.sh"
log_info "Verificar entorno completo:"
log_info "  bash scripts/verify.sh"
