# Iniciativa: Integrar commits faltantes desde backup 20260522

| Campo | Valor |
|-------|-------|
| Artefacto | INI-SRV-002 |
| Tipo | Mantenimiento retroactivo |
| Submodulo | server (template-ecommerce-server) |
| Estado | Cerrada |
| Version | 1.0.0 |
| Fecha de creacion | 2026-05-25 |
| Fecha de cierre | 2026-05-25 |
| Autor | NestorMonroy |
| Clasificacion | Interno |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 |

## Filosofia rectora

Usar la infraestructura de almacenamiento existente (Clase B,
remotos locales de git) en lugar de soluciones ad-hoc. No
reescribir historial: los commits faltantes se integran via
cherry-pick, preservando autor, fecha y mensaje originales.

Excepciones explicitas: ninguna. Esta iniciativa no modifica
el historial existente ni altera archivos de codigo.

## Que produce esta iniciativa

| Entregable | Estado al cierre |
|------------|------------------|
| `c481ca0` cherry-pick de `10abbf9` | Producido — README actualizado |
| `ae77a46` cherry-pick de `fd5fda8` | Producido — Renombre en 28 archivos |
| Tarball en Clase B | Producido — referencia historica preservada |

## Indice de documentos

| Documento | Proposito |
|-----------|-----------|
| [index-integrar-commits-backup-20260522.md](index-integrar-commits-backup-20260522.md) | Este archivo. Metadata, filosofia, entregables, decisiones. |
| [alcance-integrar-commits-backup-20260522.md](alcance-integrar-commits-backup-20260522.md) | Que cubre, criterio de completitud, fuera de alcance, estimacion. |
| [analisis-integrar-commits-backup-20260522.md](analisis-integrar-commits-backup-20260522.md) | Inventario del backup, comparacion de historiales, estrategia. |
| [plan-integrar-commits-backup-20260522.md](plan-integrar-commits-backup-20260522.md) | DAG de fases, tareas por fase con esfuerzo. |
| [tareas-integrar-commits-backup-20260522.md](tareas-integrar-commits-backup-20260522.md) | Lista plana de tareas con estado y entregable. |
| [progreso-integrar-commits-backup-20260522.md](progreso-integrar-commits-backup-20260522.md) | Bitacora cronologica de eventos atomizados. |
| [decisiones-integrar-commits-backup-20260522.md](decisiones-integrar-commits-backup-20260522.md) | Decisiones de diseno, hallazgos y verificacion post-ejecucion. |

## Decisiones aprobadas

| ID | Decision | Contenido |
|----|----------|-----------|
| D-REMOTO-LOCAL | Usar el repo extraido en Clase B como remoto local para el cherry-pick. | Preserva metadatos originales del commit (autor, fecha, mensaje). Alternativa descartada: aplicar cambios con sed (perderia los metadatos originales). |
| D-CLASE-B | Extraer el tarball en `/srv/backups/project/template-ecommerce-server/` (Clase B). | Sigue el modelo de almacenamiento del proyecto. Alternativa descartada: `/tmp/backup-extract/` (temporal, fuera del modelo, no persiste). |
| D-SAFE-DIRECTORY | Agregar excepcion `safe.directory` para que `develop` acceda al repo en Clase B. | El repo en Clase B es propiedad de `svc-backups`; git rechaza el acceso por `dubious ownership`. La excepcion es el mecanismo correcto sin cambiar permisos del filesystem. |

## Alcance cruzado con otros repos

No aplica. Esta iniciativa opera exclusivamente sobre
`template-ecommerce-server`. No modifica ningun otro repo.

## Iniciativas relacionadas

- INI-SRV-001 `crear-template-ecomerce-ui-server` (cerrada): produjo
  el historial que el backup preserva y que esta iniciativa reintegra.
- INI-SRV-003 `corregir-paths-ecom-a-tui-server` (cerrada):
  iniciativa siguiente que corrigio nomenclatura en los docs
  operativos que los commits reintegrados habian actualizado.
