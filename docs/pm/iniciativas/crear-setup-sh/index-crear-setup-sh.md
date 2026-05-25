# Iniciativa: `crear-setup-sh`

| Campo | Valor |
|-------|-------|
| Artefacto | `crear-setup-sh` |
| Tipo | Iniciativa de desarrollo |
| Estado | Cerrada |
| Version | 1.0.0 |
| Fecha de creacion | 2026-05-25 |
| Fecha de apertura formal | 2026-05-25 |
| Autor | Nestor Monroy |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 |
| Repositorio | [`template-ecommerce-server`][repo-server] |
| Orden de backlog | (no aplica: abierta directamente tras detectar ausencia de punto de entrada unificado) |
| Iniciativas previas relacionadas | `crear-template-ecomerce-ui-server` (cerrada) — produjo los provisioners que este script orquesta |

## Filosofia rectora

`setup.sh` es exclusivamente un orquestador. No reimplementa
logica de ningun provisioner, no duplica sus guards internos
y no asume nada sobre el estado del sistema que no haya
verificado explicitamente.

Principios:

1. **Invocar, no replicar**: cada provisioner se invoca como
   subproceso con su propia logica de idempotencia. Si un
   provisioner falla, `setup.sh` falla con el codigo de salida
   del provisioner sin intentar recuperar.

2. **Guards minimos propios**: `setup.sh` solo valida lo que
   los provisioners no pueden validar por si solos — la
   existencia del `.env`, la presencia de clave SSH, y que
   Nginx este instalado antes de continuar la Fase 2.

3. **Pausa explicita, no silenciosa**: el punto de interrupcion
   entre Fase 1 y Fase 2 es visible, imprimible y no puede
   ser omitido accidentalmente.

Excepciones explicitas:

- Si un provisioner cambia su interfaz (nombre del script o
  flags), `setup.sh` se actualiza en la misma iniciativa que
  produce ese cambio, no en una iniciativa separada.
- `--skip-ssh` existe como excepcion al flujo de dos fases para
  entornos donde SSH hardening no aplica (WSL2, CI).

## Que produce

| Entregable | Descripcion |
|------------|-------------|
| `scripts/setup.sh` | Script de orquestacion con 2 fases y 4 flags |
| `README.md` actualizado | Quick start con `setup.sh` como punto de entrada |
| `docs/operaciones.md` actualizado | Seccion aprovisionamiento con `setup.sh` |
| `docs/arquitectura.md` actualizado | Flujo 1 actualizado con `setup.sh` |

## Documentos de la iniciativa

| Documento | Estado |
|-----------|--------|
| [index-crear-setup-sh.md][doc-index] | Este archivo |
| [alcance-crear-setup-sh.md][doc-alcance] | Completado |
| [analisis-crear-setup-sh.md][doc-analisis] | Completado |
| [plan-crear-setup-sh.md][doc-plan] | Completado |
| [tareas-crear-setup-sh.md][doc-tareas] | Completado |
| [progreso-crear-setup-sh.md][doc-progreso] | Activo (bitacora cronologica) |

## Decisiones aprobadas

| ID | Decision | Justificacion |
|----|----------|---------------|
| D-DOS-FASES | `setup.sh` opera en dos fases separadas por una pausa de reconexion SSH. Fase 1: `install.sh` + `ssh_hardening.sh`. Fase 2: `firewall` + `fail2ban` + `ssl` + `vhost` + `verify`. Flag `--continue` activa Fase 2. | `setup_ssh_hardening.sh` cambia el puerto SSH. Si Fase 2 se ejecuta sin pausa, UFW activa el nuevo puerto cortando la sesion SSH activa del operador. La pausa es la unica forma segura de garantizar la reconexion. |
| D-SKIP-SSH | Flag `--skip-ssh` omite `setup_ssh_hardening.sh` y suprime la pausa entre fases. | WSL2 no tiene sshd nativo; agentes CI no usan SSH interactivo. En esos entornos el hardening y la pausa son innecesarios. |
| D-SSL-FLAGS | Flags `--ssl-dev` y `--ssl-staging` se pasan directamente a `setup_ssl.sh`. Sin flag: modo produccion. | `setup_ssl.sh` ya soporta estos modos. `setup.sh` no reimplementa esa logica. |
| D-IDEMPOTENTE | `setup.sh` es idempotente: seguro de ejecutar multiples veces. | Los provisioners que orquesta ya son idempotentes; `setup.sh` hereda esa propiedad. |
| D-NO-INSTALA-ENV | `setup.sh` valida que `.env` existe pero no lo crea. | El `.env` contiene decisiones del operador que no se pueden inferir automaticamente. |
| D-GUARD-SSH-KEY | Antes de Fase 1, verifica clave SSH en `~/.ssh/authorized_keys`. Si no existe, aborta. | Mismo guard que `setup_ssh_hardening.sh`. Sin clave SSH el operador quedaria bloqueado tras el hardening. |
| D-NO-REEMPLAZA-PROVISIONERS | `setup.sh` es capa de orquestacion; los provisioners individuales no cambian. | Los provisioners son las unidades atomicas del sistema. Un operador avanzado puede invocarlos directamente sin pasar por `setup.sh`. |

## Alcance cruzado con otros repos

No aplica. `setup.sh` opera exclusivamente sobre el servidor
local donde se ejecuta. No modifica ni referencia el repo
[`template-ecommerce-ui`][repo-ui].

## Iniciativas relacionadas

- `crear-template-ecomerce-ui-server` (cerrada): produjo los
  8 provisioners que `setup.sh` orquesta.
- `crear-start-sh` (futura): arranque de daemons en WSL2 sin
  systemd. Problema distinto al aprovisionamiento.

<!-- Referencias Markdown -->
[doc-index]: index-crear-setup-sh.md
[doc-alcance]: alcance-crear-setup-sh.md
[doc-analisis]: analisis-crear-setup-sh.md
[doc-plan]: plan-crear-setup-sh.md
[doc-tareas]: tareas-crear-setup-sh.md
[doc-progreso]: progreso-crear-setup-sh.md
[doc-upgrade]: ../../../upgrade-server-systemless.md
[repo-server]: https://github.com/jcg-admin/template-ecommerce-server
[repo-ui]: https://github.com/jcg-admin/template-ecommerce-ui
