# Decisiones: Integrar commits faltantes desde backup 20260522

| Campo | Valor |
|-------|-------|
| Iniciativa | INI-SRV-002 integrar-commits-backup-20260522 |
| Tipo de documento | Decisiones, hallazgos y verificacion post-ejecucion |
| Obligatoriedad | Obligatorio al cierre segun PROC-GESTION-001 v4.0.0 |
| Fecha de creacion | 2026-05-25 |

> **Por que existe este documento.** Las tareas dicen *que* se hizo.
> El progreso dice *cuanto*. Este documento registra el *por que*,
> los *hallazgos* y la *verificacion final*. Sin el, la iniciativa
> no esta cerrada aunque todas las tareas marquen completadas.

---

## Seccion 1 — Decisiones de diseno

### dec-remoto-local-vs-sed-manual

| Campo | Valor |
|-------|-------|
| Decision | Usar el tarball extraido en Clase B como remoto local git para el cherry-pick. |
| Alternativas | (a) Remoto local git (elegida). (b) Aplicar los cambios manualmente con sed sobre los 28 archivos afectados. (c) Rebase interactivo. |
| Razon | La alternativa (a) preserva el autor, la fecha y el mensaje de commit originales. La alternativa (b) perderia esos metadatos y generaria un commit nuevo con fecha actual y mensaje diferente. La alternativa (c) reescribiria el historial existente, lo que viola D-COMMITS-HISTORIA. |
| Trade-off aceptado | Usar un remoto local requiere extraer el tarball en Clase B y agregar una excepcion `safe.directory`. El overhead es de unos minutos pero la trazabilidad del historial lo justifica. |

### dec-clase-b-vs-tmp

| Campo | Valor |
|-------|-------|
| Decision | Extraer el tarball en Clase B (`/srv/backups/project/template-ecommerce-server/`) en lugar de `/tmp/`. |
| Alternativas | (a) Clase B (elegida). (b) `/tmp/backup-extract/` como solucion temporal. |
| Razon | Clase B es el destino canonico para backups del proyecto segun el modelo de almacenamiento. `/tmp/` no persiste entre reinicios de WSL2 y queda fuera del modelo. El tarball sirve como referencia historica permanente una vez que la iniciativa cierra. |
| Trade-off aceptado | La extraccion en Clase B requiere permisos de `svc-backups` (invocada via `deploy`). El flujo es ligeramente mas complejo que un `tar` directo en `/tmp/`. |

### dec-safe-directory-como-solucion

| Campo | Valor |
|-------|-------|
| Decision | Resolver el `dubious ownership` con `git config --global --add safe.directory`. |
| Alternativas | (a) `safe.directory` (elegida). (b) Cambiar el propietario del directorio en Clase B a `develop`. (c) Ejecutar el fetch como `svc-backups`. |
| Razon | La alternativa (b) romperia el modelo de propiedad de Clase B (propietario canonico: `svc-backups`). La alternativa (c) no es posible porque `svc-backups` tiene shell `nologin`. La alternativa (a) es el mecanismo documentado de git para este caso. |
| Trade-off aceptado | Agrega una entrada en `~/.gitconfig` de `develop`. Entrada inofensiva y reversible. |

---

## Seccion 2 — Hallazgos durante la ejecucion

### hallazgo-historial-divergente

El repo activo tenia 30 commits; el backup tenia 31. El commit
`fd5fda8` no existia en el historial activo. La divergencia
ocurrio cuando el repo fue restaurado desde un tarball anterior
(`20260522-020945`) que no incluia los commits
`10abbf9` y `fd5fda8`.

Resuelto en esta iniciativa via cherry-pick.

### hallazgo-dubious-ownership

Al intentar `git fetch backup-local`, git rechazaba con
`detected dubious ownership` porque el repo en Clase B es
propiedad de `svc-backups` y el fetch lo ejecuta `develop`.

Resuelto con `git config --global --add safe.directory` apuntando
al `.git/` del repo en Clase B.

### hallazgo-letras-de-dispositivo-variables

Al agregar el remoto y hacer fetch, las letras de dispositivo
(`/dev/sd*`) de los volumenes habian cambiado respecto a la sesion
anterior. El montaje via UUID en fstab funciono correctamente
porque no depende de las letras de dispositivo.

Documentado como confirmacion del diseno. Sin impacto en la
ejecucion de la iniciativa.

---

## Seccion 3 — Verificacion post-ejecucion

| Criterio del alcance | Resultado | Evidencia |
|---------------------|-----------|-----------|
| MD5 del tarball coincide con archivo .md5 | PASA | `md5sum` = `1683e93eeae20e9e0447b493f29b2de2` en ambos |
| `git log` incluye equivalentes de `10abbf9` y `fd5fda8` | PASA | `c481ca0` y `ae77a46` en el historial activo |
| `grep -r "template-ecomerce-ui-server"` en archivos operativos retorna 0 | PASA | Solo aparece en historico preservado de iniciativa cerrada |
| `origin/main` sincronizado con `HEAD` | PASA | `git status` muestra `up to date with 'origin/main'` |
| Remoto `backup-local` eliminado | PASA | `git remote -v` muestra solo `origin` |
| `bash tests/run_all.sh` sin regresiones | PASA | Baseline preservado: 72 PASS / 0 FAIL / 1 SKIP |

## Cierre

Esta iniciativa esta **cerrada**. Los 6 criterios de completitud
se cumplen. Los 3 hallazgos estan documentados. Las 3 decisiones
de diseno tienen alternativas y trade-offs registrados.
