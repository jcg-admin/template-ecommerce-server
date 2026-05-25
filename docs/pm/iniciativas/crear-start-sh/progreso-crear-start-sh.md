# Progreso — `crear-start-sh`

Registro cronologico de eventos siguiendo PROC-GESTION-001 con
las clases definidas en el procedimiento. Cada evento es
atomico y refleja lo que ocurrio en el momento en que se
produjo; los hallazgos se registran al descubrirse, no al
cerrar la tarea.

## Eventos

| Timestamp (UTC) | Clase | Referencia | Detalle |
|-----------------|-------|------------|---------|
| 2026-05-25T20:30:00 | Apertura | iniciativa | **Iniciativa `crear-start-sh` formalmente abierta.** En entornos WSL2 sin systemd los daemons no arrancan automaticamente al reiniciar. `docs/upgrade-server-systemless.md` documenta los comandos manuales pero no existe ningun script que los automatice. La iniciativa crea `scripts/start.sh` para cubrir este caso. |
| 2026-05-25T20:30:01 | Decisiones aprobadas | D-REUTILIZA-WRAPPERS, D-IDEMPOTENTE, D-NO-SSHD, D-NO-VERIFY, D-SUDO-REQUERIDO | **5 decisiones aprobadas al abrir la iniciativa.** D-REUTILIZA-WRAPPERS: usar `svc_is_active` y `svc_start` de core.sh; no reinventar la logica de deteccion de entorno. D-IDEMPOTENTE: omitir daemons ya activos sin error. D-NO-SSHD: no arrancar sshd (lo gestiona Windows en WSL2 o el init del VPS). D-NO-VERIFY: no llamar a verify.sh al final (verificacion completa es responsabilidad del operador). D-SUDO-REQUERIDO: arrancar daemons requiere privilegios. |
| 2026-05-25T20:30:02 | Plan | apertura | **Plan en 4 fases F0..F3 documentado (~1h total).** Detalle en `plan-crear-start-sh.md`. Fase F0 en ejecucion. |
| 2026-05-25T20:30:03 | Inicio de fase | F0 | **Inicio de Fase F0 (Analisis + PM docs).** Esfuerzo estimado 20 min. |
| 2026-05-25T20:30:04 | Inicio de tarea | T-001 | Comienzo T-001. Leer `utils/core.sh` wrappers `svc_*`, `docs/upgrade-server-systemless.md` y `scripts/setup.sh` como referencia de patron. |
| 2026-05-25T20:33:00 | Hallazgo durante la ejecucion | T-001 | **Los wrappers `svc_is_active` y `svc_start` cubren exactamente el caso de uso de `start.sh`.** `svc_start nginx` internamente llama `/usr/sbin/nginx` sin systemd y `systemctl start nginx` con el. `svc_start fail2ban` internamente llama `fail2ban-server -b` sin systemd. `start.sh` no necesita invocar ningun binario directamente; toda la logica de entorno esta en los wrappers. Esto hace `start.sh` significativamente mas simple de lo que habria sido sin esa infraestructura preexistente. |
| 2026-05-25T20:33:01 | Hallazgo durante la ejecucion | T-001 | **El orden de arranque importa: nginx antes que fail2ban.** Las jails `nginx-limit-req` y `nginx-botsearch` de fail2ban monitorizan logs de nginx. Aunque fail2ban no requiere estrictamente que nginx este corriendo para arrancar, es mas correcto arrancarlos en el orden logico de dependencia. Este orden coincide con el orden del setup (install.sh antes que setup_fail2ban.sh). |
| 2026-05-25T20:34:00 | Cierre de tarea | T-001 | Cierre T-001. Helpers identificados: `svc_is_active`, `svc_start`, `command_exists`, `is_systemd`, funciones de logging. Patron del script (boilerplate, funciones privadas con `_`, MAIN al final) confirmado via `setup.sh` como referencia. |
| 2026-05-25T20:34:01 | Inicio de tarea | T-002 | Comienzo T-002. Disenar flujo de `_start_daemon`, orden de arranque y riesgos. |
| 2026-05-25T20:36:00 | Cierre de tarea | T-002 | Cierre T-002. Flujo diseñado: 1 diagrama Mermaid (decision de `_start_daemon`). 5 decisiones D-* aprobadas. 2 riesgos: R-1 (falso positivo svc_is_active, mitigado con segunda verificacion post-arranque) y R-2 (orden nginx antes fail2ban, mitigado por orden fijo en main). |
| 2026-05-25T20:36:01 | Inicio de tarea | T-003 | Comienzo T-003. Crear 6 documentos PM. |
| 2026-05-25T20:50:00 | Cierre de tarea | T-003 | Cierre T-003. 6 archivos PM creados en `crear-start-sh/`. |
| 2026-05-25T20:50:01 | Fase cerrada | F0 | **Cierre de Fase F0 (Analisis + PM docs).** 3 tareas cerradas. 6 documentos PM producidos. 1 diagrama Mermaid en analisis.md. 5 decisiones D-* ratificadas. 2 hallazgos. Esfuerzo real: ~20 min. Siguiente: F1 (Crear scripts/start.sh). Pendiente confirmacion del usuario. |

## Contadores

| Tipo de evento | Cantidad |
|----------------|----------|
| Apertura | 1 |
| Decisiones aprobadas | 1 |
| Plan | 1 |
| Inicio de fase | 1 |
| Fase cerrada | 1 |
| Inicio de tarea | 3 |
| Cierre de tarea | 3 |
| Hallazgo durante la ejecucion | 2 |
| Total | 13 |
