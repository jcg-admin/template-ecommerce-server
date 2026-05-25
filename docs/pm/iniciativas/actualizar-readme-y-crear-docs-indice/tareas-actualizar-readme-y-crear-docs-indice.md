# Tareas: Actualizar README y crear indice de documentacion

## F0 - Analisis + PM docs (20 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-001 | Auditar README.md: gaps en inventario, LOC, tests, iniciativas | 10 min | **Cerrada** | 5 gaps identificados con valores incorrectos |
| T-002 | Auditar docs/: mapear cajones existentes vs modelo arc42 del UI | 5 min | **Cerrada** | Mapa de 15 cajones (5 existentes + 3 propios + 7 ausentes) |
| T-003 | Crear 6 documentos PM | 5 min | **Cerrada** | 6 archivos en `actualizar-readme-y-crear-docs-indice/` |

## F1 - Actualizar README.md (20 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-101 | Actualizar tabla de inventario: 4 scripts, LOC correctos | 5 min | **Cerrada** | Inventario correcto |
| T-102 | Actualizar tests: 72 → 74 PASS | 2 min | **Cerrada** | Tests actualizados |
| T-103 | Actualizar estado del repo: 7+1 iniciativas, 61 commits | 5 min | **Cerrada** | Estado correcto |
| T-104 | Actualizar ref-defs y enlaces | 3 min | **Cerrada** | Links actualizados |
| T-105 | Verificar links internos sin rotos | 5 min | **Cerrada** | 0 links rotos nuevos |

## F2 - Crear docs/README.md (20 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-201 | Crear `docs/README.md` con cajones existentes | 10 min | **Cerrada** | Indice de documentacion |
| T-202 | Declarar cajones ausentes con justificacion | 5 min | **Cerrada** | Ausentes documentados honestamente |
| T-203 | Verificar links del nuevo README | 5 min | **Cerrada** | 0 links rotos |

## F3 - Verificacion y cierre (10 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-301 | `bash tests/run_all.sh` + auditoria de links | 5 min | **Cerrada** | PASS >= 74, FAIL = 0 |
| T-302 | Crear `decisiones-*.md`; cerrar index e indice; commit | 5 min | **Cerrada** | Iniciativa cerrada |
