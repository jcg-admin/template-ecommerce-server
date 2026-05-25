# Alcance — `crear-start-sh`

## Que cubre

1. **Script `scripts/start.sh`** que:
   - Verifica que cada daemon este instalado antes de intentar
     arrancarlo (guard de prerequisito).
   - Detecta si cada daemon ya esta corriendo via
     `svc_is_active` y lo omite si es el caso.
   - Arranca Nginx y fail2ban via `svc_start` en ese orden.
   - Reporta el estado final de cada daemon con mensajes
     claros de exito o fallo.
   - Requiere sudo o root (arrancar daemons requiere
     privilegios).
   - Es idempotente: seguro de ejecutar multiples veces.

2. **Actualizacion de `README.md`**: agregar seccion de
   arranque manual para entornos WSL2 sin systemd.

3. **Actualizacion de `docs/upgrade-server-systemless.md`**:
   agregar referencia a `start.sh` en el resumen ejecutivo
   como la forma estandar de arrancar los daemons.

4. **Cobertura de tests automaticos**: `test_provisioner_syntax.sh`
   cubre automaticamente `start.sh` sin modificar los tests
   existentes.

## Criterio de completitud

1. `scripts/start.sh` existe y pasa `bash -n`.
2. `test_provisioner_syntax.sh` incluye `start.sh` con PASS.
3. `start.sh` arranca Nginx si no esta corriendo.
4. `start.sh` arranca fail2ban si no esta corriendo.
5. `start.sh` omite silenciosamente un daemon si ya esta activo.
6. `start.sh` aborta con mensaje claro si un daemon no esta
   instalado.
7. `README.md` tiene seccion de arranque WSL2.
8. `docs/upgrade-server-systemless.md` referencia `start.sh`.
9. `bash tests/run_all.sh` retorna PASS >= 73, FAIL = 0.

## Fuera de alcance

| Item | Razon |
|------|-------|
| Arrancar `sshd` | En WSL2 lo gestiona Windows; en produccion el init del sistema. `start.sh` no toca SSH (D-NO-SSHD). |
| Llamar a `verify.sh` | Verificacion completa del entorno es responsabilidad del operador, no del arranque (D-NO-VERIFY). |
| Recargar configuracion | `start.sh` arranca, no recarga. Si el operador quiere recargar config de Nginx usa `nginx -s reload`. |
| Detener daemons | No hay `stop.sh` en este alcance. En WSL2 los daemons se detienen al cerrar la distro. |
| Configurar arranque automatico | En WSL2 sin systemd no hay mecanismo nativo de arranque automatico que `start.sh` pueda registrar. |

## Estimacion de esfuerzo por fase

| Fase | Descripcion | Estimado |
|------|-------------|----------|
| F0 | Analisis + PM docs | 20 min |
| F1 | Crear `scripts/start.sh` | 20 min |
| F2 | Actualizar `README.md` y `upgrade-server-systemless.md` | 10 min |
| F3 | Verificacion y cierre | 10 min |
| Total | | ~1 hora |

<!-- Referencias Markdown -->
[doc-plan]: plan-crear-start-sh.md
[repo-server]: https://github.com/jcg-admin/template-ecommerce-server
