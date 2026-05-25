# Alcance — `integrar-commits-backup-20260522`

## Que cubre

| Categoria | Detalle |
|-----------|---------|
| Verificacion de integridad | MD5 del tarball contra `.md5` del backup |
| Comparacion de historiales | Backup (31 commits) vs repo activo (30 commits) |
| Extraccion a Clase B | Tarball a `/srv/backups/project/template-ecommerce-server/` |
| Integracion de commits | Cherry-pick de `10abbf9` y `fd5fda8` en ese orden |
| Verificacion de nomenclatura | grep de `template-ecomerce-ui-server` en archivos operativos |
| Limpieza | Eliminacion del remoto temporal `backup-local` |

## Criterio de completitud

- MD5 verificado y coincidente.
- `git log --oneline` del repo activo incluye equivalentes
  de `10abbf9` y `fd5fda8` como nuevos hashes cherry-picked.
- `grep -r "template-ecomerce-ui-server"` en archivos
  operativos retorna cero resultados fuera del historico
  preservado intencionalmente.
- `origin/main` sincronizado con `HEAD`.
- Remoto `backup-local` eliminado.

## Fuera de alcance

| Item | Razon |
|------|-------|
| Reescritura de historial | Los commits faltantes se integran via cherry-pick, no rebase. El historial existente es inmutable (D-COMMITS-HISTORIA). |
| Rotacion del tarball en Clase B | El tarball es referencia permanente de este hito. La rotacion automatica es responsabilidad del proceso de backups de `svc-backups`. |
| Documentacion de la iniciativa WSL2 | Es una iniciativa separada con su propio alcance. |
| Correccion de nomenclatura en `progreso-*.md` de iniciativas cerradas | Historico inmutable per D-COMMITS-HISTORIA. |

## Estimacion de esfuerzo por fase

| Fase | Esfuerzo real |
|------|---------------|
| F0 — Analisis | 15 min |
| F1 — Extraccion a Clase B | 5 min |
| F2 — Cherry-pick e integracion | 10 min |
| F3 — Verificacion y cierre | 5 min |
| Total | 35 min |
