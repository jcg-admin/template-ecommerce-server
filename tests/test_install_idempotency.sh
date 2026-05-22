#!/bin/bash
# =============================================================================
# tests/test_install_idempotency.sh
# Smoke test: comprobar que los install scripts tienen logica de idempotencia
# =============================================================================
# NO ejecuta `apt-get install nginx` (requiere root + red en Ubuntu real).
# En su lugar, valida que el codigo de cada provisioner CONTIENE los patrones
# de idempotencia esperados:
#
#   1. install.sh:        funcion _check_current_version + exit 0 escenario B
#   2. setup_vhost.sh:    verificacion de existencia de archivos antes de
#                          escribir; symlinks creados con `ln -sf`
#   3. setup_ssl.sh:      escenario A (cert OK -> exit 0)
#   4. setup_fail2ban.sh: _check_current_state con exit 0 si config + jails
#                          coinciden
#   5. setup_ssh_hardening.sh: _check_current_state con exit 0 si sshd -T
#                              ya tiene los valores correctos
#   6. setup_firewall.sh: _check_current_state con exit 0 si UFW activo
#                          con las 3 reglas
#
# Test estructural, no runtime. La idempotencia REAL ocurre cuando un
# operador re-ejecuta el script en un VPS Ubuntu real.
#
# Uso:
#   bash tests/test_install_idempotency.sh
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

assert_contains() {
    local desc="$1" file="$2" pattern="$3"
    if grep -qE "$pattern" "$file" 2>/dev/null; then
        echo -e "  ${_CLR_GREEN}[PASS]${_CLR_RESET} ${desc}"
        _PASS=$(( _PASS + 1 ))
    else
        echo -e "  ${_CLR_RED}[FAIL]${_CLR_RESET} ${desc}"
        echo -e "         pattern: ${pattern}"
        echo -e "         file:    ${file}"
        _FAIL=$(( _FAIL + 1 ))
    fi
}

# =============================================================================
# Tests
# =============================================================================
echo ""
echo "test_install_idempotency.sh -- patrones de idempotencia"
echo ""

# 1. install.sh nginx
echo "  Provisioner: nginx/install.sh"
assert_contains "tiene funcion _check_current_version" \
    "${PROJECT_ROOT}/provisioners/nginx/install.sh" \
    "^_check_current_version\(\)"

assert_contains "exit 0 si version ya correcta (escenario B)" \
    "${PROJECT_ROOT}/provisioners/nginx/install.sh" \
    "Sin cambios.*Nginx.*ya instalado|ya instalado.*Sin cambios"

assert_contains "backup de /etc/nginx antes de purgar" \
    "${PROJECT_ROOT}/provisioners/nginx/install.sh" \
    "_backup_nginx_config"

# 2. setup_vhost.sh
echo ""
echo "  Provisioner: nginx/setup_vhost.sh"
assert_contains "verifica si template existe antes de copiar" \
    "${PROJECT_ROOT}/provisioners/nginx/setup_vhost.sh" \
    "Template no encontrado"

assert_contains "symlinks con ln -sf (idempotente)" \
    "${PROJECT_ROOT}/provisioners/nginx/setup_vhost.sh" \
    "ln -sf"

assert_contains "_revert en caso de nginx -t fallido" \
    "${PROJECT_ROOT}/provisioners/nginx/setup_vhost.sh" \
    "^_revert\(\)"

# 3. setup_ssl.sh
echo ""
echo "  Provisioner: ssl/setup_ssl.sh"
assert_contains "escenario A: cert OK -> exit 0" \
    "${PROJECT_ROOT}/provisioners/ssl/setup_ssl.sh" \
    "Escenario A.*exit 0|sin accion requerida.*Escenario A"

assert_contains "_check_existing_cert clasifica OK/WARN/ERR" \
    "${PROJECT_ROOT}/provisioners/ssl/setup_ssl.sh" \
    "case.*SSL_CERT_STATUS"

assert_contains "normalizacion de mode 0755 (idempotencia segunda iteracion)" \
    "${PROJECT_ROOT}/provisioners/ssl/setup_ssl.sh" \
    "normalizando a 755|chmod 0755"

# 4. setup_fail2ban.sh
echo ""
echo "  Provisioner: security/setup_fail2ban.sh"
assert_contains "_check_current_state compara config esperada vs actual" \
    "${PROJECT_ROOT}/provisioners/security/setup_fail2ban.sh" \
    "expected.*current|current.*expected"

assert_contains "exit 0 si config + jails activas correctas" \
    "${PROJECT_ROOT}/provisioners/security/setup_fail2ban.sh" \
    "sin cambios"

# 5. setup_ssh_hardening.sh
echo ""
echo "  Provisioner: security/setup_ssh_hardening.sh"
assert_contains "_check_current_state usa sshd -T" \
    "${PROJECT_ROOT}/provisioners/security/setup_ssh_hardening.sh" \
    "sshd -T"

assert_contains "exit 0 si hardening ya correcto" \
    "${PROJECT_ROOT}/provisioners/security/setup_ssh_hardening.sh" \
    "ya tiene el hardening correcto"

assert_contains "lockout guard via _check_authorized_keys" \
    "${PROJECT_ROOT}/provisioners/security/setup_ssh_hardening.sh" \
    "^_check_authorized_keys\(\)"

# 6. setup_firewall.sh
echo ""
echo "  Provisioner: firewall/setup_firewall.sh"
assert_contains "_check_current_state verifica UFW activo + reglas" \
    "${PROJECT_ROOT}/provisioners/firewall/setup_firewall.sh" \
    "Status: active"

assert_contains "exit 0 si reglas ya presentes" \
    "${PROJECT_ROOT}/provisioners/firewall/setup_firewall.sh" \
    "sin cambios"

assert_contains "_ufw_has_rule funcion auxiliar de verificacion" \
    "${PROJECT_ROOT}/provisioners/firewall/setup_firewall.sh" \
    "^_ufw_has_rule\(\)"

# =============================================================================
# Resumen
# =============================================================================
echo ""
echo "Resumen test_install_idempotency.sh:"
echo "  PASS: ${_PASS}"
echo "  FAIL: ${_FAIL}"
echo "  SKIP: ${_SKIP}"
echo ""

exit $(( _FAIL > 0 ? 1 : 0 ))
