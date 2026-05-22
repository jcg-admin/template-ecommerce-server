#!/bin/bash
# =============================================================================
# utils/validation.sh -- Funciones de validacion
#                        template-ecommerce-server
# =============================================================================
# Portado desde jcg-admin/e-comerce-server/utils/validation.sh con
# adaptaciones significativas al contexto de este repo (sin Django,
# sin Apache, sin Python embebido):
#
# Funciones portadas 1:1 (agnostic):
#   validate_root
#   validate_ubuntu [version_prefix]
#   validate_ssl_cert <cert_path> [warn_days] [err_days]
#
# Funciones NO portadas:
#   validate_python_version
#     Razon: D-BACKEND-AGNOSTIC. Este server NO embebe Python; el
#     backend (cuando exista) corre en otro lugar y se accede via
#     $API_UPSTREAM por reverse proxy. Codigo muerto en este contexto.
#
#   validate_apache_version
#     Razon: D-WS. Reemplazada por validate_nginx_version con la misma
#     estructura pero parseando la salida de nginx -v.
#
# Funciones nuevas especificas de este repo:
#   validate_nginx_version [required_major] [required_minor]
#   validate_domain <hostname>
#   validate_email <addr>
#   validate_port <num>
#   validate_path_writable <path>
#   is_wsl2
#
# Depende de: logging.sh, core.sh
#
# Uso:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/validation.sh"
# =============================================================================

# -----------------------------------------------------------------------------
# validate_root
#   Retorna 0 si el proceso corre como root (EUID=0), 1 si no.
#   Los provisioners (install.sh, setup_vhost.sh, setup_ssl.sh) requieren
#   root para instalar paquetes y escribir en /etc/nginx/.
# -----------------------------------------------------------------------------
validate_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script debe ejecutarse como root (usa sudo)"
        return 1
    fi
    return 0
}

# -----------------------------------------------------------------------------
# validate_ubuntu [version_prefix]
#   Verifica que el SO es Ubuntu y que la version comienza con
#   version_prefix. Default: "24.04".
# -----------------------------------------------------------------------------
validate_ubuntu() {
    local required_prefix="${1:-24.04}"
    local os_release="/etc/os-release"

    [[ -f "$os_release" ]] || { log_error "No se encontro ${os_release}"; return 1; }

    local os_id os_version_id
    os_id=$(. "$os_release" && echo "${ID:-}")
    os_version_id=$(. "$os_release" && echo "${VERSION_ID:-}")

    [[ "${os_id,,}" == "ubuntu" ]] || { log_error "SO incompatible: ${os_id}"; return 1; }
    [[ "${os_version_id}" == "${required_prefix}"* ]] || {
        log_error "Version incompatible: Ubuntu ${os_version_id} (se requiere ${required_prefix}.x)"
        return 1
    }
    return 0
}

# -----------------------------------------------------------------------------
# validate_nginx_version [required_major] [required_minor]
#   Verifica que Nginx esta instalado y cumple la serie major.minor.x.
#   Default: 1.24
#
#   Lee la version del binario nginx -v (no requiere servidor activo).
#   Mismo patron que validate_apache_version del referente, adaptado a
#   la salida de nginx -v que va a stderr.
#
#   Ejemplo de salida de nginx -v:
#     nginx version: nginx/1.24.0 (Ubuntu)
#
#   Retorna 0 si la version es correcta, 1 si no esta instalado o la
#   serie no coincide.
# -----------------------------------------------------------------------------
validate_nginx_version() {
    local required_major="${1:-1}" required_minor="${2:-24}"

    require_command nginx || {
        log_error "nginx no encontrado -- Nginx no esta instalado"
        log_error "  Instala con: sudo bash provisioners/nginx/install.sh"
        return 1
    }

    # nginx -v escribe a stderr; redirigir con 2>&1
    local version_full
    version_full=$(nginx -v 2>&1 \
        | grep -oE 'nginx/[0-9]+\.[0-9]+\.[0-9]+' \
        | head -1)

    if [[ -z "$version_full" ]]; then
        local raw
        raw=$(nginx -v 2>&1 || echo "")
        log_error "No se pudo leer la version de Nginx"
        log_error "  Salida: ${raw}"
        log_error "  Se requiere: Nginx ${required_major}.${required_minor}.x+"
        return 1
    fi

    local version_str installed_major installed_minor
    version_str=$(echo "$version_full" | cut -d/ -f2)
    installed_major=$(echo "$version_str" | cut -d. -f1)
    installed_minor=$(echo "$version_str" | cut -d. -f2)

    # Aceptar major igual, minor >= required (e.g. 1.24+ acepta 1.24, 1.26, etc)
    if (( installed_major < required_major )) \
       || (( installed_major == required_major && installed_minor < required_minor )); then
        log_error "Version instalada: Nginx ${version_str}"
        log_error "Se requiere: Nginx ${required_major}.${required_minor}.x+"
        log_error "  Actualiza con: sudo apt update && sudo apt install --only-upgrade nginx"
        return 1
    fi

    return 0
}

# -----------------------------------------------------------------------------
# validate_ssl_cert <cert_path> [warn_days] [err_days]
#   Verifica la vigencia de un certificado SSL instalado.
#   Defaults: warn_days=30, err_days=7.
#
#   No requiere conexion de red -- lee la fecha del archivo cert.pem.
#
#   CONVENCION DE RETORNO compatible con set -euo pipefail:
#   Retorna siempre 0. Exporta SSL_CERT_STATUS con valor OK, WARN o ERR.
#   Los callers consultan la variable en lugar del codigo de retorno.
#   Retornar 1 o 2 con set -e activo mata el script si el caller no usa
#   || true -- patron fragil que esta convencion evita.
#
#   Ejemplo de uso:
#     validate_ssl_cert "/etc/ssl/midominio.com/cert.pem" 30 7
#     if [[ "$SSL_CERT_STATUS" == "ERR" ]]; then
#         log_error "Certificado vencido o proximo a vencer"
#     fi
# -----------------------------------------------------------------------------
validate_ssl_cert() {
    local cert_path="${1:-}"
    local warn_days="${2:-30}"
    local err_days="${3:-7}"

    # Exportar siempre -- el caller necesita poder leer la variable
    # incluso si la funcion sale antes por error.
    export SSL_CERT_STATUS="ERR"

    if [[ -z "$cert_path" ]]; then
        log_error "validate_ssl_cert: se requiere la ruta del certificado"
        return 0
    fi

    if [[ ! -f "$cert_path" ]]; then
        # Distinguir "no existe" de "no accesible". Si el directorio
        # padre existe pero no es entrable (perm 0700 sin x para el
        # usuario actual), '[[ -f ]]' devuelve false aunque el cert
        # este ahi.
        local cert_dir
        cert_dir=$(dirname "$cert_path")
        if [[ -d "$cert_dir" ]] && [[ ! -x "$cert_dir" ]]; then
            log_error "Certificado no accesible: ${cert_path}"
            log_error "  Directorio ${cert_dir} sin permiso de ejecucion para"
            log_error "  el usuario actual ($(whoami)). Probable mode 0700."
            log_error "  Fix: sudo chmod 0755 ${cert_dir}"
            log_error "  (el cert es publico; key.pem permanece 0600)"
        else
            log_error "Certificado no encontrado: ${cert_path}"
            log_error "  Obten el certificado con: sudo bash provisioners/ssl/setup_ssl.sh"
        fi
        return 0
    fi

    if ! require_command openssl; then
        log_error "openssl no disponible -- no se puede verificar el certificado"
        return 0
    fi

    local expiry_str
    expiry_str=$(openssl x509 -enddate -noout -in "$cert_path" 2>/dev/null \
        | cut -d= -f2)

    if [[ -z "$expiry_str" ]]; then
        log_error "No se pudo leer la fecha de expiracion de: ${cert_path}"
        log_error "  El archivo puede estar corrupto o no ser un certificado valido"
        return 0
    fi

    local expiry_epoch
    expiry_epoch=$(date -d "$expiry_str" +%s 2>/dev/null)

    if [[ -z "$expiry_epoch" ]]; then
        log_error "No se pudo parsear la fecha de expiracion: ${expiry_str}"
        return 0
    fi

    local now_epoch days_remaining
    now_epoch=$(date +%s)
    days_remaining=$(( (expiry_epoch - now_epoch) / 86400 ))

    if (( days_remaining <= 0 )); then
        export SSL_CERT_STATUS="ERR"
        log_error "Certificado VENCIDO hace $(( -days_remaining )) dias"
        log_error "  Renueva con: bash scripts/renew_ssl.sh"
    elif (( days_remaining < err_days )); then
        export SSL_CERT_STATUS="ERR"
        log_error "Certificado vence en ${days_remaining} dias -- URGENTE"
        log_error "  Renueva con: bash scripts/renew_ssl.sh"
    elif (( days_remaining < warn_days )); then
        export SSL_CERT_STATUS="WARN"
        log_warn "Certificado vence en ${days_remaining} dias"
        log_warn "  Renueva con: bash scripts/renew_ssl.sh"
    else
        export SSL_CERT_STATUS="OK"
        log_success "Certificado valido -- vence en ${days_remaining} dias"
    fi

    return 0
}

# =============================================================================
# Validaciones nuevas especificas de este repo
# =============================================================================

# -----------------------------------------------------------------------------
# validate_domain <hostname>
#   Verifica que el argumento es un hostname valido segun RFC 1123.
#   Acepta:
#     - hostnames simples: localhost, miserver
#     - FQDNs: midominio.com, app.midominio.com, www.app.midominio.com
#   Rechaza:
#     - Vacio, espacios, caracteres no validos.
#     - Empieza o termina con `-` o `.`.
#     - Labels > 63 chars o total > 253 chars.
#
#   No verifica que el dominio resuelva por DNS (eso es runtime, no
#   validacion de formato).
# -----------------------------------------------------------------------------
validate_domain() {
    local domain="${1:-}"

    if [[ -z "$domain" ]]; then
        log_error "validate_domain: dominio vacio"
        return 1
    fi

    if (( ${#domain} > 253 )); then
        log_error "validate_domain: dominio demasiado largo (${#domain} > 253 chars)"
        return 1
    fi

    # Hostname o FQDN; cada label 1-63 chars, alfanumerico o guion,
    # no empieza ni termina en guion. localhost permitido.
    local pattern='^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'
    if [[ ! "$domain" =~ $pattern ]]; then
        log_error "validate_domain: formato invalido -- ${domain}"
        return 1
    fi
    return 0
}

# -----------------------------------------------------------------------------
# validate_email <addr>
#   Validacion basica de formato de email. NO sigue RFC 5322 completo
#   (demasiado permisivo); usa un subset razonable que cubre los emails
#   usuales del operador del servidor.
# -----------------------------------------------------------------------------
validate_email() {
    local addr="${1:-}"

    if [[ -z "$addr" ]]; then
        log_error "validate_email: direccion vacia"
        return 1
    fi

    local pattern='^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    if [[ ! "$addr" =~ $pattern ]]; then
        log_error "validate_email: formato invalido -- ${addr}"
        return 1
    fi
    return 0
}

# -----------------------------------------------------------------------------
# validate_port <num>
#   Verifica que el argumento es un puerto TCP valido.
#   Rango aceptado: 1-65535. Recomendado para SSH_PORT: 1024-65535
#   (puertos no privilegiados ademas de los reservados conocidos).
#   Esta funcion acepta el rango completo; la recomendacion la aplica
#   el caller si quiere.
# -----------------------------------------------------------------------------
validate_port() {
    local port="${1:-}"

    if [[ -z "$port" ]]; then
        log_error "validate_port: puerto vacio"
        return 1
    fi

    if [[ ! "$port" =~ ^[0-9]+$ ]]; then
        log_error "validate_port: no es numero -- ${port}"
        return 1
    fi

    if (( port < 1 )) || (( port > 65535 )); then
        log_error "validate_port: fuera de rango -- ${port} (1-65535)"
        return 1
    fi
    return 0
}

# -----------------------------------------------------------------------------
# validate_path_writable <path>
#   Verifica que el path es escribible por el usuario actual. Si el path
#   no existe, verifica que su directorio padre lo es.
#   Util antes de escribir archivos generados (configs procesadas,
#   logs, etc).
# -----------------------------------------------------------------------------
validate_path_writable() {
    local path="${1:-}"

    if [[ -z "$path" ]]; then
        log_error "validate_path_writable: ruta vacia"
        return 1
    fi

    if [[ -e "$path" ]]; then
        if [[ ! -w "$path" ]]; then
            log_error "validate_path_writable: no escribible -- ${path}"
            return 1
        fi
        return 0
    fi

    # No existe; el padre debe ser escribible
    local parent
    parent=$(dirname "$path")
    if [[ ! -d "$parent" ]]; then
        log_error "validate_path_writable: directorio padre no existe -- ${parent}"
        return 1
    fi
    if [[ ! -w "$parent" ]]; then
        log_error "validate_path_writable: directorio padre no escribible -- ${parent}"
        return 1
    fi
    return 0
}

# -----------------------------------------------------------------------------
# is_wsl2
#   Retorna 0 si el sistema corre sobre WSL2, 1 si no.
#
#   Estrategia:
#     1) /proc/version contiene "microsoft" (caso insensitivo).
#     2) /proc/sys/kernel/osrelease contiene "WSL2" o "microsoft".
#   Combinacion robusta porque WSL1 y WSL2 tienen flags ligeramente
#   distintos. WSL2 = kernel Linux real (Hyper-V), no falla en aplicar
#   muchos provisioners; WSL1 = capa de traduccion, fallaria.
#
#   Usado por provisioners para aplicar skip explicito donde corresponde
#   (caso sshd en WSL2 que lo maneja Windows, no Linux).
# -----------------------------------------------------------------------------
is_wsl2() {
    if grep -qi "microsoft" /proc/version 2>/dev/null; then
        return 0
    fi
    if grep -qiE "WSL2|microsoft" /proc/sys/kernel/osrelease 2>/dev/null; then
        return 0
    fi
    return 1
}
