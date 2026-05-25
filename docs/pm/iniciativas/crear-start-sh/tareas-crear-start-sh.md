# Tareas — `crear-start-sh`

Lista de tareas detalladas por fase. El esfuerzo es estimado
y se afina segun hallazgos durante la ejecucion.

## F0 — Analisis + PM docs (20 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-001 | Leer `utils/core.sh` wrappers `svc_*`, `docs/upgrade-server-systemless.md` y `scripts/setup.sh` como referencia de patron | 10 min | **Cerrada** | Entendimiento de helpers disponibles y patron del proyecto |
| T-002 | Disenar flujo de `_start_daemon`, orden de arranque y riesgos | 5 min | **Cerrada** | 5 decisiones D-* aprobadas, 2 riesgos identificados |
| T-003 | Crear 6 documentos PM con diagrama Mermaid | 5 min | **Cerrada** | 6 archivos en `crear-start-sh/` |

## F1 — Crear `scripts/start.sh` (20 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-101 | Header, boilerplate (`set -euo pipefail`, SCRIPT_DIR, PROJECT_ROOT, source utils) | 3 min | **Pendiente** | Estructura base del script |
| T-102 | Funcion `_start_daemon`: guard de instalacion, `svc_is_active`, `svc_start`, verificacion post-arranque | 10 min | **Pendiente** | Logica de arranque idempotente y segura |
| T-103 | Funcion `main`: check sudo/root, invocar `_start_daemon nginx` y `_start_daemon fail2ban` en orden, resumen final | 5 min | **Pendiente** | Script completo y funcional |
| T-104 | `bash -n scripts/start.sh` y `bash tests/run_all.sh` | 2 min | **Pendiente** | Sintaxis valida; PASS >= 73, FAIL = 0 |

## F2 — Actualizar documentacion (10 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-201 | Actualizar `README.md`: agregar seccion de arranque para WSL2 sin systemd | 5 min | **Pendiente** | README con referencia a `start.sh` |
| T-202 | Actualizar `docs/upgrade-server-systemless.md`: agregar `start.sh` en resumen ejecutivo como forma estandar de arranque | 5 min | **Pendiente** | Documento actualizado con `start.sh` |

## F3 — Verificacion y cierre (10 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-301 | `bash tests/run_all.sh` y auditoria de links | 5 min | **Pendiente** | PASS >= 74, FAIL = 0; 0 links rotos nuevos |
| T-302 | Revision manual de `start.sh`: guards, orden, mensajes, idempotencia | 3 min | **Pendiente** | Script revisado y correcto |
| T-303 | Actualizar progreso con cierre, index con Estado=Cerrada, indice-de-iniciativas.md; commit de cierre | 2 min | **Pendiente** | Iniciativa formalmente cerrada |
