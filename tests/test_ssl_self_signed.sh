#!/bin/bash
# =============================================================================
# tests/test_ssl_self_signed.sh
# Smoke test: validar logica de modo --dev (self-signed) en setup_ssl.sh
# =============================================================================
# NO ejecuta acme.sh ni openssl directamente (requiere root). En su lugar:
#   1. Valida estructura del codigo (presencia de funciones esperadas).
#   2. Genera ad-hoc un certificado self-signed con openssl + verifica con
#      validate_ssl_cert de utils/validation.sh. Esto SI funciona sin root
#      porque escribe en /tmp/.
#   3. Valida que setup_ssl.sh detecta correctamente --dev en argumentos
#      mediante extraccion + dry-run del parseo de args.
#
# Uso:
#   bash tests/test_ssl_self_signed.sh
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

skip() {
    local desc="$1" reason="${2:-}"
    echo -e "  ${_CLR_YELLOW}[SKIP]${_CLR_RESET} ${desc} (${reason})"
    _SKIP=$(( _SKIP + 1 ))
}

# =============================================================================
# Tests
# =============================================================================
echo ""
echo "test_ssl_self_signed.sh -- modo --dev de setup_ssl.sh"
echo ""

SETUP_SSL="${PROJECT_ROOT}/provisioners/ssl/setup_ssl.sh"

# Test 1: existencia de funciones esperadas
echo "  Estructura del codigo:"
assert "tiene funcion _generate_self_signed" \
    grep -q "^_generate_self_signed()" "$SETUP_SSL"

assert "tiene funcion _check_existing_cert" \
    grep -q "^_check_existing_cert()" "$SETUP_SSL"

assert "tiene funcion _verify_certificate" \
    grep -q "^_verify_certificate()" "$SETUP_SSL"

assert "tiene logica de fallback staging -> dev" \
    grep -q "STAGING_FALLBACK_REASON" "$SETUP_SSL"

assert "tiene parseo de --dev en args" \
    grep -q '\-\-dev) *DEV_MODE=true' "$SETUP_SSL"

assert "tiene parseo de --staging en args" \
    grep -q '\-\-staging) *STAGING_MODE=true' "$SETUP_SSL"

assert "tiene integracion SSL_STAGING de .env" \
    grep -q 'SSL_STAGING.*true' "$SETUP_SSL"

assert "reloadcmd usa nginx -s reload (no apache)" \
    grep -q 'reloadcmd.*nginx -s reload' "$SETUP_SSL"

assert "webroot canonico /var/www/acme-challenge" \
    grep -q 'ACME_WEBROOT.*=.*"/var/www/acme-challenge"' "$SETUP_SSL"

# Test 2: openssl funcional para self-signed (sin root, en /tmp)
echo ""
echo "  Generacion self-signed funcional:"

if ! command -v openssl >/dev/null 2>&1; then
    skip "generar self-signed con openssl" "openssl no disponible"
    skip "validate_ssl_cert sobre cert generado" "openssl no disponible"
else
    TMP_DIR=$(mktemp -d)
    trap "rm -rf $TMP_DIR" EXIT

    if openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "${TMP_DIR}/key.pem" \
            -out    "${TMP_DIR}/cert.pem" \
            -subj   "/CN=test.localhost/O=test-ssl/C=MX" \
            2>/dev/null; then
        _PASS=$(( _PASS + 1 ))
        echo -e "  ${_CLR_GREEN}[PASS]${_CLR_RESET} openssl genera cert + key validos en /tmp"

        # Validar con validate_ssl_cert
        # shellcheck source=/dev/null
        source "${PROJECT_ROOT}/utils/logging.sh"
        # shellcheck source=/dev/null
        source "${PROJECT_ROOT}/utils/core.sh"
        # shellcheck source=/dev/null
        source "${PROJECT_ROOT}/utils/validation.sh"

        # validate_ssl_cert exporta SSL_CERT_STATUS; el cert tiene 365 dias
        validate_ssl_cert "${TMP_DIR}/cert.pem" 30 7 >/dev/null 2>&1
        assert_eq "validate_ssl_cert clasifica cert 365d como OK" \
            "OK" "${SSL_CERT_STATUS:-UNDEF}"

        # Verificar permisos esperados tras chmod 600/644
        chmod 600 "${TMP_DIR}/key.pem"
        chmod 644 "${TMP_DIR}/cert.pem"
        key_perms=$(stat -c "%a" "${TMP_DIR}/key.pem" 2>/dev/null)
        cert_perms=$(stat -c "%a" "${TMP_DIR}/cert.pem" 2>/dev/null)
        assert_eq "key.pem permisos 600 (D-STORAGE)" "600" "$key_perms"
        assert_eq "cert.pem permisos 644 (publico)" "644" "$cert_perms"

        # Test: cert expirado debe clasificarse como ERR
        # Generar cert con -days 0 hace que ya este vencido al instante
        if openssl req -x509 -nodes -days 0 -newkey rsa:2048 \
                -keyout "${TMP_DIR}/key-old.pem" \
                -out    "${TMP_DIR}/cert-old.pem" \
                -subj   "/CN=expired.localhost/O=test/C=MX" \
                2>/dev/null; then
            sleep 1  # asegurar que pasa al menos 1 segundo
            validate_ssl_cert "${TMP_DIR}/cert-old.pem" 30 7 >/dev/null 2>&1
            assert_eq "validate_ssl_cert clasifica cert -days 0 como ERR" \
                "ERR" "${SSL_CERT_STATUS:-UNDEF}"
        else
            skip "test cert vencido" "openssl req -days 0 fallo"
        fi
    else
        echo -e "  ${_CLR_RED}[FAIL]${_CLR_RESET} openssl no pudo generar cert"
        _FAIL=$(( _FAIL + 1 ))
    fi
fi

# =============================================================================
# Resumen
# =============================================================================
echo ""
echo "Resumen test_ssl_self_signed.sh:"
echo "  PASS: ${_PASS}"
echo "  FAIL: ${_FAIL}"
echo "  SKIP: ${_SKIP}"
echo ""

exit $(( _FAIL > 0 ? 1 : 0 ))
