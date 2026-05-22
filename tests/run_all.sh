#!/bin/bash
# =============================================================================
# tests/run_all.sh
# Orquestador: ejecuta todos los test_*.sh en orden alfabetico
# =============================================================================
# Itera sobre tests/test_*.sh, captura exit code de cada uno, presenta
# resumen agregado al final.
#
# Exit codes:
#   0 si todos los test_*.sh retornan 0
#   1 si al menos uno falla
#
# Output: cada test produce su propio reporte; al final se anade un
# bloque "AGREGADO" con totales.
#
# Convencion para crear nuevos tests:
#   1. Nombre: tests/test_<area>.sh con permiso 0755
#   2. Helpers: assert (con bash -c para pipelines), assert_eq, skip
#   3. Contadores: _PASS, _FAIL, _SKIP locales al script
#   4. Exit code: 1 si _FAIL > 0, 0 si todos PASS o SKIP
#   5. Output legible con prefijo [PASS]/[FAIL]/[SKIP]
#   6. Hermetico: no asumir estado previo del sistema; cleanup propio
#
# Uso:
#   bash tests/run_all.sh
#   bash tests/run_all.sh --quiet   # solo el resumen final
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

QUIET=false
for arg in "$@"; do
    [[ "$arg" == "--quiet" ]] && QUIET=true
done

if [[ -t 1 ]]; then
    _CLR_RESET="\033[0m"; _CLR_GREEN="\033[0;32m"; _CLR_RED="\033[0;31m"
    _CLR_YELLOW="\033[0;33m"; _CLR_BOLD="\033[1m"; _CLR_CYAN="\033[0;36m"
else
    _CLR_RESET=""; _CLR_GREEN=""; _CLR_RED=""; _CLR_YELLOW=""
    _CLR_BOLD=""; _CLR_CYAN=""
fi

echo ""
echo -e "${_CLR_BOLD}${_CLR_CYAN}template-ecomerce-ui-server -- tests/run_all.sh${_CLR_RESET}"
echo "============================================================"
echo ""

# Listar test_*.sh ordenados alfabeticamente
TESTS=()
while IFS= read -r -d '' f; do
    TESTS+=("$f")
done < <(find "${SCRIPT_DIR}" -maxdepth 1 -name "test_*.sh" -type f -print0 | sort -z)

if [[ ${#TESTS[@]} -eq 0 ]]; then
    echo -e "${_CLR_YELLOW}WARN${_CLR_RESET} no se encontraron archivos test_*.sh en ${SCRIPT_DIR}"
    exit 0
fi

# Ejecutar cada test, capturar exit code
declare -A RESULTS
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIP=0
SUITES_OK=0
SUITES_FAIL=0

for test_file in "${TESTS[@]}"; do
    name=$(basename "$test_file" .sh)
    echo -e "${_CLR_BOLD}>>> ${name}${_CLR_RESET}"

    if [[ "$QUIET" == "true" ]]; then
        output=$(bash "$test_file" 2>&1)
        exit_code=$?
    else
        bash "$test_file"
        exit_code=$?
        output=""
    fi

    # Extraer contadores del output
    # Si quiet, parseamos el output capturado; si verbose, re-leemos el
    # output via bash de nuevo capturando (pero ya se imprimio).
    # Para simplicidad: ejecutar quiet siempre internamente para parsear
    # los contadores, y solo imprimir el output si NO es quiet (ya lo
    # imprimio bash arriba).
    if [[ "$QUIET" != "true" ]]; then
        output=$(bash "$test_file" 2>&1)
    fi

    pass_n=$(echo "$output" | grep -E "^  PASS:" | head -1 | awk '{print $2}')
    fail_n=$(echo "$output" | grep -E "^  FAIL:" | head -1 | awk '{print $2}')
    skip_n=$(echo "$output" | grep -E "^  SKIP:" | head -1 | awk '{print $2}')
    pass_n="${pass_n:-0}"; fail_n="${fail_n:-0}"; skip_n="${skip_n:-0}"

    RESULTS["$name"]="${pass_n}/${fail_n}/${skip_n}"
    TOTAL_PASS=$(( TOTAL_PASS + pass_n ))
    TOTAL_FAIL=$(( TOTAL_FAIL + fail_n ))
    TOTAL_SKIP=$(( TOTAL_SKIP + skip_n ))

    if [[ "$exit_code" -eq 0 ]]; then
        SUITES_OK=$(( SUITES_OK + 1 ))
    else
        SUITES_FAIL=$(( SUITES_FAIL + 1 ))
    fi

    if [[ "$QUIET" != "true" ]]; then
        echo ""
    fi
done

# =============================================================================
# Resumen agregado
# =============================================================================
echo "============================================================"
echo -e "${_CLR_BOLD}AGREGADO${_CLR_RESET}"
echo ""

for name in "${!RESULTS[@]}"; do
    result="${RESULTS[$name]}"
    printf "  %-45s  PASS/FAIL/SKIP = %s\n" "$name" "$result"
done | sort

echo ""
echo -e "  Suites:  ${_CLR_GREEN}${SUITES_OK} OK${_CLR_RESET}  /  ${_CLR_RED}${SUITES_FAIL} FAIL${_CLR_RESET}"
echo -e "  Totales: ${_CLR_GREEN}${TOTAL_PASS} PASS${_CLR_RESET}  /  ${_CLR_RED}${TOTAL_FAIL} FAIL${_CLR_RESET}  /  ${_CLR_YELLOW}${TOTAL_SKIP} SKIP${_CLR_RESET}"
echo ""

if [[ "$SUITES_FAIL" -eq 0 ]]; then
    echo -e "${_CLR_GREEN}${_CLR_BOLD}OK${_CLR_RESET}: todos los tests pasaron"
else
    echo -e "${_CLR_RED}${_CLR_BOLD}FAIL${_CLR_RESET}: ${SUITES_FAIL} suite(s) fallaron"
fi
echo ""

exit $(( SUITES_FAIL > 0 ? 1 : 0 ))
