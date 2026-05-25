# Alcance: Agregar logging a archivo en scripts y provisioners

| Campo | Valor |
|-------|-------|
| Iniciativa | agregar-logging-a-archivo |
| Estado | En ejecucion |
| Version | 1.0.0 |
| Fecha de creacion | 2026-05-26 |

## Por que existe esta iniciativa

Cuando `verify.sh` se ejecuta como usuario `deploy` (sin ser root),
el check de firewall llamaba `ufw status` sin privilegios, lo que
causaba que `set -euo pipefail` abortara el script a mitad de
ejecucion. El operador no tenia forma de saber que checks habian
pasado antes del corte porque el output solo va a pantalla.

El problema raiz no es el abort sino la ausencia de un log persistente:
si la sesion SSH se interrumpe, si el terminal se cierra, o si el
script falla a mitad, no queda registro de lo que ocurrio.

`utils/logging.sh` ya tiene `init_log` y `_write_log` implementados
desde INI-SRV-001. Ningun script los usa todavia. Esta iniciativa
activa esa infraestructura en los 10 scripts del repo.

## Que cubre esta iniciativa

1. **`.gitignore`**: agregar `logs/*.log` para que los archivos de
   log no se versionen.

2. **`logs/.gitkeep`**: archivo vacio versionado que garantiza que
   el directorio `logs/` existe con el propietario correcto (develop)
   desde el clon inicial. Sin esto, si `init_log` crea el directorio
   en el primer uso como root, develop no puede escribir despues.

3. **`init_log "operations"`** agregado a 10 scripts, inmediatamente
   despues del bloque de source de utils:

   | Script | Tipo |
   |--------|------|
   | `scripts/setup.sh` | Script operativo |
   | `scripts/start.sh` | Script operativo |
   | `scripts/verify.sh` | Script operativo |
   | `scripts/renew_ssl.sh` | Script operativo |
   | `provisioners/nginx/install.sh` | Provisioner |
   | `provisioners/nginx/setup_vhost.sh` | Provisioner |
   | `provisioners/ssl/setup_ssl.sh` | Provisioner |
   | `provisioners/security/setup_fail2ban.sh` | Provisioner |
   | `provisioners/security/setup_ssh_hardening.sh` | Provisioner |
   | `provisioners/firewall/setup_firewall.sh` | Provisioner |

4. **`docs/operaciones.md`**: agregar nota sobre la ubicacion del
   log y como consultarlo en tiempo real y en post-mortem.

## Criterio de completitud

1. `logs/.gitkeep` existe en el repo y `logs/` esta en `.gitignore`.
2. `git ls-files logs/` muestra solo `.gitkeep`, no archivos `.log`.
3. Los 10 scripts tienen `init_log "operations"` en la posicion
   correcta (despues de source de utils, antes de cualquier accion).
4. Al ejecutar cualquiera de los 10 scripts, `logs/operations.log`
   se crea o actualiza con las entradas de esa ejecucion.
5. Dos ejecuciones consecutivas de `verify.sh` producen dos bloques
   de entradas en el mismo `logs/operations.log` (acumulativo).
6. `bash tests/run_all.sh`: PASS >= 74, FAIL = 0.
7. Auditoria de links: sin nuevos rotos.

## Fuera de alcance

| Item | Razon |
|------|-------|
| Modificar `utils/logging.sh` | La infraestructura ya funciona. D-INIT-LOG-EXISTENTE. |
| Rotacion automatica de logs | Requiere analisis de retencion y frecuencia. D-SIN-ROTACION. |
| Log centralizado fuera del repo | Herramientas como syslog, journald o ELK estan fuera del scope de este template. |
| Logs de provisioners externos | acme.sh tiene su propio log en `~/.acme.sh/acme.sh.log`. No se integra. |
| Notificaciones por email o webhook | Fuera del scope de esta iniciativa. |

## Estimacion de esfuerzo

| Fase | Descripcion | Esfuerzo |
|------|-------------|----------|
| F0 | Analisis + PM docs | 20 min |
| F1 | .gitignore, .gitkeep, init_log en 10 scripts | 20 min |
| F2 | Actualizar docs/operaciones.md | 10 min |
| F3 | Verificacion y cierre | 10 min |
| Total | | ~1 hora |
