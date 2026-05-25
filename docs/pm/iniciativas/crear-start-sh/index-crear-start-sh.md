# Iniciativa: `crear-start-sh`

| Campo | Valor |
|-------|-------|
| Artefacto | `crear-start-sh` |
| Tipo | Iniciativa de desarrollo |
| Estado | En ejecucion |
| Version | 1.0.0 |
| Fecha de creacion | 2026-05-25 |
| Fecha de apertura formal | 2026-05-25 |
| Autor | Nestor Monroy |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 |
| Repositorio | [`template-ecommerce-server`][repo-server] |
| Orden de backlog | (no aplica: abierta directamente como continuacion natural de `crear-setup-sh`) |
| Iniciativa previa relacionada | `crear-setup-sh` (cerrada) — `setup.sh` provisiona; `start.sh` arranca |

## Que hace esta iniciativa

En entornos sin systemd (WSL2 sin `systemd=true`, contenedores,
CI runners) los daemons no arrancan automaticamente al
reiniciar. El operador debe arrancarlos manualmente con
comandos que ya estan documentados en
`docs/upgrade-server-systemless.md` pero que requieren
recordarlos y ejecutarlos cada vez.

`start.sh` automatiza ese arranque: verifica que cada daemon
no este ya corriendo y lo arranca si es necesario. Reutiliza
los wrappers `svc_is_active` y `svc_start` de `utils/core.sh`,
que ya manejan tanto entornos con systemd como sin el.

En entornos con systemd (VPS de produccion), los daemons
arrancan solos en el boot y `start.sh` no es necesario, pero
es seguro ejecutarlo: detecta que los servicios ya estan
activos y sale sin hacer nada.

## Filosofia rectora

`start.sh` arranca; no instala, no configura, no verifica la
correctitud del entorno. Su unico trabajo es levantar los
daemons que ya estan instalados y configurados por los
provisioners.

Principios:

1. **Reutilizar, no reimplementar**: usa `svc_is_active` y
   `svc_start` de `core.sh`. Esos wrappers ya encapsulan la
   logica de deteccion de systemd y los comandos nativos de
   cada daemon.

2. **Idempotente**: si un daemon ya esta corriendo, el script
   lo detecta y no hace nada con el. Ejecutar `start.sh` dos
   veces es seguro.

3. **Sin efectos secundarios**: no modifica configuracion, no
   recarga vhosts, no renueva certificados. Solo arranca.

Excepciones explicitas:

- `sshd` NO se arranca. En WSL2 lo gestiona Windows; en
  produccion lo gestiona systemd o el init del VPS. Intentar
  arrancarlo desde `start.sh` crearia conflictos.
- `start.sh` no llama a `verify.sh`. La verificacion completa
  del entorno es responsabilidad del operador tras el arranque.

## Que produce

| Entregable | Descripcion |
|------------|-------------|
| `scripts/start.sh` | Script de arranque de daemons (Nginx + fail2ban) |
| `README.md` actualizado | Seccion de arranque en entornos sin systemd |
| `docs/upgrade-server-systemless.md` actualizado | Referencia a `start.sh` en el resumen ejecutivo |

## Documentos de la iniciativa

| Documento | Estado |
|-----------|--------|
| [index-crear-start-sh.md][doc-index] | Este archivo |
| [alcance-crear-start-sh.md][doc-alcance] | Completado |
| [analisis-crear-start-sh.md][doc-analisis] | Completado |
| [plan-crear-start-sh.md][doc-plan] | Completado |
| [tareas-crear-start-sh.md][doc-tareas] | Completado |
| [progreso-crear-start-sh.md][doc-progreso] | Activo (bitacora cronologica) |

## Decisiones aprobadas

| ID | Decision | Justificacion |
|----|----------|---------------|
| D-REUTILIZA-WRAPPERS | `start.sh` usa `svc_is_active` y `svc_start` de `utils/core.sh` en lugar de invocar comandos nativos directamente. | Los wrappers ya encapsulan la deteccion de systemd y los comandos correctos para cada daemon en cada entorno. Duplicar esa logica en `start.sh` crearia deuda de mantenimiento. |
| D-IDEMPOTENTE | Si un daemon ya esta corriendo, `start.sh` lo detecta y lo omite sin error. | El script debe ser seguro de ejecutar multiples veces sin efectos adversos. |
| D-NO-SSHD | `start.sh` no arranca sshd. | En WSL2 lo gestiona Windows. En produccion lo gestiona systemd o el init del VPS. Arrancarlo desde `start.sh` causaria conflictos o errores en ambos entornos. |
| D-NO-VERIFY | `start.sh` no llama a `verify.sh` al final. | `verify.sh` hace 12 checks que incluyen conexiones de red, estado de certificados SSL y jails de fail2ban. Son checks de entorno completo, no de arranque. El operador lo ejecuta cuando quiere; `start.sh` solo arranca. |
| D-SUDO-REQUERIDO | `start.sh` requiere sudo o root. | Arrancar Nginx y fail2ban requiere privilegios de sistema en ambos modos (systemd y nativo). |

## Alcance cruzado con otros repos

No aplica. `start.sh` opera exclusivamente sobre los daemons
del servidor local. No modifica ni referencia el repo
`template-ecommerce-ui`.

## Iniciativas relacionadas

- `crear-setup-sh` (cerrada): `setup.sh` instala y configura.
  `start.sh` arranca lo que `setup.sh` dejo instalado.
- `crear-template-ecomerce-ui-server` (cerrada): produjo los
  provisioners y la documentacion `upgrade-server-systemless.md`
  que describe el problema que `start.sh` resuelve.

<!-- Referencias Markdown -->
[doc-index]: index-crear-start-sh.md
[doc-alcance]: alcance-crear-start-sh.md
[doc-analisis]: analisis-crear-start-sh.md
[doc-plan]: plan-crear-start-sh.md
[doc-tareas]: tareas-crear-start-sh.md
[doc-progreso]: progreso-crear-start-sh.md
[repo-server]: https://github.com/jcg-admin/template-ecommerce-server
