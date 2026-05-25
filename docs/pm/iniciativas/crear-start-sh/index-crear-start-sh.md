# Iniciativa: Crear script de arranque de daemons

| Campo | Valor |
|-------|-------|
| Artefacto | INI-SRV-006 |
| Tipo | Iniciativa de desarrollo |
| Submodulo | server (template-ecommerce-server) |
| Estado | Cerrada |
| Version | 1.0.0 |
| Fecha de creacion | 2026-05-25 |
| Fecha de cierre | 2026-05-25 |
| Autor | NestorMonroy |
| Clasificacion | Interno |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 |

## Filosofia rectora

`start.sh` arranca; no instala, no configura, no verifica la
correctitud del entorno. Su unico trabajo es levantar los daemons
que ya estan instalados y configurados por los provisioners.

Principios:

1. **Reutilizar, no reimplementar**: usa `svc_is_active` y
   `svc_start` de `utils/core.sh`. Esos wrappers ya encapsulan la
   logica de deteccion de systemd y los comandos nativos de cada
   daemon.

2. **Idempotente**: si un daemon ya esta corriendo, el script lo
   detecta y lo omite sin error. Ejecutar `start.sh` dos veces es
   seguro.

3. **Sin efectos secundarios**: no modifica configuracion, no
   recarga vhosts, no renueva certificados. Solo arranca.

Excepciones explicitas:

- `sshd` NO se arranca. En WSL2 lo gestiona Windows; en produccion
  lo gestiona systemd o el init del VPS.
- `start.sh` no llama a `verify.sh`. La verificacion completa del
  entorno es responsabilidad del operador tras el arranque.

## Que produce esta iniciativa

| Entregable | Estado al cierre |
|------------|------------------|
| `scripts/start.sh` | Producido — 144 lineas, 1 funcion _start_daemon, idempotente |
| `README.md` actualizado | Producido — seccion arranque WSL2 con start.sh |
| `docs/upgrade-server-systemless.md` actualizado | Producido — resumen ejecutivo referencia start.sh |

## Indice de documentos

| Documento | Proposito |
|-----------|-----------|
| [index-crear-start-sh.md](index-crear-start-sh.md) | Este archivo. Metadata, filosofia, entregables, decisiones. |
| [alcance-crear-start-sh.md](alcance-crear-start-sh.md) | Que cubre, criterio de completitud, fuera de alcance, estimacion. |
| [analisis-crear-start-sh.md](analisis-crear-start-sh.md) | Inventario de helpers disponibles, diagrama de flujo, riesgos. |
| [plan-crear-start-sh.md](plan-crear-start-sh.md) | DAG de fases, tareas por fase con esfuerzo. |
| [tareas-crear-start-sh.md](tareas-crear-start-sh.md) | Lista plana de tareas con estado y entregable. |
| [progreso-crear-start-sh.md](progreso-crear-start-sh.md) | Bitacora cronologica de eventos atomizados. |
| [decisiones-crear-start-sh.md](decisiones-crear-start-sh.md) | Decisiones de diseno, hallazgos y verificacion post-ejecucion. |

## Decisiones aprobadas

| ID | Decision | Contenido |
|----|----------|-----------|
| D-REUTILIZA-WRAPPERS | Usar `svc_is_active` y `svc_start` de `utils/core.sh`. | Los wrappers ya encapsulan la deteccion de systemd y los comandos nativos para cada daemon. Duplicar esa logica en `start.sh` crearia deuda de mantenimiento. Alternativa descartada: invocar `/usr/sbin/nginx` y `fail2ban-server -b` directamente. |
| D-IDEMPOTENTE | Si un daemon ya esta corriendo, omitirlo sin error. | El script debe ser seguro de ejecutar multiples veces sin efectos adversos. Un `svc_start` sobre un daemon activo puede causar error o comportamiento impredecible segun el daemon. |
| D-NO-SSHD | No arrancar sshd. | En WSL2 lo gestiona Windows. En produccion lo gestiona systemd o el init del VPS. Arrancarlo desde `start.sh` causaria conflictos en ambos entornos. |
| D-NO-VERIFY | No llamar a `verify.sh` al final. | `verify.sh` hace 12 checks que incluyen conexiones de red y estado de certificados. Son checks de entorno completo, no de arranque. El operador los ejecuta cuando quiere. |
| D-SUDO-REQUERIDO | Requiere sudo o root. | Arrancar Nginx y fail2ban requiere privilegios de sistema tanto con systemd como sin el. |

## Alcance cruzado con otros repos

No aplica. `start.sh` opera exclusivamente sobre los daemons del
servidor local. No modifica ni referencia el repo
`template-ecommerce-ui`.

## Iniciativas relacionadas

- INI-SRV-005 `crear-setup-sh` (cerrada): `setup.sh` instala y
  configura. `start.sh` arranca lo que `setup.sh` dejo instalado.
- INI-SRV-001 `crear-template-ecomerce-ui-server` (cerrada):
  produjo los provisioners y `docs/upgrade-server-systemless.md`
  que documenta el problema que `start.sh` resuelve.
