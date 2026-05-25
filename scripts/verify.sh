#!/bin/bash
# =============================================================================
# scripts/verify.sh
# Verificacion completa del entorno de template-ecommerce-server
# =============================================================================
# Portado del referente jcg-admin/e-comerce-server/scripts/verify.sh
# (599 LOC, 13 checks) con adaptaciones documentadas en 8 hallazgos de
# inspeccion previa al codigo (F8 progreso).
#
# Comprueba en orden (11 checks; 13 del referente menos 2 eliminados
# por D-WS + D-BACKEND-AGNOSTIC):
#
#   1.  Variables requeridas en .env (7 vs 13 del referente; -6 Django)
#   2.  Nginx instalado y version >= 1.24 (vs Apache 2.4 del referente)
#   3.  Nginx activo en puerto 80
#   4.  SSL activo en puerto 443
#   5.  Certificado SSL -- dias restantes (WARN/ERR segun umbrales)
#   6.  API upstream responde (CONDICIONAL: si API_UPSTREAM vacio -> SKIP)
#   7.  Redirect HTTP -> HTTPS (301 con Location: https://)
#   8.  SPA catch-all activo (try_files en template-https.conf)
#   9.  Firewall UFW activo con SSH/HTTP/HTTPS permitidos
#   10. Privilegio minimo: cert key 0600 + workers Nginx no-root
#   11. fail2ban activo con 3 jails (sshd + nginx-limit-req + nginx-botsearch)
#   12. SSH hardening efectivo (PermitRootLogin no, PasswordAuthentication no)
#
# Eliminado vs referente:
#   - check_apache_modules: Nginx Ubuntu 24.04 trae modulos en core
#   - check_django_api con path /api/v1/auth/login/ (Django-especifico)
#     -- sustituido por check_api_upstream con path generico /api/
#
# Muestra resumen final con contadores OK / WARN / ERR.
# Retorna exit code 0 si ERR=0, 1 si hay algun error.
#
# Uso:
#   bash scripts/verify.sh
#
# Variables del .env consumidas:
#   DOMAIN, UI_DIST, API_UPSTREAM (puede vacio), SSL_EMAIL, SSL_CERT_DIR,
#   SSL_CERT_DAYS_WARN, SSL_CERT_DAYS_ERR, SSH_PORT
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export PROJECT_ROOT

source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/core.sh"
source "${PROJECT_ROOT}/utils/network.sh"
source "${PROJECT_ROOT}/utils/validation.sh"

init_log "operations"
# =============================================================================
ENV_FILE="${PROJECT_ROOT}/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    echo ""
    echo "  ERROR: Archivo .env no encontrado en ${PROJECT_ROOT}"
    echo "  Crea tu configuracion: cp .env.example .env"
    echo ""
    exit 1
fi
set -a; source "$ENV_FILE"; set +a

# Defaults para variables de umbral
SSL_CERT_DAYS_WARN="${SSL_CERT_DAYS_WARN:-30}"
SSL_CERT_DAYS_ERR="${SSL_CERT_DAYS_ERR:-7}"

# Defaults para SSH y fail2ban -- usados en checks 11 y 12
SSH_PORT="${SSH_PORT:-22}"

# Jails configuradas en setup_fail2ban.sh F6/T-601
readonly JAILS=("sshd" "nginx-limit-req" "nginx-botsearch")

# =============================================================================
# Contadores OK / WARN / ERR
# =============================================================================
_OK=0; _WARN=0; _ERR=0

ok()   { log_success "  [OK]   $1"; _OK=$(( _OK + 1 ));   }
warn() { log_warn    "  [WARN] $1"; _WARN=$(( _WARN + 1 )); }
fail() { log_error   "  [ERR]  $1"; _ERR=$(( _ERR + 1 ));  }

# =============================================================================
# Check 1: Variables de entorno requeridas
# Adaptado vs referente: 7 variables (sin Django/WSGI/STATIC/MEDIA)
# API_UPSTREAM se chequea presencia pero acepta vacio (D-BACKEND-AGNOSTIC).
# =============================================================================
check_env_vars() {
    log_header "PASO: Variables de entorno (.env)"

    local required=(
        "DOMAIN"
        "UI_DIST"
        "SSL_EMAIL"
        "SSL_CERT_DIR"
        "SSL_CERT_DAYS_WARN"
        "SSL_CERT_DAYS_ERR"
    )

    for var in "${required[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            ok "${var}=${!var}"
        else
            fail "${var} no definido o vacio en .env"
        fi
    done

    # API_UPSTREAM: la VARIABLE debe existir en .env (presente, aunque
    # sea vacia). Si esta vacia, el bloque /api/ del vhost esta
    # comentado (D-BACKEND-AGNOSTIC, F4 setup_vhost.sh logica).
    if [[ -n "${API_UPSTREAM:-}" ]]; then
        ok "API_UPSTREAM=${API_UPSTREAM}"
    elif declare -p API_UPSTREAM &>/dev/null; then
        warn "API_UPSTREAM vacio -- /api/ devuelve 404 (by design)"
        log_warn "  Configura .env y re-ejecuta setup_vhost.sh para activar"
    else
        fail "API_UPSTREAM no presente en .env"
        log_error "  Anade 'API_UPSTREAM=' a .env (puede quedar vacia)"
    fi
}

# =============================================================================
# Check 2: Nginx instalado y version >= 1.24
# =============================================================================
check_nginx_version() {
    log_header "PASO: Nginx instalado y version"

    if ! command_exists nginx; then
        fail "nginx no encontrado -- Nginx no esta instalado"
        log_error "  Instala con: sudo bash provisioners/nginx/install.sh"
        return
    fi

    if validate_nginx_version 1 24; then
        local version_str
        version_str=$(nginx -v 2>&1 \
            | grep -oE 'nginx/[0-9]+\.[0-9]+\.[0-9]+' | head -1 \
            | cut -d/ -f2)
        ok "Nginx ${version_str} instalado (>= 1.24)"
    else
        fail "Version de Nginx incorrecta"
        log_error "  Actualiza con: sudo bash provisioners/nginx/install.sh"
    fi
}

# =============================================================================
# Check 3: Nginx activo en puerto 80
# =============================================================================
check_nginx_port_80() {
    log_header "PASO: Nginx activo en puerto 80"

    if tcp_is_reachable "127.0.0.1" 80 3; then
        ok "Nginx responde en :80"
    else
        fail "Nginx no responde en :80"
        log_error "  Arranca con: sudo bash scripts/start.sh"
        log_error "  Estado: sudo systemctl status nginx  (o revisa logs en /var/log/nginx/)"
    fi
}

# =============================================================================
# Check 4: SSL activo en puerto 443
# =============================================================================
check_ssl_port_443() {
    log_header "PASO: SSL activo en puerto 443"

    if tcp_is_reachable "127.0.0.1" 443 3; then
        ok "SSL responde en :443"
    else
        fail "SSL no responde en :443"
        log_error "  Verifica el certificado: sudo bash provisioners/ssl/setup_ssl.sh"
        log_error "  Verifica el virtualhost: sudo bash provisioners/nginx/setup_vhost.sh"
    fi
}

# =============================================================================
# Check 5: Certificado SSL -- dias restantes
# =============================================================================
check_ssl_cert() {
    log_header "PASO: Certificado SSL -- dias restantes"

    local cert_file="${SSL_CERT_DIR}/cert.pem"

    # validate_ssl_cert retorna siempre 0 y exporta SSL_CERT_STATUS
    validate_ssl_cert "$cert_file" "$SSL_CERT_DAYS_WARN" "$SSL_CERT_DAYS_ERR"

    case "$SSL_CERT_STATUS" in
        OK)
            ok "Certificado SSL valido"
            ;;
        WARN)
            warn "Certificado proximo a vencer"
            log_warn "  Renueva con: bash scripts/renew_ssl.sh"
            ;;
        ERR)
            fail "Certificado vencido o no encontrado"
            log_error "  Renueva con: bash scripts/renew_ssl.sh"
            log_error "  O emite nuevo: sudo bash provisioners/ssl/setup_ssl.sh"
            ;;
    esac
}

# =============================================================================
# Check 6: API upstream responde (CONDICIONAL)
# Si API_UPSTREAM esta vacio -> SKIP con OK informativo (es un escenario
# valido en este server agnostic al backend; el bloque /api/ esta
# comentado en el vhost por setup_vhost.sh, asi /api/ devuelve 404).
#
# Si API_UPSTREAM tiene valor -> GET https://${DOMAIN}/api/ y validar:
#   2xx, 3xx, 4xx  -> OK (cualquier respuesta del backend prueba el proxy)
#   5xx, 000       -> FAIL (gateway error o backend caido)
# =============================================================================
check_api_upstream() {
    log_header "PASO: API upstream responde"

    if [[ -z "${API_UPSTREAM:-}" ]]; then
        ok "API_UPSTREAM vacio -- bloque /api/ comentado, no aplica check"
        log_info "  (escenario valido: server sirve UI sin backend, by design)"
        return
    fi

    if ! command_exists curl; then
        warn "curl no disponible -- check omitido"
        return
    fi

    local http_code
    http_code=$(curl \
        --silent \
        --max-time 10 \
        --insecure \
        --output /dev/null \
        --write-out "%{http_code}" \
        "https://${DOMAIN}/api/" 2>/dev/null \
        || true)
    [[ -z "$http_code" ]] && http_code="000"

    # 000 = conexion rechazada o timeout
    if [[ "$http_code" == "000" ]]; then
        fail "API upstream no responde (timeout o conexion rechazada)"
        log_error "  API_UPSTREAM=${API_UPSTREAM}"
        log_error "  Verifica que el backend esta activo y accesible desde Nginx"
        log_error "  Logs Nginx: sudo tail -f /var/log/nginx/template-https-error.log"
        return
    fi

    # 5xx = error del gateway / backend
    if [[ "${http_code:0:1}" == "5" ]]; then
        fail "API upstream error de gateway: HTTP ${http_code}"
        log_error "  502/503/504 = backend ${API_UPSTREAM} no responde correctamente"
        log_error "  Logs: sudo tail -f /var/log/nginx/template-https-error.log"
        return
    fi

    # 2xx/3xx/4xx = backend respondio (cualquier respuesta valida el proxy)
    ok "API upstream responde: HTTP ${http_code}"
}

# =============================================================================
# Check 7: Redirect HTTP -> HTTPS
# curl a http://DOMAIN/ debe retornar 301 con Location: https://
# =============================================================================
check_http_redirect() {
    log_header "PASO: Redirect HTTP -> HTTPS"

    if ! command_exists curl; then
        warn "curl no disponible -- check omitido"
        return
    fi

    # Intenta contra DOMAIN. Si falla por DNS (000), reintenta contra
    # localhost con el header Host: para simular la peticion correctamente.
    local http_code location_header target_url="http://${DOMAIN}/"

    http_code=$(curl \
        --silent --max-time 10 \
        --output /dev/null \
        --write-out "%{http_code}" \
        "$target_url" 2>/dev/null || true)
    [[ -z "$http_code" ]] && http_code="000"

    if [[ "$http_code" == "000" ]]; then
        log_warn "  DNS de ${DOMAIN} no resuelve -- reintentando contra localhost"
        log_warn "  (entorno de desarrollo: ${DOMAIN} no apunta a este servidor)"
        target_url="http://localhost/"
        http_code=$(curl \
            --silent --max-time 10 \
            --output /dev/null \
            --write-out "%{http_code}" \
            --header "Host: ${DOMAIN}" \
            "$target_url" 2>/dev/null || true)
        [[ -z "$http_code" ]] && http_code="000"
    fi

    if [[ "$http_code" == "000" ]]; then
        fail "No hay respuesta en http://${DOMAIN}/ ni en localhost (puerto 80)"
        log_error "  Nginx activo? sudo bash scripts/start.sh"
        return
    fi

    location_header=$(curl \
        --silent --max-time 10 --head \
        --header "Host: ${DOMAIN}" \
        "http://localhost/" 2>/dev/null \
        | grep -i "^location:" | head -1 || echo "")

    if [[ "$http_code" != "301" ]]; then
        fail "Redirect HTTP -> HTTPS no es 301 (obtenido: HTTP ${http_code})"
        log_error "  Verifica el virtualhost HTTP: config/nginx/template-http.conf"
        return
    fi

    if echo "$location_header" | grep -qi "https://"; then
        ok "Redirect HTTP -> HTTPS: 301 -> ${location_header#*: }"
    else
        fail "Redirect 301 pero Location no apunta a HTTPS: ${location_header}"
        log_error "  Verifica: config/nginx/template-http.conf"
    fi
}

# =============================================================================
# Check 8: SPA catch-all activo
# Una ruta inexistente debe retornar HTTP 200 (index.html del UI bundle).
# Implementado en Nginx via `try_files $uri $uri/ /index.html` en
# template-https.conf F3.
# =============================================================================
check_spa_catchall() {
    log_header "PASO: SPA catch-all activo"

    if ! command_exists curl; then
        warn "curl no disponible -- check omitido"
        return
    fi

    local test_path="/test-spa-catch-all-template-ecommerce-server"
    local http_code target_url="https://${DOMAIN}${test_path}"

    http_code=$(curl \
        --silent --max-time 10 --insecure \
        --output /dev/null \
        --write-out "%{http_code}" \
        "$target_url" 2>/dev/null || true)
    [[ -z "$http_code" ]] && http_code="000"

    if [[ "$http_code" == "000" ]]; then
        log_warn "  DNS de ${DOMAIN} no resuelve -- reintentando contra localhost"
        log_warn "  (entorno de desarrollo: ${DOMAIN} no apunta a este servidor)"
        target_url="https://localhost${test_path}"
        http_code=$(curl \
            --silent --max-time 10 --insecure \
            --output /dev/null \
            --write-out "%{http_code}" \
            --header "Host: ${DOMAIN}" \
            "$target_url" 2>/dev/null || true)
        [[ -z "$http_code" ]] && http_code="000"
    fi

    if [[ "$http_code" == "000" ]]; then
        fail "Sin respuesta en https://${DOMAIN}${test_path} ni en localhost"
        log_error "  Nginx activo? sudo bash scripts/start.sh"
        return
    fi

    if [[ "$http_code" == "200" ]]; then
        ok "SPA catch-all activo -- HTTP ${http_code} (try_files sirviendo index.html)"
    elif [[ "$http_code" == "404" ]]; then
        fail "SPA catch-all inactivo -- HTTP 404"
        log_error "  Posibles causas:"
        log_error "    - UI_DIST no apunta a un directorio con index.html"
        log_error "    - try_files mal configurado en config/nginx/template-https.conf"
        log_error "    - bundle UI no desplegado (ejecuta npm run build en template-ecommerce-ui)"
    else
        fail "SPA catch-all: respuesta inesperada -- HTTP ${http_code}"
        log_error "  Se esperaba HTTP 200 (catch-all) o HTTP 404 (sin catch-all)"
    fi
}

# =============================================================================
# Check 9: Firewall UFW activo con puertos correctos
# =============================================================================
check_firewall() {
    log_header "PASO: Firewall UFW -- puertos permitidos"

    if ! command_exists ufw; then
        warn "ufw no encontrado -- firewall no verificado"
        log_warn "  Instala con: sudo apt-get install ufw"
        log_warn "  Configura con: sudo bash provisioners/firewall/setup_firewall.sh"
        return
    fi

    # ufw status requiere privilegios de root. Si el script corre
    # como un usuario sin sudo (ej: deploy sin -s, develop), se omite
    # el check con un WARN explicativo en lugar de abortar el script.
    local ufw_output
    ufw_output=$(sudo ufw status 2>/dev/null || true)

    if [[ -z "$ufw_output" ]]; then
        warn "ufw status requiere privilegios -- check omitido"
        log_warn "  Verifica manualmente como root:"
        log_warn "    sudo ufw status"
        return
    fi

    local ufw_status_line
    ufw_status_line=$(echo "$ufw_output" | head -1)

    if ! echo "$ufw_status_line" | grep -q "Status: active"; then
        fail "UFW inactivo -- el servidor esta expuesto sin firewall"
        log_error "  Configura con: sudo bash provisioners/firewall/setup_firewall.sh"
        return
    fi
    ok "UFW activo"

    # SSH_PORT configurable -- default 22
    local required_ports=("$SSH_PORT" "80" "443")
    local port_names=("SSH(${SSH_PORT})" "HTTP(80)" "HTTPS(443)")

    local i=0
    for port in "${required_ports[@]}"; do
        if echo "$ufw_output" | grep -qE "^${port}[[:space:]]|^${port}/tcp[[:space:]]"; then
            ok "Puerto ${port_names[$i]} permitido en UFW"
        else
            fail "Puerto ${port_names[$i]} NO permitido en UFW"
            log_error "  Corrige con: sudo ufw allow ${port}/tcp"
        fi
        i=$(( i + 1 ))
    done
}

# =============================================================================
# Check 10: Privilegio minimo -- clave SSL y workers Nginx
# =============================================================================
check_min_privilege() {
    log_header "PASO: Privilegio minimo"

    # 10a. Permisos de la clave SSL privada -- debe ser 600 (solo root puede leer).
    # D-STORAGE: key.pem 0600 root:root. Nginx master root la lee antes
    # de fork-ear workers como www-data.
    local key_file="${SSL_CERT_DIR}/key.pem"

    if [[ ! -f "$key_file" ]]; then
        warn "Clave SSL no encontrada (${key_file}) -- check de permisos omitido"
    else
        # stat sobre key.pem (root:root 600) requiere sudo si el usuario
        # no tiene acceso de lectura al directorio /etc/ssl/DOMAIN/.
        local key_perms
        key_perms=$(sudo stat -c "%a" "$key_file" 2>/dev/null || true)
        if [[ -z "$key_perms" ]]; then
            warn "Permisos de clave SSL no verificados (requiere sudo)"
            log_warn "  Verifica manualmente: sudo stat -c '%a' ${key_file}"
            log_warn "  Debe ser 600"
        elif [[ "$key_perms" == "600" ]]; then
            ok "Clave SSL: permisos ${key_perms} (D-STORAGE compliant)"
        elif [[ "$key_perms" == "640" ]]; then
            warn "Clave SSL: permisos ${key_perms} -- D-STORAGE exige 600"
            log_warn "  Corrige con: sudo chmod 600 ${key_file}"
        else
            fail "Clave SSL: permisos ${key_perms} -- deben ser 600"
            log_error "  Corrige con: sudo chmod 600 ${key_file}"
            log_error "  Una clave con permisos abiertos expone el certificado SSL"
        fi
    fi

    # 10b. Workers Nginx no corren como root. Solo el proceso master
    # necesita root (bind a :80/:443 + leer key.pem). Los workers
    # heredan privilegios reducidos con `user www-data` (default
    # Ubuntu nginx.conf).
    local nginx_workers
    nginx_workers=$(ps -eo user,comm 2>/dev/null \
        | grep nginx \
        | grep -v "^root" \
        | awk '{print $1}' \
        | sort -u \
        | head -3 \
        || echo "")

    if [[ -z "$nginx_workers" ]]; then
        # Puede ser que Nginx no este corriendo o ps no muestre workers aun
        warn "No se pudo verificar el usuario de los workers Nginx"
        log_warn "  Verifica manualmente: ps -eo user,comm | grep nginx"
    else
        local worker_user
        worker_user=$(echo "$nginx_workers" | head -1)
        if [[ "$worker_user" == "root" ]]; then
            fail "Workers Nginx corriendo como root -- riesgo de seguridad"
            log_error "  Verifica directiva 'user' en /etc/nginx/nginx.conf"
            log_error "  Valor canonico Ubuntu: 'user www-data;'"
        else
            ok "Workers Nginx corriendo como ${worker_user} (no root)"
        fi
    fi
}

# =============================================================================
# Check 11: fail2ban activo con 3 jails
# Adaptado vs referente: 3 jails (sshd + 2 Nginx) vs 2 (sshd + apache-auth)
# =============================================================================
check_fail2ban() {
    log_header "PASO: fail2ban -- jails activas"

    # fail2ban no instalado -> warn, no fail. Es capa adicional, no critica.
    if ! command_exists fail2ban-client; then
        warn "fail2ban no instalado"
        log_warn "  Instala con: sudo bash provisioners/security/setup_fail2ban.sh"
        return
    fi

    # Verificar que el servicio esta activo.
    # svc_is_active usa 'service fail2ban status' sin systemd, lo que
    # puede requerir root. Usamos sudo con fallback graceful.
    local fail2ban_active=false
    if sudo svc_is_active fail2ban 2>/dev/null; then
        fail2ban_active=true
    elif svc_is_active fail2ban 2>/dev/null; then
        fail2ban_active=true
    fi

    if [[ "$fail2ban_active" == "false" ]]; then
        fail "fail2ban instalado pero inactivo"
        log_error "  Arranca con: sudo bash scripts/start.sh"
        log_error "  O reconfigura: sudo bash provisioners/security/setup_fail2ban.sh"
        return
    fi
    ok "fail2ban activo"

    # Verificar jails -- fail2ban-client status requiere root
    local socket_accessible=false
    if fail2ban-client status &>/dev/null; then
        socket_accessible=true
    fi

    if [[ "$socket_accessible" == "false" ]]; then
        warn "fail2ban corriendo -- jails no verificadas (ejecuta con sudo)"
        for jail in "${JAILS[@]}"; do
            log_warn "  sudo fail2ban-client status ${jail}"
        done
        return
    fi

    # Con acceso al socket, verificar cada jail
    for jail in "${JAILS[@]}"; do
        if fail2ban-client status "$jail" &>/dev/null; then
            ok "Jail '${jail}' activa"
        else
            fail "Jail '${jail}' no activa"
            log_error "  Reconfigura: sudo bash provisioners/security/setup_fail2ban.sh"
        fi
    done
}

# =============================================================================
# Check 12: SSH hardening efectivo
# Usa sshd -T que vuelca la configuracion efectiva incluyendo overrides
# =============================================================================
check_ssh_hardening() {
    log_header "PASO: SSH hardening -- configuracion efectiva"

    if ! command_exists sshd; then
        warn "sshd no encontrado -- check omitido (entorno sin SSH nativo, e.g. WSL2)"
        return
    fi

    # sshd -T vuelca la configuracion efectiva incluyendo sshd_config.d/*.conf
    local sshd_config
    sshd_config=$(sshd -T 2>/dev/null)

    if [[ -z "$sshd_config" ]]; then
        warn "sshd -T no retorno configuracion -- check omitido"
        return
    fi

    # 12a. Puerto SSH no estandar
    local effective_port
    effective_port=$(echo "$sshd_config" | grep "^port " | awk '{print $2}')

    if [[ "$effective_port" == "$SSH_PORT" && "$SSH_PORT" != "22" ]]; then
        ok "SSH Puerto: ${effective_port} (no estandar)"
    elif [[ "$effective_port" == "22" ]]; then
        warn "SSH Puerto: 22 (estandar -- recomendado cambiarlo)"
        log_warn "  Configura SSH_PORT en .env y ejecuta:"
        log_warn "    sudo bash provisioners/security/setup_ssh_hardening.sh"
        log_warn "    sudo bash provisioners/firewall/setup_firewall.sh"
    else
        ok "SSH Puerto: ${effective_port}"
    fi

    # 12b. PermitRootLogin
    local effective_rootlogin
    effective_rootlogin=$(echo "$sshd_config" | grep "^permitrootlogin " | awk '{print $2}')

    if [[ "$effective_rootlogin" == "no" ]]; then
        ok "PermitRootLogin: no"
    else
        fail "PermitRootLogin: ${effective_rootlogin:-<no configurado>} (debe ser 'no')"
        log_error "  Aplica: sudo bash provisioners/security/setup_ssh_hardening.sh"
    fi

    # 12c. PasswordAuthentication
    local effective_passauth
    effective_passauth=$(echo "$sshd_config" | grep "^passwordauthentication " | awk '{print $2}')

    if [[ "$effective_passauth" == "no" ]]; then
        ok "PasswordAuthentication: no"
    else
        fail "PasswordAuthentication: ${effective_passauth:-<no configurado>} (debe ser 'no')"
        log_error "  Aplica: sudo bash provisioners/security/setup_ssh_hardening.sh"
        log_error "  ANTES verifica que tienes clave SSH autorizada en ~/.ssh/authorized_keys"
    fi
}

# =============================================================================
# MAIN
# =============================================================================
log_header "template-ecommerce-server -- Verificacion completa"
log_info "  Dominio: ${DOMAIN:-<no definido>}"
echo ""

check_env_vars;        echo ""
check_nginx_version;   echo ""
check_nginx_port_80;   echo ""
check_ssl_port_443;    echo ""
check_ssl_cert;        echo ""
check_api_upstream;    echo ""
check_http_redirect;   echo ""
check_spa_catchall;    echo ""
check_firewall;        echo ""
check_min_privilege;   echo ""
check_fail2ban;        echo ""
check_ssh_hardening;   echo ""

# =============================================================================
# Resumen
# =============================================================================
log_separator 60 "="
echo ""
log_success  "OK:           ${_OK}"
if [[ $_WARN -gt 0 ]]; then
    log_warn    "Advertencias: ${_WARN}"
else
    log_success "Advertencias: ${_WARN}"
fi
if [[ $_ERR -gt 0 ]]; then
    log_error   "Errores:      ${_ERR}"
else
    log_success "Errores:      ${_ERR}"
fi
echo ""

if [[ $_ERR -eq 0 && $_WARN -eq 0 ]]; then
    log_success "Entorno listo para produccion."
elif [[ $_ERR -eq 0 ]]; then
    log_warn "Entorno funcional con advertencias -- revisa los items marcados WARN."
else
    log_error "Entorno incompleto -- corrige los errores antes de usar en produccion."
fi

exit $(( _ERR > 0 ? 1 : 0 ))
