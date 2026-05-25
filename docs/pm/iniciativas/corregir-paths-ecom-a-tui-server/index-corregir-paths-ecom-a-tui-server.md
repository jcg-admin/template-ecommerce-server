# Iniciativa: Corregir rutas ecom a tui y nomenclatura en docs

| Campo | Valor |
|-------|-------|
| Artefacto | INI-SRV-003 |
| Tipo | Correccion de nomenclatura y rutas |
| Submodulo | server (template-ecommerce-server) |
| Estado | Cerrada |
| Version | 1.0.0 |
| Fecha de creacion | 2026-05-25 |
| Fecha de cierre | 2026-05-25 |
| Autor | NestorMonroy |
| Clasificacion | Interno |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 |

## Filosofia rectora

Aplicar sed batches con patrones exactos y verificados.
Preservar sin excepcion los referentes externos (repos reales en
GitHub con nombres especificos) y los documentos PM de iniciativas
cerradas.

Excepciones explicitas:

- `jcg-admin/e-comerce-server`: repo externo real, nombre
  correcto, no se toca aunque contenga `ecom`.
- `Procedimiento-Implementacion-Almacenamiento-WSL2-ecomerce-p001`:
  nombre de procedimiento externo, no se toca.
- `progreso-*.md` de iniciativas cerradas: bitacoras
  inmutables per D-COMMITS-HISTORIA.

## Que produce esta iniciativa

| Entregable | Estado al cierre |
|------------|------------------|
| `.env.example` corregido | Producido — nomenclatura P1+P2 y rutas P3 actualizadas |
| `README.md` corregido | Producido — rutas P3 y links P4 reparados |
| `docs/` operativos corregidos | Producido — 5 archivos con rutas `/srv/repos/tui/` |
| `docs/desarrollo/` corregido | Producido — 2 archivos con links a iniciativa correctos |

## Indice de documentos

| Documento | Proposito |
|-----------|-----------|
| [index-corregir-paths-ecom-a-tui-server.md](index-corregir-paths-ecom-a-tui-server.md) | Este archivo. Metadata, filosofia, entregables, decisiones. |
| [alcance-corregir-paths-ecom-a-tui-server.md](alcance-corregir-paths-ecom-a-tui-server.md) | Que cubre, criterio de completitud, fuera de alcance, estimacion. |
| [analisis-corregir-paths-ecom-a-tui-server.md](analisis-corregir-paths-ecom-a-tui-server.md) | Inventario de los 4 patrones, validacion de no-colisiones, estrategia. |
| [plan-corregir-paths-ecom-a-tui-server.md](plan-corregir-paths-ecom-a-tui-server.md) | DAG de fases, tareas por fase con esfuerzo. |
| [tareas-corregir-paths-ecom-a-tui-server.md](tareas-corregir-paths-ecom-a-tui-server.md) | Lista plana de tareas con estado y entregable. |
| [progreso-corregir-paths-ecom-a-tui-server.md](progreso-corregir-paths-ecom-a-tui-server.md) | Bitacora cronologica de eventos atomizados. |
| [decisiones-corregir-paths-ecom-a-tui-server.md](decisiones-corregir-paths-ecom-a-tui-server.md) | Decisiones de diseno, hallazgos y verificacion post-ejecucion. |

## Decisiones aprobadas

| ID | Decision | Contenido |
|----|----------|-----------|
| D-PATHS-TUI | Reemplazar `/srv/repos/ecom/` por `/srv/repos/tui/` en todos los archivos operativos. | El punto de montaje canonico del WSL2 es `tui`, definido en el procedimiento de almacenamiento v1.1.0. El path `ecom` era un supuesto del referente que nunca correspondio al entorno real. |
| D-REFERENTES-PRESERVADOS | No modificar `jcg-admin/e-comerce-server` ni `ecomerce-p001`. | Son nombres de entidades externas reales. Cambiarlos romperia la correspondencia con los objetos reales que referencian. |
| D-PM-HISTORICO | No modificar los docs PM de `crear-template-ecomerce-ui-server/`. | Son historico inmutable per D-COMMITS-HISTORIA. Modificarlos retroactivamente falsificaria la bitacora de la iniciativa. |
| D-LINKS-INICIATIVA | Corregir links `crear-template-ecommerce-server` a `crear-template-ecomerce-ui-server` en docs operativos. | El directorio `crear-template-ecommerce-server/` no existe. Los links apuntaban a un path inexistente. |

## Alcance cruzado con otros repos

No aplica. Esta iniciativa opera exclusivamente sobre archivos
del repo `template-ecommerce-server`. No modifica el repo
`template-ecommerce-ui`.

## Iniciativas relacionadas

- INI-SRV-002 `integrar-commits-backup-20260522` (cerrada):
  reintegro los commits que contienen el renombre que esta
  iniciativa complementa con las rutas.
- INI-SRV-004 `corregir-links-navegacion-historica` (cerrada):
  iniciativa siguiente que corrigio links internos en los docs
  PM de la iniciativa historica.
