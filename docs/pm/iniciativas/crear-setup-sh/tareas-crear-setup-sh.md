# Tareas — `crear-setup-sh`

Lista de tareas detalladas por fase. Cada tarea genera uno o
mas commits unitarios. El esfuerzo es estimado y se afina segun
hallazgos durante la ejecucion.

## F0 — Analisis + PM docs (30 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-001 | Leer verify.sh, provisioners, utils/core.sh y upgrade-server-systemless.md para entender helpers disponibles y contexto de entorno sin systemd | 10 min | **Cerrada** | Entendimiento del contexto tecnico completo |
| T-002 | Disenar flujo de dos fases, 4 flags, guards y riesgos | 5 min | **Cerrada** | 7 decisiones D-* aprobadas |
| T-003 | Crear 6 documentos PM con 3 diagramas Mermaid | 15 min | **Cerrada** | 6 archivos en `crear-setup-sh/` |

## F1 — Crear `scripts/setup.sh` (45 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-101 | Header, boilerplate (`set -euo pipefail`, SCRIPT_DIR, PROJECT_ROOT), source de utils | 5 min | **Pendiente** | Estructura base del script |
| T-102 | Funcion `_usage`: texto de ayuda con los 4 flags, prerequisitos y ejemplos de uso | 5 min | **Pendiente** | `setup.sh --help` imprime usage correcto |
| T-103 | Funcion `_parse_flags`: parsear `--continue`, `--skip-ssh`, `--ssl-dev`, `--ssl-staging`; detectar combinaciones invalidas | 5 min | **Pendiente** | Flags parseados; combinaciones invalidas abortan con mensaje |
| T-104 | Funcion `_check_prerequisites`: verificar sudo, `.env` existente, variables requeridas presentes | 10 min | **Pendiente** | Script aborta antes de ejecutar nada si faltan prerequisitos |
| T-105 | Funcion `_check_ssh_key`: guard anti-lockout verificando `~/.ssh/authorized_keys` | 5 min | **Pendiente** | Script aborta si no hay clave SSH con instrucciones claras |
| T-106 | Funcion `_run_fase1`: invoke `install.sh` + (condicional) `ssh_hardening.sh` + pausa con instrucciones de reconexion | 5 min | **Pendiente** | Fase 1 ejecutable con y sin `--skip-ssh` |
| T-107 | Funcion `_run_fase2`: invoke `firewall` + `fail2ban` + `ssl` (pasando flag SSL) + `vhost` + `verify` | 5 min | **Pendiente** | Fase 2 ejecuta los 5 pasos en orden con verificacion final |
| T-108 | Funcion `main`: guard de nginx instalado para `--continue`, orquestacion general | 3 min | **Pendiente** | Script completo y funcional |
| T-109 | Verificar `bash -n scripts/setup.sh` y ejecutar `bash tests/run_all.sh` | 2 min | **Pendiente** | Sintaxis valida; FAIL = 0 en suite completa |

## F2 — Actualizar documentacion (20 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-201 | Actualizar `README.md`: reemplazar lista de 8 comandos manuales en quick start por invocacion de `setup.sh` | 10 min | **Pendiente** | README con punto de entrada simplificado |
| T-202 | Actualizar `docs/operaciones.md`: agregar `setup.sh` en la seccion de aprovisionamiento como punto de entrada primario | 5 min | **Pendiente** | operaciones.md con setup.sh documentado |
| T-203 | Actualizar `docs/arquitectura.md`: flujo 1 (aprovisionar desde cero) con `setup.sh` | 5 min | **Pendiente** | arquitectura.md con flujo actualizado |

## F3 — Verificacion y cierre (15 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-301 | Ejecutar `bash tests/run_all.sh` y verificar que el script de auditoria de links no reporta nuevos rotos | 5 min | **Pendiente** | PASS >= 72, FAIL = 0; 0 links rotos nuevos |
| T-302 | Revision manual de `setup.sh`: flags, guards, mensajes, orden de pasos | 5 min | **Pendiente** | Script revisado y correcto |
| T-303 | Actualizar progreso con eventos de cierre, index con Estado=Cerrada, tareas con estados finales; commit de cierre | 5 min | **Pendiente** | Iniciativa formalmente cerrada |

<!-- Referencias Markdown -->
[analisis-ui]: https://github.com/jcg-admin/template-ecommerce-ui/blob/main/docs/desarrollo/analisis-servidor-para-template.md
