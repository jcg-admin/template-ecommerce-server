# Iniciativa: Agregar logging a archivo en scripts y provisioners

| Campo | Valor |
|-------|-------|
| Artefacto | INI-SRV-009 |
| Tipo | Iniciativa de desarrollo |
| Submodulo | server (template-ecommerce-server) |
| Estado | **Cerrada** |
| Version | 1.0.0 |
| Fecha de creacion | 2026-05-26 |
| Fecha de cierre | 2026-05-26 |
| Autor | NestorMonroy |
| Clasificacion | Interno |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 + arc42 |

## Filosofia rectora

`utils/logging.sh` ya tiene la infraestructura: `init_log` y
`_write_log` estan implementados. Ningun script los usa todavia.
Esta iniciativa activa esa infraestructura en todos los scripts y
provisioners sin modificar la logica de ninguno de ellos.

Un solo archivo acumulativo por repo: `logs/operations.log`. Cada
ejecucion de cualquier script append al mismo archivo con timestamp,
formando un historial cronologico de todas las operaciones.

Excepciones explicitas:

- `logs/` no se versiona. El archivo de log es dato operativo, no
  codigo. Se agrega a `.gitignore`.
- No se implementa rotacion de logs en esta iniciativa. El archivo
  crece indefinidamente; el operador lo rota manualmente si es
  necesario. Rotacion automatica es una mejora futura separada.
- `utils/logging.sh` no se modifica. Solo se activa `init_log`
  en cada script que ya lo sourcea.

## Que produce esta iniciativa

| Entregable | Estado al cierre |
|------------|------------------|
| `logs/` en `.gitignore` | Producido — `logs/*.log` + `!logs/.gitkeep` |
| `logs/.gitkeep` en el repo | Producido — directorio logs/ versionado con propietario correcto |
| `init_log "operations"` en 10 scripts | Producido — 4 scripts + 6 provisioners activados |
| `docs/operaciones.md` actualizado | Producido — seccion de logs con tail -f, post-mortem y rotacion |

## Indice de documentos

| Documento | Proposito |
|-----------|-----------|
| [alcance-agregar-logging-a-archivo.md](alcance-agregar-logging-a-archivo.md) | Que cubre, criterio de completitud, fuera de alcance, estimacion. |
| [analisis-agregar-logging-a-archivo.md](analisis-agregar-logging-a-archivo.md) | Auditoria de init_log existente, permisos del directorio logs/, scripts a modificar. |
| [plan-agregar-logging-a-archivo.md](plan-agregar-logging-a-archivo.md) | DAG de fases, tareas por fase con esfuerzo. |
| [tareas-agregar-logging-a-archivo.md](tareas-agregar-logging-a-archivo.md) | Lista plana de tareas con estado y entregable. |
| [progreso-agregar-logging-a-archivo.md](progreso-agregar-logging-a-archivo.md) | Bitacora cronologica de eventos atomizados. |
| [decisiones-agregar-logging-a-archivo.md](decisiones-agregar-logging-a-archivo.md) | Decisiones de diseno, hallazgos y verificacion post-ejecucion. |

## Decisiones aprobadas

| ID | Decision | Contenido |
|----|----------|-----------|
| **D-UN-SOLO-ARCHIVO** | Un solo archivo acumulativo `logs/operations.log` para todos los scripts. | Facilita la correlacion temporal entre operaciones. Un operador puede hacer `tail -f logs/operations.log` y ver todo lo que ocurre sin importar que script se esta ejecutando. Alternativa descartada: un archivo por script (verify.log, setup.log, etc.) — fragmenta el historial y complica el diagnostico. |
| **D-INIT-LOG-EXISTENTE** | Usar `init_log` de `utils/logging.sh` sin modificar el archivo. | La infraestructura ya existe y funciona. Modificar logging.sh para esta iniciativa seria scope creep; los scripts solo necesitan llamar `init_log "operations"` despues de hacer source de los utils. |
| **D-LOGS-NO-VERSIONADOS** | `logs/*.log` se agrega a `.gitignore`. | Los archivos de log son datos operativos, no codigo. Versionar logs llena el historial de git con ruido y puede exponer informacion sensible del entorno (rutas, IPs, dominios). |
| **D-GITKEEP** | `logs/.gitkeep` se versiona para garantizar que el directorio existe al clonar. | Sin el directorio pre-existente, `init_log` hace `mkdir -p` en el primer uso. Si ese primer uso es un provisioner que corre como root, `logs/` queda con propietario root y `develop` no puede escribir. El `.gitkeep` garantiza que el directorio existe con el propietario correcto (develop, UID 1002) desde el clon inicial. |
| **D-SIN-ROTACION** | No se implementa rotacion automatica de logs en esta iniciativa. | La rotacion requiere decisiones sobre retencion, compresion y frecuencia que merecen su propio analisis. El archivo crecera lentamente (texto plano, operaciones ocasionales). El operador puede rotar manualmente con `mv logs/operations.log logs/operations.log.bak`. |

## Alcance cruzado con otros repos

No aplica. Todos los cambios son en `template-ecommerce-server`.
`logs/operations.log` no se comparte con `template-ecommerce-ui`.

## Iniciativas relacionadas

- INI-SRV-001 `crear-template-ecomerce-ui-server` (cerrada):
  produjo `utils/logging.sh` con `init_log` y `_write_log` que
  esta iniciativa activa.
- INI-SRV-007 `auditar-gaps-server-y-ui` (cerrada): corrigio
  `verify.sh` donde el problema de logs truncados fue detectado.
- INI-SRV-009-F2 (futura, no en este alcance): rotacion automatica
  de `logs/operations.log` con logrotate o cron.
