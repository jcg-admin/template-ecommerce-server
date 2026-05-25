# Decisiones: Crear script de arranque de daemons

| Campo | Valor |
|-------|-------|
| Iniciativa | INI-SRV-006 crear-start-sh |
| Tipo de documento | Decisiones, hallazgos y verificacion post-ejecucion |
| Obligatoriedad | Obligatorio al cierre segun PROC-GESTION-001 v4.0.0 |
| Fecha de creacion | 2026-05-25 |

> **Por que existe este documento.** Las tareas dicen *que* se hizo.
> El progreso dice *cuanto*. Este documento registra el *por que*,
> los *hallazgos* y la *verificacion final*. Sin el, la iniciativa
> no esta cerrada aunque todas las tareas marquen completadas.

---

## Seccion 1 — Decisiones de diseno

### dec-reutilizar-svc-wrappers

| Campo | Valor |
|-------|-------|
| Decision | `start.sh` usa `svc_is_active` y `svc_start` de `utils/core.sh` en lugar de invocar binarios directamente. |
| Alternativas | (a) Wrappers de `core.sh` (elegida). (b) Invocar `/usr/sbin/nginx` y `fail2ban-server -b` directamente. (c) Mezcla: `svc_start` para nginx, comando directo para fail2ban. |
| Razon | Los wrappers encapsulan completamente la logica de deteccion de systemd y los comandos correctos para cada daemon en cada entorno. Duplicar esa logica en `start.sh` crearia una segunda fuente de verdad. Si en el futuro `svc_start` cambia su implementacion, `start.sh` hereda el cambio sin modificacion. |
| Trade-off aceptado | `start.sh` depende de `utils/core.sh`. Si `core.sh` no es sourceable, el script falla antes de ejecutar ninguna accion. Es una dependencia explicita y correcta: sin `core.sh` el repo no esta en estado valido de ninguna forma. |

### dec-idempotencia-via-svc-is-active

| Campo | Valor |
|-------|-------|
| Decision | Verificar con `svc_is_active` antes de cada `svc_start` para omitir daemons ya corriendo. |
| Alternativas | (a) Verificar antes de arrancar (elegida). (b) Intentar arrancar siempre e ignorar el error si ya esta corriendo. (c) Detener y rearrancar siempre (restart). |
| Razon | La alternativa (b) depende de que el error de "ya corriendo" sea distinguible de otros errores, lo cual varia por daemon y version. La alternativa (c) causa downtime innecesario si el daemon ya esta activo y correctamente configurado. La alternativa (a) es explicita, predecible y no depende de codigos de salida especificos de cada daemon. |
| Trade-off aceptado | Hay una ventana de tiempo entre `svc_is_active` y `svc_start` donde el daemon podria cambiar de estado. En entornos reales de WSL2 este race condition es improbable; se acepta. |

### dec-no-sshd

| Campo | Valor |
|-------|-------|
| Decision | `start.sh` no arranca `sshd`. |
| Alternativas | (a) Excluir sshd (elegida). (b) Incluir sshd con guard de deteccion de entorno. (c) Flag opcional `--with-ssh`. |
| Razon | En WSL2 el SSH lo gestiona Windows directamente; intentar arrancar `sshd` desde bash causaria conflictos. En produccion con systemd, sshd arranca en el boot; si no esta corriendo hay un problema mayor que `start.sh` no debe intentar resolver. La alternativa (b) requiere deteccion de entorno fragil. La alternativa (c) complejiza el script para un caso de uso que no existe en la practica. |
| Trade-off aceptado | Si un operador necesita arrancar sshd manualmente en un entorno especifico, debe hacerlo directamente. `start.sh` no es el mecanismo para eso. |

### dec-warn-si-no-instalado-no-error

| Campo | Valor |
|-------|-------|
| Decision | Si un daemon no esta instalado, emitir WARN y continuar (no abortar). |
| Alternativas | (a) WARN y continuar (elegida). (b) ERROR y abortar si cualquier daemon no esta instalado. |
| Razon | Un escenario valido es tener nginx instalado pero fail2ban pendiente (por ejemplo, en una instalacion parcial o en CI que solo testea nginx). Abortar en ese caso impide arrancar nginx innecesariamente. La alternativa (a) permite que el script haga lo que puede y reporte claramente lo que omitio. |
| Trade-off aceptado | El script puede retornar exito aunque un daemon no este instalado. El operador debe leer el output para saber que se omitio. El resumen final hace esto explicito. |

---

## Seccion 2 — Hallazgos durante la ejecucion

### hallazgo-sleep-1-necesario-para-verificacion-post-arranque

`svc_is_active` inmediatamente despues de `svc_start` puede
retornar falso negativo: el daemon arranco correctamente pero aun
no ha inicializado su socket o proceso antes de que el check se
ejecute. Un `sleep 1` entre `svc_start` y la verificacion
post-arranque elimina este falso negativo en la practica.

El valor de 1 segundo es conservador para daemons de sistema.
Nginx y fail2ban inicializan en menos de 200ms en hardware normal.

### hallazgo-test-provisioner-syntax-cubre-start-sh-automaticamente

`test_provisioner_syntax.sh` usa `find ... -name "*.sh"` sobre
todo el repo. Al crear `scripts/start.sh`, quedo cubierto
automaticamente sin modificar ningun test existente. El PASS
count paso de 18 a 19, y `run_all.sh` de 73 a 74.

---

## Seccion 3 — Verificacion post-ejecucion

| Criterio del alcance | Resultado | Evidencia |
|---------------------|-----------|-----------|
| `scripts/start.sh` existe y pasa `bash -n` | PASA | `bash -n scripts/start.sh` retorna 0 |
| `test_provisioner_syntax.sh` reporta PASS para `start.sh` | PASA | 19 PASS / 0 FAIL en test_provisioner_syntax |
| `_start_daemon` arranca Nginx si no esta corriendo | PASA | Revision de codigo: flujo `svc_is_active` -> false -> `svc_start nginx` |
| `_start_daemon` arranca fail2ban si no esta corriendo | PASA | Revision de codigo: flujo `svc_is_active` -> false -> `svc_start fail2ban` |
| Daemon ya activo se omite sin error | PASA | Revision de codigo: `svc_is_active` -> true -> `return 0` |
| Daemon no instalado emite WARN y continua | PASA | Revision de codigo: `command_exists` -> false -> `log_warn` -> `return 0` |
| `README.md` tiene seccion de arranque WSL2 | PASA | Seccion "Arranque de daemons en WSL2 (cada reinicio)" agregada |
| `docs/upgrade-server-systemless.md` referencia `start.sh` | PASA | Resumen ejecutivo actualizado con `sudo bash scripts/start.sh` |
| `bash tests/run_all.sh` PASS >= 74, FAIL = 0 | PASA | 74 PASS / 0 FAIL / 1 SKIP |

## Cierre

Esta iniciativa esta **cerrada**. Los 9 criterios de completitud
se cumplen. Los 2 hallazgos estan documentados. Las 4 decisiones
de diseno tienen alternativas y trade-offs registrados.
