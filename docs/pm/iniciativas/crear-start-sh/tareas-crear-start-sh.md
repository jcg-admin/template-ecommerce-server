# Tareas: Crear script de arranque de daemons

## F0 - Analisis + PM docs (20 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-001 | Leer `utils/core.sh`, `docs/upgrade-server-systemless.md` y `scripts/setup.sh` | 10 min | **Cerrada** | Entendimiento de helpers y patron del proyecto |
| T-002 | Disenar flujo de `_start_daemon`, orden de arranque, aprobar 5 D-* | 5 min | **Cerrada** | 5 decisiones aprobadas, 2 riesgos identificados |
| T-003 | Crear 6 documentos PM siguiendo procedimiento real del repo UI | 5 min | **Cerrada** | 6 archivos en `crear-start-sh/` |

## F1 - Crear `scripts/start.sh` (20 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-101 | Header y boilerplate del script | 3 min | **Cerrada** | Estructura base |
| T-102 | Funcion `_start_daemon` con verificacion post-arranque | 10 min | **Cerrada** | Logica de arranque idempotente |
| T-103 | MAIN con check sudo/root y resumen final | 5 min | **Cerrada** | Script completo |
| T-104 | `bash -n` y `bash tests/run_all.sh` | 2 min | **Cerrada** | PASS >= 74, FAIL = 0 |

## F2 - Actualizar documentacion (10 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-201 | Seccion de arranque WSL2 en `README.md` | 5 min | **Cerrada** | README con referencia a `start.sh` |
| T-202 | Referencia a `start.sh` en `docs/upgrade-server-systemless.md` | 5 min | **Cerrada** | Documento actualizado |

## F3 - Verificacion y cierre (10 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-301 | `bash tests/run_all.sh` y auditoria de links | 5 min | **Cerrada** | PASS >= 74, FAIL = 0 |
| T-302 | Revision manual de `start.sh` | 3 min | **Cerrada** | Script revisado |
| T-303 | Crear `decisiones-*.md`; cerrar index e indice; commit | 2 min | **Cerrada** | Iniciativa cerrada |
