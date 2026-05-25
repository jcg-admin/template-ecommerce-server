# Iniciativa: Crear script de aprovisionamiento unificado

| Campo | Valor |
|-------|-------|
| Artefacto | INI-SRV-005 |
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

`setup.sh` es exclusivamente un orquestador. No reimplementa
logica de ningun provisioner, no duplica sus guards internos y
no asume nada sobre el estado del sistema que no haya verificado
explicitamente.

Principios:

1. **Invocar, no replicar**: cada provisioner se invoca como
   subproceso con su propia logica de idempotencia.
2. **Guards minimos propios**: solo valida lo que los
   provisioners no pueden validar por si solos.
3. **Pausa explicita, no silenciosa**: el punto de interrupcion
   entre Fase 1 y Fase 2 es visible y no puede omitirse
   accidentalmente.

Excepciones explicitas:

- Si un provisioner cambia su interfaz, `setup.sh` se actualiza
  en la misma iniciativa que produce ese cambio.
- `--skip-ssh` existe como excepcion al flujo de dos fases para
  entornos donde SSH hardening no aplica (WSL2, CI).

## Que produce esta iniciativa

| Entregable | Estado al cierre |
|------------|------------------|
| `scripts/setup.sh` | Producido — 2 fases, 4 flags, 5 guards, 340 lineas |
| `README.md` actualizado | Producido — quick start con 3 flujos de setup.sh |
| `docs/operaciones.md` actualizado | Producido — setup.sh como punto de entrada primario |
| `docs/arquitectura.md` actualizado | Producido — diagrama de secuencia de dos fases |

## Indice de documentos

| Documento | Proposito |
|-----------|-----------|
| [index-crear-setup-sh.md](index-crear-setup-sh.md) | Este archivo. Metadata, filosofia, entregables, decisiones. |
| [alcance-crear-setup-sh.md](alcance-crear-setup-sh.md) | Que cubre, criterio de completitud, fuera de alcance, estimacion. |
| [analisis-crear-setup-sh.md](analisis-crear-setup-sh.md) | Inventario del estado actual, 3 diagramas Mermaid, riesgos. |
| [plan-crear-setup-sh.md](plan-crear-setup-sh.md) | DAG de fases, tareas por fase con esfuerzo. |
| [tareas-crear-setup-sh.md](tareas-crear-setup-sh.md) | Lista plana de tareas con estado y entregable. |
| [progreso-crear-setup-sh.md](progreso-crear-setup-sh.md) | Bitacora cronologica de eventos atomizados. |
| [decisiones-crear-setup-sh.md](decisiones-crear-setup-sh.md) | Decisiones de diseno, hallazgos y verificacion post-ejecucion. |

## Decisiones aprobadas

| ID | Decision | Contenido |
|----|----------|-----------|
| D-DOS-FASES | `setup.sh` opera en dos fases separadas por una pausa de reconexion SSH. | `setup_ssh_hardening.sh` cambia el puerto SSH. Si Fase 2 se ejecuta sin pausa, UFW activa el nuevo puerto cortando la sesion SSH activa. La pausa es la unica forma segura. |
| D-SKIP-SSH | Flag `--skip-ssh` omite `setup_ssh_hardening.sh` y suprime la pausa. | WSL2 no tiene sshd nativo; agentes CI no usan SSH interactivo. En esos entornos el hardening y la pausa son innecesarios. |
| D-SSL-FLAGS | Flags `--ssl-dev` y `--ssl-staging` se pasan directamente a `setup_ssl.sh`. | `setup_ssl.sh` ya soporta esos modos. `setup.sh` no reimplementa esa logica. |
| D-IDEMPOTENTE | `setup.sh` es idempotente. | Los provisioners que orquesta ya son idempotentes; `setup.sh` hereda esa propiedad. |
| D-NO-INSTALA-ENV | Valida que `.env` existe pero no lo crea. | El `.env` contiene decisiones del operador que no se pueden inferir automaticamente. |
| D-GUARD-SSH-KEY | Verifica clave SSH en `~/.ssh/authorized_keys` antes de Fase 1. | Sin clave SSH el operador quedaria bloqueado tras el hardening. Mismo guard que `setup_ssh_hardening.sh`. |
| D-NO-REEMPLAZA-PROVISIONERS | `setup.sh` es capa de orquestacion; los provisioners no cambian. | Un operador avanzado puede invocar provisioners directamente sin pasar por `setup.sh`. |

## Alcance cruzado con otros repos

No aplica. `setup.sh` opera exclusivamente sobre el servidor
local donde se ejecuta. No modifica el repo `template-ecommerce-ui`.

## Iniciativas relacionadas

- INI-SRV-001 `crear-template-ecomerce-ui-server` (cerrada):
  produjo los 8 provisioners que `setup.sh` orquesta.
- INI-SRV-006 `crear-start-sh` (en ejecucion): arranque de
  daemons en WSL2 sin systemd. Problema distinto al aprovisionamiento.
