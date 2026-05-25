# Analisis: Agregar logging a archivo en scripts y provisioners

## Auditoria de `init_log` en `utils/logging.sh`

```bash
init_log() {
    local name="${1:-script}"
    local log_dir="${PROJECT_ROOT}/logs"
    mkdir -p "$log_dir"
    _LOG_FILE="${log_dir}/${name}.log"
    echo "=== $(date '+%Y-%m-%d %H:%M:%S') -- Inicio ===" >> "$_LOG_FILE"
}

_write_log() {
    [[ -n "$_LOG_FILE" ]] && echo "$(date '+%H:%M:%S') $*" >> "$_LOG_FILE" || true
}
```

`init_log` ya hace todo lo necesario:

- Crea `${PROJECT_ROOT}/logs/` si no existe.
- Establece `_LOG_FILE` como variable global del proceso.
- Escribe un separador de inicio con timestamp.
- `_write_log` appends a `_LOG_FILE` si esta definido; no-op si no.

Todas las funciones `log_header`, `log_success`, `log_info`,
`log_warn`, `log_error`, `log_fatal`, `log_separator` y `log_step`
llaman a `_write_log` internamente. Al activar `init_log`, el
logging a archivo ocurre automaticamente sin cambiar ninguna funcion.

## Problema de permisos del directorio `logs/`

`init_log` llama `mkdir -p "$log_dir"`. El directorio se crea con
el propietario del proceso que ejecuta el script:

| Escenario | Usuario | Propietario logs/ | develop puede escribir? |
|-----------|---------|-------------------|-------------------------|
| deploy corre setup.sh con sudo | root | root:root 755 | NO |
| develop corre verify.sh | develop | develop:develop 755 | SI |
| deploy corre setup.sh con sudo DESPUES de verify.sh | root | develop:develop 755 | root siempre puede |

El problema ocurre cuando el primer script en ejecutarse corre como
root: `logs/` queda con propietario root y develop no puede escribir.

**Solucion**: versionar `logs/.gitkeep`. Al clonar el repo, el
directorio `logs/` existe con el propietario del usuario que clono
(develop, UID 1002). `init_log` nunca necesita crearlo; solo abre
el archivo de log dentro de un directorio ya existente con los
permisos correctos.

Adicionalmente, modificar `init_log` para hacer `chmod g+w` en el
directorio al crearlo NO es necesario con `.gitkeep` en su lugar,
pero si `init_log` crea el directorio (caso edge: directorio
eliminado manualmente), deberia hacer `chmod 777 "$log_dir"` para
que cualquier usuario pueda escribir. Esto queda como decision:
D-INIT-LOG-EXISTENTE indica no modificar logging.sh en esta
iniciativa; se acepta el edge case.

## Inventario de scripts a modificar

Todos los scripts del repo hacen `source utils/logging.sh` y por
tanto tienen acceso a `init_log`. Se agrega la llamada despues del
bloque de source, antes de cualquier otra accion:

```bash
# Patron de insercion (igual en todos):
source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/core.sh"
# ...otros source...
init_log "operations"   # <- agregar aqui
```

| Script | Linea aproximada de insercion | Notas |
|--------|-------------------------------|-------|
| `scripts/setup.sh` | Tras el bloque de 3 source | Corre como root via sudo |
| `scripts/start.sh` | Tras el bloque de 2 source | Corre como root via sudo |
| `scripts/verify.sh` | Tras el bloque de 4 source | Corre como deploy (no root) |
| `scripts/renew_ssl.sh` | Tras el bloque de source | Corre como root (cron o deploy) |
| `provisioners/nginx/install.sh` | Tras el bloque de source | Root |
| `provisioners/nginx/setup_vhost.sh` | Tras el bloque de source | Root |
| `provisioners/ssl/setup_ssl.sh` | Tras el bloque de source | Root |
| `provisioners/security/setup_fail2ban.sh` | Tras el bloque de source | Root |
| `provisioners/security/setup_ssh_hardening.sh` | Tras el bloque de source | Root |
| `provisioners/firewall/setup_firewall.sh` | Tras el bloque de source | Root |

**Total**: 10 archivos, 1 linea cada uno.

## Formato del archivo de log

Ejemplo de `logs/operations.log` tras dos ejecuciones:

```
=== 2026-05-26 01:00:00 -- Inicio ===
01:00:01 HEADER template-ecommerce-server -- Verificacion completa
01:00:01 INFO   Dominio: midominio.com
01:00:02 HEADER PASO: Variables de entorno (.env)
01:00:02 OK   [OK]   DOMAIN=midominio.com
...
01:00:15 OK   Errores:      0
=== 2026-05-26 01:05:00 -- Inicio ===
01:05:01 HEADER template-ecommerce-server -- Verificacion completa
...
```

Cada bloque `=== ... -- Inicio ===` marca el inicio de una ejecucion.
Las entradas no tienen colores ANSI (logging.sh omite colores cuando
stdout no es terminal; el archivo se escribe via `_write_log`, no a
stdout).

## `.gitignore` actual del repo

```bash
ls /tmp/project/template-ecommerce-server/.gitignore 2>/dev/null \
    || echo "No existe .gitignore"
```

Si no existe, se crea. Si existe, se agrega una entrada `logs/*.log`.

## Riesgos identificados

| ID | Riesgo | Mitigacion |
|----|--------|------------|
| R-1 | `logs/` creado como root antes que develop ejecute verify.sh | `.gitkeep` versionado garantiza que el directorio existe con propietario develop desde el clon |
| R-2 | `logs/operations.log` crece indefinidamente en entornos de alta actividad | El archivo crece lentamente en uso normal (texto plano, operaciones ocasionales); el operador rota manualmente. Rotacion automatica es mejora futura |
| R-3 | `init_log` sobreescribe `_LOG_FILE` si un script llama a otro script que tambien llama init_log | Los scripts que se llaman entre si (ej: setup.sh llama a provisioners) son subprocesos bash separados; cada uno tiene su propio scope de variables. No hay colision. |
