#!/bin/bash
# =============================================================================
# tests/test_logging.sh
# Smoke test: verificar la implementacion de logging a archivo
# =============================================================================
# Comprueba que init_log esta activado en todos los scripts y provisioners,
# que .gitignore ignora los .log pero no .gitkeep, y que init_log produce
# el formato de log correcto al ser llamada directamente.
#
# Tests estructurales (grep sobre codigo fuente) + 1 test funcional
# (ejecutar init_log en /tmp y verificar el output).
#
# NO requiere root ni red. Hermetico: limpia /tmp tras ejecutar.
#
# Cobertura:
#   1.  init_log presente en los 4 scripts de scripts/
#   2.  init_log presente en los 6 provisioners
#   3.  init_log aparece DESPUES del ultimo source de utils (orden correcto)
#   4.  .gitignore tiene logs/*.log (ignora archivos .log)
#   5.  .gitignore tiene !logs/.gitkeep (excepcion para .gitkeep)
#   6.  .gitignore NO tiene la entrada 'logs/' que ignoraria .gitkeep
#   7.  logs/.gitkeep existe en el repo
#   8.  init_log crea el archivo con el separador === Inicio ===
#   9.  Dos llamadas consecutivas acumulan dos bloques en el mismo archivo
#   10. El archivo de log no contiene codigos de color ANSI
#
# Uso:
#   bash tests/test_logging.sh
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

assert_not_contains() {
    local desc="$1" file="$2" pattern="$3"
    if ! grep -qE "$pattern" "$file" 2>/dev/null; then
        echo -e "  ${_CLR_GREEN}[PASS]${_CLR_RESET} ${desc}"
        _PASS=$(( _PASS + 1 ))
    else
        echo -e "  ${_CLR_RED}[FAIL]${_CLR_RESET} ${desc}"
        echo -e "         pattern presente (no debia): ${pattern}"
        echo -e "         file: ${file}"
        _FAIL=$(( _FAIL + 1 ))
    fi
}

assert_file_exists() {
    local desc="$1" file="$2"
    if [[ -f "$file" ]]; then
        echo -e "  ${_CLR_GREEN}[PASS]${_CLR_RESET} ${desc}"
        _PASS=$(( _PASS + 1 ))
    else
        echo -e "  ${_CLR_RED}[FAIL]${_CLR_RESET} ${desc}"
        echo -e "         archivo no encontrado: ${file}"
        _FAIL=$(( _FAIL + 1 ))
    fi
}

assert_init_log_after_source() {
    # Verifica que init_log aparece DESPUES del ultimo source de utils
    # en el archivo dado. Patron: source utils -> ... -> init_log "operations"
    local desc="$1" file="$2"
    local last_source_line init_log_line
    last_source_line=$(grep -n 'source.*utils' "$file" 2>/dev/null | tail -1 | cut -d: -f1)
    init_log_line=$(grep -n 'init_log "operations"' "$file" 2>/dev/null | head -1 | cut -d: -f1)

    if [[ -z "$last_source_line" || -z "$init_log_line" ]]; then
        echo -e "  ${_CLR_RED}[FAIL]${_CLR_RESET} ${desc}"
        echo -e "         source linea: ${last_source_line:-<no encontrado>}"
        echo -e "         init_log linea: ${init_log_line:-<no encontrado>}"
        _FAIL=$(( _FAIL + 1 ))
        return
    fi

    if (( init_log_line > last_source_line )); then
        echo -e "  ${_CLR_GREEN}[PASS]${_CLR_RESET} ${desc}"
        _PASS=$(( _PASS + 1 ))
    else
        echo -e "  ${_CLR_RED}[FAIL]${_CLR_RESET} ${desc}"
        echo -e "         init_log (linea ${init_log_line}) debe estar DESPUES del ultimo source (linea ${last_source_line})"
        _FAIL=$(( _FAIL + 1 ))
    fi
}

# =============================================================================
# Tests
# =============================================================================
echo ""
echo "test_logging.sh -- logging a archivo (init_log)"
echo ""

# --- Seccion 1: init_log en scripts/ ---
echo "  init_log en scripts/:"

for script in setup.sh start.sh verify.sh renew_ssl.sh; do
    assert_contains \
        "scripts/${script} tiene init_log \"operations\"" \
        "${PROJECT_ROOT}/scripts/${script}" \
        'init_log "operations"'
done

# --- Seccion 2: init_log en provisioners/ ---
echo ""
echo "  init_log en provisioners/:"

for provisioner in \
    provisioners/nginx/install.sh \
    provisioners/nginx/setup_vhost.sh \
    provisioners/ssl/setup_ssl.sh \
    provisioners/security/setup_fail2ban.sh \
    provisioners/security/setup_ssh_hardening.sh \
    provisioners/firewall/setup_firewall.sh; do
    assert_contains \
        "${provisioner} tiene init_log \"operations\"" \
        "${PROJECT_ROOT}/${provisioner}" \
        'init_log "operations"'
done

# --- Seccion 3: orden correcto (init_log despues de source) ---
echo ""
echo "  Orden correcto (init_log despues del ultimo source):"

for f in \
    scripts/setup.sh \
    scripts/start.sh \
    scripts/verify.sh \
    scripts/renew_ssl.sh \
    provisioners/nginx/install.sh \
    provisioners/security/setup_fail2ban.sh; do
    assert_init_log_after_source \
        "${f}: init_log despues del ultimo source utils" \
        "${PROJECT_ROOT}/${f}"
done

# --- Seccion 4: .gitignore correcto ---
echo ""
echo "  .gitignore:"

assert_contains \
    ".gitignore tiene logs/*.log" \
    "${PROJECT_ROOT}/.gitignore" \
    'logs/\*\.log'

assert_contains \
    ".gitignore tiene !logs/.gitkeep (excepcion)" \
    "${PROJECT_ROOT}/.gitignore" \
    '!logs/\.gitkeep'

assert_not_contains \
    ".gitignore NO tiene entrada 'logs/' que ignoraria .gitkeep" \
    "${PROJECT_ROOT}/.gitignore" \
    '^logs/$'

# --- Seccion 5: logs/.gitkeep existe ---
echo ""
echo "  Directorio logs/:"

assert_file_exists \
    "logs/.gitkeep existe en el repo" \
    "${PROJECT_ROOT}/logs/.gitkeep"

# --- Seccion 6: test funcional de init_log ---
echo ""
echo "  Test funcional de init_log:"

_TMP_LOG_DIR=$(mktemp -d)
_TMP_LOG="${_TMP_LOG_DIR}/logs/operations.log"
mkdir -p "${_TMP_LOG_DIR}/logs"
_LOGGING_SH="${PROJECT_ROOT}/utils/logging.sh"

# Simular dos ejecuciones independientes (dos procesos bash separados)
# que appendean al mismo archivo de log.
bash -c "
    export PROJECT_ROOT='${_TMP_LOG_DIR}'
    source '${_LOGGING_SH}'
    init_log 'operations'
    log_info 'primera ejecucion'
" 2>/dev/null || true

bash -c "
    export PROJECT_ROOT='${_TMP_LOG_DIR}'
    source '${_LOGGING_SH}'
    init_log 'operations'
    log_info 'segunda ejecucion'
" 2>/dev/null || true

if [[ -f "${_TMP_LOG}" ]]; then
    echo -e "  ${_CLR_GREEN}[PASS]${_CLR_RESET} init_log crea logs/operations.log"
    _PASS=$(( _PASS + 1 ))
else
    echo -e "  ${_CLR_RED}[FAIL]${_CLR_RESET} init_log no creo logs/operations.log"
    _FAIL=$(( _FAIL + 1 ))
fi

_INICIO_COUNT=$(grep -c "^=== " "${_TMP_LOG}" 2>/dev/null || true)
_INICIO_COUNT=$(echo "$_INICIO_COUNT" | tr -d '[:space:]')
if [[ "${_INICIO_COUNT}" -ge 2 ]]; then
    echo -e "  ${_CLR_GREEN}[PASS]${_CLR_RESET} dos ejecuciones acumulan dos bloques === ... -- Inicio === (${_INICIO_COUNT} encontrados)"
    _PASS=$(( _PASS + 1 ))
else
    echo -e "  ${_CLR_RED}[FAIL]${_CLR_RESET} acumulacion incorrecta (esperado >= 2 bloques Inicio, encontrado: ${_INICIO_COUNT})"
    _FAIL=$(( _FAIL + 1 ))
fi

if ! grep -qP '\033\[' "${_TMP_LOG}" 2>/dev/null; then
    echo -e "  ${_CLR_GREEN}[PASS]${_CLR_RESET} log no contiene codigos de color ANSI"
    _PASS=$(( _PASS + 1 ))
else
    echo -e "  ${_CLR_RED}[FAIL]${_CLR_RESET} log contiene codigos de color ANSI (no deseado en archivo)"
    _FAIL=$(( _FAIL + 1 ))
fi

# Limpieza
rm -rf "${_TMP_LOG_DIR}"

# =============================================================================
# Resumen
# =============================================================================
echo ""
echo "Resumen test_logging.sh:"
echo "  PASS: ${_PASS}"
echo "  FAIL: ${_FAIL}"
echo "  SKIP: ${_SKIP}"
echo ""

exit $(( _FAIL > 0 ? 1 : 0 ))
