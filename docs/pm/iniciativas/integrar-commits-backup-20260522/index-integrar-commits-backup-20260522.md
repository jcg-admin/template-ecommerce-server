# Iniciativa: `integrar-commits-backup-20260522`

| Campo | Valor |
|-------|-------|
| Slug | `integrar-commits-backup-20260522` |
| Estado | Cerrada |
| Fecha de apertura | 2026-05-25 |
| Fecha de cierre | 2026-05-25 |
| Autor / responsable | Nestor Monroy |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 |
| Repositorio | [`template-ecommerce-server`][repo-server] |
| Tipo | Mantenimiento retroactivo (documentada post-ejecucion) |

## Que hace esta iniciativa

Al comparar el tarball de backup
`template-ecommerce-server-FULL-20260522-050927-source.tar.gz`
contra el estado del repo en `origin/main`, se detectaron dos
commits presentes en el backup pero ausentes en el historial
activo:

- `10abbf9` Update README to reflect closed initiative
- `fd5fda8` Rename to template-ecommerce-server (F2)

El commit `fd5fda8` contiene el renombre masivo de 28 archivos
de `template-ecomerce-ui-server` a `template-ecommerce-server`.
Su ausencia dejaba la nomenclatura desincronizada en todo el
repo.

Esta iniciativa integra ambos commits via cherry-pick usando el
tarball en Clase B como remoto local, preservando autor, fecha y
mensaje original de cada commit.

## Entregables

| Entregable | Descripcion |
|------------|-------------|
| `c481ca0` | Cherry-pick de `10abbf9` — README actualizado |
| `ae77a46` | Cherry-pick de `fd5fda8` — Renombre 28 archivos |
| Tarball en Clase B | `template-ecommerce-server-FULL-20260522-050927-source.tar.gz` |

## Documentos de la iniciativa

| Documento | Estado |
|-----------|--------|
| [index][doc-index] | Este archivo |
| [alcance][doc-alcance] | Completado |
| [analisis][doc-analisis] | Completado |
| [plan][doc-plan] | Completado |
| [tareas][doc-tareas] | Completado |
| [progreso][doc-progreso] | Cerrado |

## Decisiones aprobadas

| ID | Descripcion |
|----|-------------|
| D-REMOTO-LOCAL | Usar el repo extraido en Clase B como remoto local para el cherry-pick, preservando metadatos originales del commit (autor, fecha, mensaje). Alternativa rechazada: aplicar cambios manualmente con sed. |
| D-CLASE-B | Extraer el tarball en `/srv/backups/project/template-ecommerce-server/` (Clase B) siguiendo el modelo de almacenamiento del proyecto. Alternativa rechazada: `/tmp/backup-extract/` (fuera del modelo). |
| D-SAFE-DIRECTORY | Agregar excepcion `safe.directory` para que `develop` pueda acceder al repo en Clase B (propietario `svc-backups`). El warning `dubious ownership` es esperado y documentado en H-3 del procedimiento de almacenamiento. |

<!-- Referencias Markdown -->
[doc-index]: index-integrar-commits-backup-20260522.md
[doc-alcance]: alcance-integrar-commits-backup-20260522.md
[doc-analisis]: analisis-integrar-commits-backup-20260522.md
[doc-plan]: plan-integrar-commits-backup-20260522.md
[doc-tareas]: tareas-integrar-commits-backup-20260522.md
[doc-progreso]: progreso-integrar-commits-backup-20260522.md
[repo-server]: https://github.com/jcg-admin/template-ecommerce-server
