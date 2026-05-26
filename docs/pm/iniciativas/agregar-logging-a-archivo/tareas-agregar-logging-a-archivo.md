# Tareas: Agregar logging a archivo en scripts y provisioners

## F0 - Analisis + PM docs (20 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-001 | Auditar init_log, analizar permisos, inventariar 10 scripts | 10 min | **Cerrada** | Analisis con inventario y 3 riesgos identificados |
| T-002 | Crear 6 documentos PM | 10 min | **Cerrada** | 6 archivos en `agregar-logging-a-archivo/` |

## F1 - .gitignore, .gitkeep, init_log en 10 scripts (20 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-101 | Crear/actualizar `.gitignore` con `logs/*.log` | 2 min | **Cerrada** | `.gitignore` actualizado |
| T-102 | Crear `logs/.gitkeep` | 1 min | **Cerrada** | Directorio logs/ versionado |
| T-103 | `init_log "operations"` en 4 scripts de scripts/ | 5 min | **Cerrada** | setup.sh, start.sh, verify.sh, renew_ssl.sh |
| T-104 | `init_log "operations"` en 6 provisioners | 7 min | **Cerrada** | install.sh, setup_vhost.sh, setup_ssl.sh, setup_fail2ban.sh, setup_ssh_hardening.sh, setup_firewall.sh |
| T-105 | `bash -n` en los 10 scripts modificados | 3 min | **Cerrada** | 10 PASS de sintaxis |
| T-106 | `bash tests/run_all.sh` | 2 min | **Cerrada** | PASS >= 74, FAIL = 0 |

## F2 - Actualizar docs/operaciones.md (10 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-201 | Seccion de logs en operaciones.md | 10 min | **Cerrada** | Documentacion de ubicacion y uso del log |

## F3 - Verificacion y cierre (10 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-301 | Verificacion funcional: logs/operations.log se crea y acumula | 5 min | **Cerrada** | Log verificado |
| T-302 | decisiones-*.md; cerrar index, tareas e indice; commit | 5 min | **Cerrada** | Iniciativa cerrada |
