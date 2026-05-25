# Iniciativa: `integrar-commits-backup-20260522`

| Campo | Valor |
|-------|-------|
| Artefacto | `integrar-commits-backup-20260522` |
| Tipo | Mantenimiento retroactivo |
| Estado | Cerrada |
| Version | 1.0.0 |
| Fecha de creacion | 2026-05-25 |
| Fecha de apertura formal | 2026-05-25 |
| Fecha de cierre | 2026-05-25 |
| Autor | Nestor Monroy |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 |
| Repositorio | [`template-ecommerce-server`][repo-server] |
| Orden de backlog | (no aplica: abierta directamente al detectar divergencia de historial entre backup y repo activo) |

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

## Filosofia rectora

Usar la infraestructura de almacenamiento existente (Clase B,
remotos locales de git) en lugar de soluciones ad-hoc. No
reescribir historial: los commits faltantes se integran via
cherry-pick, preservando autor, fecha y mensaje originales.

Excepciones explicitas: ninguna. Esta iniciativa no modifica
el historial existente ni altera archivos de codigo.

## Que produce

| Entregable | Descripcion |
|------------|-------------|
| `c481ca0` | Cherry-pick de `10abbf9` — README actualizado |
| `ae77a46` | Cherry-pick de `fd5fda8` — Renombre en 28 archivos |
| Tarball en Clase B | `template-ecommerce-server-FULL-20260522-050927-source.tar.gz` preservado como referencia historica |

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

| ID | Decision | Justificacion |
|----|----------|---------------|
| D-REMOTO-LOCAL | Usar el repo extraido en Clase B como remoto local para el cherry-pick. | Preserva metadatos originales del commit (autor, fecha, mensaje) sin necesidad de reescribir nada. Alternativa rechazada: aplicar cambios manualmente con sed (perderia los metadatos). |
| D-CLASE-B | Extraer el tarball en `/srv/backups/project/template-ecommerce-server/` (Clase B). | Sigue el modelo de almacenamiento del proyecto. Alternativa rechazada: `/tmp/backup-extract/` (temporal, fuera del modelo, no persiste entre sesiones). |
| D-SAFE-DIRECTORY | Agregar excepcion `safe.directory` para que `develop` pueda hacer fetch del repo en Clase B. | El repo en Clase B es propiedad de `svc-backups`; git rechaza el acceso por `dubious ownership`. La excepcion es el mecanismo correcto; no cambia permisos del filesystem. |

## Alcance cruzado con otros repos

No aplica. Esta iniciativa opera exclusivamente sobre
`template-ecommerce-server`. El tarball usado como fuente
proviene de un backup local; no se modifica ningun otro repo.

## Iniciativas relacionadas

- `crear-template-ecomerce-ui-server` (cerrada): produjo el
  historial que el backup preserva y que esta iniciativa
  reintegra.
- `corregir-paths-ecom-a-tui-server` (cerrada): iniciativa
  siguiente que corrigio nomenclatura en los docs operativos
  que los commits reintegrados habian actualizado.

<!-- Referencias Markdown -->
[doc-index]: index-integrar-commits-backup-20260522.md
[doc-alcance]: alcance-integrar-commits-backup-20260522.md
[doc-analisis]: analisis-integrar-commits-backup-20260522.md
[doc-plan]: plan-integrar-commits-backup-20260522.md
[doc-tareas]: tareas-integrar-commits-backup-20260522.md
[doc-progreso]: progreso-integrar-commits-backup-20260522.md
[repo-server]: https://github.com/jcg-admin/template-ecommerce-server
