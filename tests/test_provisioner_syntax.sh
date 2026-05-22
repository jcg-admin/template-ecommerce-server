#!/bin/bash
# =============================================================================
# tests/test_provisioner_syntax.sh
# Smoke test: `bash -n` sobre todos los scripts .sh del repo
# =============================================================================
# Detecta errores de sintaxis bash en cualquier script editado. Es el
# primer test a ejecutar -- si un script no parsea, el resto de tests
# son irrelevantes.
#
# Cobertura:
#   - utils/*.sh (4 archivos)
#   - provisioners/*/*.sh (6 archivos)
#   - scripts/*.sh (2 archivos)
#   - tests/*.sh (los propios tests, excluyendo este)
#
# Patron del framework de tests:
#   _PASS, _FAIL, _SKIP contadores globales
#   assert <descripcion> <comando>  -> PASS si comando exit 0, FAIL si no
#   skip <descripcion> <razon>      -> SKIP con razon
#   Exit code: 1 si _FAIL > 0, 0 si todos PASS o SKIP
#
# Uso:
#   bash tests/test_provisioner_syntax.sh
# =============================================================================
set -uo pipefail
# NO -e: queremos seguir tras fallos individuales y reportar todos al final

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colores -- solo en terminal interactiva
if [[ -t 1 ]]; then
    _CLR_RESET="\033[0m"
    _CLR_GREEN="\033[0;32m"
    _CLR_RED="\033[0;31m"
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

skip() {
    local desc="$1" reason="${2:-}"
    echo -e "  ${_CLR_YELLOW}[SKIP]${_CLR_RESET} ${desc} (${reason})"
    _SKIP=$(( _SKIP + 1 ))
}

# =============================================================================
# Tests
# =============================================================================
echo ""
echo "test_provisioner_syntax.sh -- bash -n sobre todos los scripts"
echo ""

# Iterar sobre todos los .sh excepto este mismo (evitar self-test recursivo
# que no anade valor)
SELF="${BASH_SOURCE[0]}"
SELF_ABS="$(cd "$(dirname "$SELF")" && pwd)/$(basename "$SELF")"

while IFS= read -r -d '' script; do
    script_abs="$(cd "$(dirname "$script")" && pwd)/$(basename "$script")"
    if [[ "$script_abs" == "$SELF_ABS" ]]; then
        continue
    fi
    # Path relativo al PROJECT_ROOT para output mas corto
    rel="${script#${PROJECT_ROOT}/}"
    assert "bash -n ${rel}" bash -n "$script"
done < <(find "$PROJECT_ROOT" -name "*.sh" -type f -not -path "*/.git/*" -print0 | sort -z)

# =============================================================================
# Resumen
# =============================================================================
echo ""
echo "Resumen test_provisioner_syntax.sh:"
echo "  PASS: ${_PASS}"
echo "  FAIL: ${_FAIL}"
echo "  SKIP: ${_SKIP}"
echo ""

exit $(( _FAIL > 0 ? 1 : 0 ))
