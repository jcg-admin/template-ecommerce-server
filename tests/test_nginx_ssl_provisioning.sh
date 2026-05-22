#!/bin/bash
# =============================================================================
# tests/test_nginx_ssl_provisioning.sh
# Smoke test: integracion Nginx + SSL (templates + setup_vhost logic)
# =============================================================================
# Valida la cadena F3 (templates Nginx) + F4 (setup_vhost.sh) + F5 (SSL):
#
#   1. Templates contienen los placeholders esperados
#   2. Reemplazo de placeholders con valores reales produce config valido
#      (cero placeholders %%X%% remanentes excluyendo comentarios)
#   3. Caso API_UPSTREAM vacio: el bloque location /api/ queda comentado
#   4. Caso API_UPSTREAM con valor: el bloque location /api/ queda activo
#   5. Headers de seguridad re-declarados en cada location con add_header
#
# NO ejecuta setup_vhost.sh completo (requiere root + nginx). Extrae la
# logica de _substitute_vars mediante simulacion con sed.
#
# Uso:
#   bash tests/test_nginx_ssl_provisioning.sh
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -t 1 ]]; then
    _CLR_RESET="\033[0m"; _CLR_GREEN="\033[0;32m"; _CLR_RED="\033[0;31m"
    _CLR_YELLOW="\033[0;33m"
else
    _CLR_RESET=""; _CLR_GREEN=""; _CLR_RED=""; _CLR_YELLOW=""
fi

_PASS=0; _FAIL=0; _SKIP=0

assert() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo -e "  ${_CLR_GREEN}[PASS]${_CLR_RESET} ${desc}"
        _PASS=$(( _PASS + 1 ))
    else
        echo -e "  ${_CLR_RED}[FAIL]${_CLR_RESET} ${desc}"
        _FAIL=$(( _FAIL + 1 ))
    fi
}

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo -e "  ${_CLR_GREEN}[PASS]${_CLR_RESET} ${desc}"
        _PASS=$(( _PASS + 1 ))
    else
        echo -e "  ${_CLR_RED}[FAIL]${_CLR_RESET} ${desc}"
        echo -e "         expected: '${expected}'"
        echo -e "         actual:   '${actual}'"
        _FAIL=$(( _FAIL + 1 ))
    fi
}

# =============================================================================
# Tests
# =============================================================================
echo ""
echo "test_nginx_ssl_provisioning.sh -- templates + sustitucion + /api/ logic"
echo ""

TEMPLATE_HTTP="${PROJECT_ROOT}/config/nginx/template-http.conf"
TEMPLATE_HTTPS="${PROJECT_ROOT}/config/nginx/template-https.conf"

# Test 1: templates existen
echo "  Existencia de templates:"
assert "template-http.conf existe" test -f "$TEMPLATE_HTTP"
assert "template-https.conf existe" test -f "$TEMPLATE_HTTPS"

# Test 2: placeholders esperados en cada template
echo ""
echo "  Placeholders en template-http.conf:"
http_placeholders=$(grep -vE '^[[:space:]]*#' "$TEMPLATE_HTTP" \
                      | grep -oE '%%[A-Z_]+%%' \
                      | sort -u \
                      | tr '\n' ' ')
assert_eq "template-http.conf placeholders" "%%DOMAIN%% " "$http_placeholders"

echo ""
echo "  Placeholders en template-https.conf:"
https_placeholders=$(grep -vE '^[[:space:]]*#' "$TEMPLATE_HTTPS" \
                       | grep -oE '%%[A-Z_]+%%' \
                       | sort -u \
                       | tr '\n' ' ')
assert_eq "template-https.conf placeholders" \
    "%%API_UPSTREAM%% %%DOMAIN%% %%SSL_CERT_DIR%% %%UI_DIST%% " \
    "$https_placeholders"

# Test 3: sustitucion completa caso API_UPSTREAM con valor
echo ""
echo "  Sustitucion CON API_UPSTREAM seteado:"
TMP=$(mktemp)
trap "rm -f $TMP" EXIT

cp "$TEMPLATE_HTTPS" "$TMP"

DOMAIN="test.example.com"
UI_DIST="/srv/test/dist"
API_UPSTREAM="http://127.0.0.1:8000"
SSL_CERT_DIR="/etc/ssl/test"

sed -i \
    -e "s|%%DOMAIN%%|${DOMAIN}|g" \
    -e "s|%%UI_DIST%%|${UI_DIST}|g" \
    -e "s|%%API_UPSTREAM%%|${API_UPSTREAM}|g" \
    -e "s|%%SSL_CERT_DIR%%|${SSL_CERT_DIR}|g" \
    "$TMP"

remaining=$(grep -vE '^[[:space:]]*#' "$TMP" | grep -oE '%%[A-Z_]+%%' | sort -u | wc -l)
assert_eq "cero placeholders remanentes" "0" "$remaining"

# proxy_pass debe contener el valor
assert "proxy_pass tiene URL http://127.0.0.1:8000" \
    grep -q "proxy_pass.*http://127.0.0.1:8000" "$TMP"

# server_name debe contener DOMAIN
assert "server_name = test.example.com" \
    grep -q "server_name.*test\.example\.com" "$TMP"

# Test 4: caso API_UPSTREAM vacio -> bloque /api/ comentado
echo ""
echo "  Sustitucion SIN API_UPSTREAM (bloque /api/ comentado):"
cp "$TEMPLATE_HTTPS" "$TMP"

# Aplicar la logica de _substitute_vars con API_UPSTREAM vacio:
# 1. Comentar el bloque location /api/
sed -i '/^    location ^~ \/api\//,/^    }/ {
    s/^/# /
}' "$TMP"

# 2. Sustituir el resto con valor dummy para API_UPSTREAM
DOMAIN_EMPTY="test2.example.com"
UI_DIST_EMPTY="/srv/test2"
API_UPSTREAM_EMPTY="http://127.0.0.1:1"
SSL_CERT_DIR_EMPTY="/etc/ssl/test2"

sed -i \
    -e "s|%%DOMAIN%%|${DOMAIN_EMPTY}|g" \
    -e "s|%%UI_DIST%%|${UI_DIST_EMPTY}|g" \
    -e "s|%%API_UPSTREAM%%|${API_UPSTREAM_EMPTY}|g" \
    -e "s|%%SSL_CERT_DIR%%|${SSL_CERT_DIR_EMPTY}|g" \
    "$TMP"

# Verificar: la linea con proxy_pass debe estar comentada
# Buscamos: linea con "proxy_pass" precedida por "#"
api_block_commented=$(grep -E "^# +proxy_pass" "$TMP" | wc -l)
assert "linea proxy_pass dentro de /api/ esta comentada" \
    test "$api_block_commented" -ge 1

# El bloque location ^~ /api/ debe estar comentado
api_location_commented=$(grep -cE "^# +location \^~ /api/" "$TMP")
assert_eq "linea de apertura del location /api/ comentada" "1" "$api_location_commented"

# Despues de los reemplazos, NO debe quedar %%API_UPSTREAM%%
# (ni siquiera comentado, porque el sed sustituyo el placeholder global)
api_placeholder_remaining=$(grep -cE "%%API_UPSTREAM%%" "$TMP")
assert_eq "cero %%API_UPSTREAM%% libres tras sed dummy" "0" "$api_placeholder_remaining"

# Test 5: headers de seguridad re-declarados en cada location con add_header
echo ""
echo "  Headers de seguridad (idiosincrasia Nginx):"
hsts_count=$(grep -c "Strict-Transport-Security" "$TEMPLATE_HTTPS")
assert "HSTS aparece >=3 veces (global + assets + catch-all)" \
    test "$hsts_count" -ge 3

xframe_count=$(grep -c "X-Frame-Options" "$TEMPLATE_HTTPS")
assert "X-Frame-Options aparece >=3 veces" \
    test "$xframe_count" -ge 3

# Test 6: orden critico de locations (ACME antes que catch-all)
echo ""
echo "  Orden de locations:"
acme_line=$(grep -n "location.*acme-challenge" "$TEMPLATE_HTTP" | head -1 | cut -d: -f1)
catchall_line=$(grep -n "location / {" "$TEMPLATE_HTTP" | head -1 | cut -d: -f1)
if [[ -n "$acme_line" && -n "$catchall_line" && "$acme_line" -lt "$catchall_line" ]]; then
    _PASS=$(( _PASS + 1 ))
    echo -e "  ${_CLR_GREEN}[PASS]${_CLR_RESET} ACME location (linea ${acme_line}) declarada ANTES que / (linea ${catchall_line}) en template-http"
else
    _FAIL=$(( _FAIL + 1 ))
    echo -e "  ${_CLR_RED}[FAIL]${_CLR_RESET} orden de locations incorrecto en template-http"
fi

# =============================================================================
# Resumen
# =============================================================================
echo ""
echo "Resumen test_nginx_ssl_provisioning.sh:"
echo "  PASS: ${_PASS}"
echo "  FAIL: ${_FAIL}"
echo "  SKIP: ${_SKIP}"
echo ""

exit $(( _FAIL > 0 ? 1 : 0 ))
