# Alcance: Crear script de arranque de daemons

## Que cubre esta iniciativa

Un script `scripts/start.sh` que arranca Nginx y fail2ban en
entornos sin systemd (WSL2 sin `systemd=true`, contenedores, CI).
En entornos con systemd los daemons arrancan solos al boot y el
script los detecta como ya activos sin hacer nada.

El script:

- Verifica que cada daemon este instalado antes de intentar
  arrancarlo.
- Detecta si cada daemon ya esta corriendo via `svc_is_active`
  y lo omite si es el caso (idempotencia).
- Arranca Nginx y fail2ban via `svc_start` en ese orden.
- Requiere sudo o root.

Ademas actualiza la documentacion existente para referenciar
`start.sh` como la forma estandar de arranque manual.

## Criterio de completitud

1. `scripts/start.sh` existe y pasa `bash -n`.
2. `test_provisioner_syntax.sh` reporta PASS para `start.sh`.
3. Si Nginx no esta corriendo, `start.sh` lo arranca.
4. Si fail2ban no esta corriendo, `start.sh` lo arranca.
5. Si un daemon ya esta activo, `start.sh` lo omite sin error.
6. Si un daemon no esta instalado, `start.sh` emite WARN y
   continua (no aborta; el otro daemon puede estar bien).
7. `README.md` tiene instrucciones de arranque para WSL2.
8. `docs/upgrade-server-systemless.md` referencia `start.sh`.
9. `bash tests/run_all.sh` retorna PASS >= 74, FAIL = 0.

## Fuera de alcance

| Item | Razon |
|------|-------|
| Arrancar sshd | En WSL2 lo gestiona Windows; en produccion el init del sistema. D-NO-SSHD. |
| Llamar a verify.sh | Verificacion completa es responsabilidad del operador, no del arranque. D-NO-VERIFY. |
| Recargar configuracion | Si el operador quiere recargar config de Nginx usa `nginx -s reload` directamente. |
| Detener daemons | No hay stop.sh en este alcance. |
| Configurar arranque automatico | En WSL2 sin systemd no hay mecanismo nativo que start.sh pueda registrar. |

## Estimacion de esfuerzo

| Fase | Esfuerzo | Notas |
|------|----------|-------|
| F0 | 20 min | Analisis + PM docs |
| F1 | 20 min | Crear scripts/start.sh |
| F2 | 10 min | Actualizar README.md y upgrade-server-systemless.md |
| F3 | 10 min | Verificacion y cierre |
| Total | ~1 hora | |
