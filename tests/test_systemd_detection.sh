#!/bin/bash
# =============================================================================
# tests/test_systemd_detection.sh
# Smoke test: validar is_systemd() y wrappers svc_* de utils/core.sh
# =============================================================================
# La funcion is_systemd() decide entre dos rutas en TODOS los provisioners:
#   - Con systemd: systemctl
#   - Sin systemd: service / nginx -s reload / fail2ban-server -b / etc
# Es critica para WSL2 y contenedores.
#
# Tests:
#   1. is_systemd() retorna un valor sano (0 o 1, no error)
#   2. is_systemd() coincide con la deteccion via /run/systemd/system
#   3. svc_* wrappers tienen las ramas esperadas (nginx, fail2ban, sshd)
#   4. is_wsl2() de utils/validation.sh detecta correctamente
#
# Uso:
#   bash tests/test_systemd_detection.sh
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

assert_in_set() {
    local desc="$1" value="$2"; shift 2
    local found=false
    for v in "$@"; do
        [[ "$value" == "$v" ]] && found=true
    done
    if [[ "$found" == "true" ]]; then
        echo -e "  ${_CLR_GREEN}[PASS]${_CLR_RESET} ${desc} (got: ${value})"
        _PASS=$(( _PASS + 1 ))
    else
        echo -e "  ${_CLR_RED}[FAIL]${_CLR_RESET} ${desc} (got: ${value}, expected one of: $*)"
        _FAIL=$(( _FAIL + 1 ))
    fi
}

# =============================================================================
# Tests
# =============================================================================
echo ""
echo "test_systemd_detection.sh -- is_systemd, is_wsl2, svc_* wrappers"
echo ""

# Source utils en subshell para no contaminar el ambiente del test
echo "  Carga de utils:"
assert "utils/core.sh source-able" \
    bash -c "source '${PROJECT_ROOT}/utils/logging.sh' && source '${PROJECT_ROOT}/utils/core.sh'"

assert "utils/validation.sh source-able" \
    bash -c "source '${PROJECT_ROOT}/utils/logging.sh' && source '${PROJECT_ROOT}/utils/core.sh' && source '${PROJECT_ROOT}/utils/validation.sh'"

# is_systemd debe retornar 0 o 1 (no error). Lo ejecutamos y capturamos
# el codigo de salida directamente.
echo ""
echo "  is_systemd() comportamiento:"
result=$(bash -c "
    source '${PROJECT_ROOT}/utils/logging.sh' 2>/dev/null
    source '${PROJECT_ROOT}/utils/core.sh' 2>/dev/null
    is_systemd
    echo \$?
")
assert_in_set "is_systemd retorna 0 o 1" "$result" "0" "1"

# Coherencia con /run/systemd/system: si el directorio existe Y systemctl
# funciona, is_systemd debe retornar 0.
echo ""
echo "  Coherencia con /run/systemd/system:"
if [[ -d /run/systemd/system ]] && command -v systemctl >/dev/null 2>&1 \
   && systemctl is-system-running --quiet 2>/dev/null; then
    expected_systemd="0"
    echo -e "  ${_CLR_YELLOW}[INFO]${_CLR_RESET} entorno con systemd detectado"
else
    expected_systemd="1"
    echo -e "  ${_CLR_YELLOW}[INFO]${_CLR_RESET} entorno SIN systemd (contenedor/WSL2/CI)"
fi
assert "is_systemd coincide con el entorno" \
    test "$result" -eq "$expected_systemd"

# is_wsl2 -- igual, debe retornar 0 o 1
echo ""
echo "  is_wsl2() comportamiento:"
wsl_result=$(bash -c "
    source '${PROJECT_ROOT}/utils/logging.sh' 2>/dev/null
    source '${PROJECT_ROOT}/utils/core.sh' 2>/dev/null
    source '${PROJECT_ROOT}/utils/validation.sh' 2>/dev/null
    is_wsl2
    echo \$?
")
assert_in_set "is_wsl2 retorna 0 o 1" "$wsl_result" "0" "1"

# svc_* wrappers: comprobar que tienen las ramas case esperadas
# NOTA: usamos bash -c para pipelines (assert con "$@" no preserva pipes)
echo ""
echo "  Ramas case en svc_* wrappers:"
CORE_SH="${PROJECT_ROOT}/utils/core.sh"
assert "svc_start tiene rama nginx" \
    bash -c "grep -A 20 '^svc_start()' '$CORE_SH' | grep -q 'nginx)'"
assert "svc_stop tiene rama nginx con nginx -s quit" \
    bash -c "grep -A 20 '^svc_stop()' '$CORE_SH' | grep -q 'nginx -s quit'"
assert "svc_reload tiene rama nginx con nginx -s reload" \
    bash -c "grep -A 20 '^svc_reload()' '$CORE_SH' | grep -q 'nginx -s reload'"
assert "svc_restart tiene rama nginx" \
    bash -c "grep -A 30 '^svc_restart()' '$CORE_SH' | grep -q 'nginx)'"
assert "svc_start tiene rama fail2ban con fail2ban-server -b" \
    bash -c "grep -A 30 '^svc_start()' '$CORE_SH' | grep -q 'fail2ban-server -b'"
assert "svc_reload tiene rama sshd con SIGHUP" \
    bash -c "grep -A 30 '^svc_reload()' '$CORE_SH' | grep -q 'kill -HUP'"

# No deben quedar ramas apache2 (excepto comentarios documentales en header)
echo ""
echo "  Limpieza de Apache:"
# Solo lineas ejecutables (no comentarios)
apache_exec=$(grep -vE '^\s*#' "$CORE_SH" | grep -c "apache2)" || true)
if [[ "$apache_exec" == "0" ]]; then
    _PASS=$(( _PASS + 1 ))
    echo -e "  ${_CLR_GREEN}[PASS]${_CLR_RESET} cero ramas case 'apache2)' ejecutables en core.sh"
else
    _FAIL=$(( _FAIL + 1 ))
    echo -e "  ${_CLR_RED}[FAIL]${_CLR_RESET} ${apache_exec} ramas case 'apache2)' encontradas (deberia ser 0)"
fi

# =============================================================================
# Resumen
# =============================================================================
echo ""
echo "Resumen test_systemd_detection.sh:"
echo "  PASS: ${_PASS}"
echo "  FAIL: ${_FAIL}"
echo "  SKIP: ${_SKIP}"
echo ""

exit $(( _FAIL > 0 ? 1 : 0 ))
