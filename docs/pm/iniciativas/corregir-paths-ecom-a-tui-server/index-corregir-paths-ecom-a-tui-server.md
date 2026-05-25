# Iniciativa: `corregir-paths-ecom-a-tui-server`

| Campo | Valor |
|-------|-------|
| Artefacto | `corregir-paths-ecom-a-tui-server` |
| Tipo | Correccion de nomenclatura y rutas |
| Estado | Cerrada |
| Version | 1.0.0 |
| Fecha de creacion | 2026-05-25 |
| Fecha de apertura formal | 2026-05-25 |
| Fecha de cierre | 2026-05-25 |
| Autor | Nestor Monroy |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 |
| Repositorio | [`template-ecommerce-server`][repo-server] |
| Orden de backlog | (no aplica: abierta directamente al detectar rutas y nomenclatura desactualizadas en docs operativos) |

## Que hace esta iniciativa

Los documentos operativos del repo contienen rutas y nombres
desactualizados heredados del proceso de creacion inicial:

- Rutas `/srv/repos/ecom/` en lugar de `/srv/repos/tui/`
  (punto de montaje real del WSL2).
- Nombre viejo del server `template-ecomerce-ui-server` en
  comentarios de `.env.example`.
- Nombre viejo del UI `template-e-comerce-ui` en
  `.env.example`.
- Links rotos apuntando a `crear-template-ecommerce-server/`
  (directorio inexistente; el real es
  `crear-template-ecomerce-ui-server`).

Esta iniciativa corrige los 4 patrones en todos los archivos
operativos preservando referentes externos y documentacion
historica inmutable.

## Filosofia rectora

Aplicar sed batches con patrones exactos y verificados.
Preservar sin excepcion los referentes externos (repos reales
en GitHub con nombres especificos) y los documentos PM de
iniciativas cerradas.

Excepciones explicitas:

- `jcg-admin/e-comerce-server`: repo externo real, nombre
  correcto, no se toca aunque contenga `ecom`.
- `Procedimiento-Implementacion-Almacenamiento-WSL2-ecomerce-p001`:
  nombre de procedimiento externo, no se toca.
- `progreso-*.md` de iniciativas cerradas: bitacoras
  inmutables per D-COMMITS-HISTORIA.

## Que produce

| Entregable | Descripcion |
|------------|-------------|
| `.env.example` corregido | Nomenclatura P1 + P2 + rutas P3 actualizadas |
| `README.md` corregido | Rutas P3 + links rotos P4 reparados |
| `docs/` operativos corregidos | 5 archivos con rutas `/srv/repos/tui/` |
| `docs/desarrollo/` corregido | 2 archivos con links a iniciativa correctos |

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
| D-PATHS-TUI | Reemplazar `/srv/repos/ecom/` por `/srv/repos/tui/` en todos los archivos operativos. | El punto de montaje canonico del WSL2 es `tui`, definido en el procedimiento de almacenamiento v1.1.0. El path `ecom` era un supuesto del referente que nunca correspondio al entorno real. |
| D-REFERENTES-PRESERVADOS | No modificar `jcg-admin/e-comerce-server` ni `ecomerce-p001`. | Son nombres de entidades externas reales. Cambiarlos en los docs romperia la correspondencia con los objetos reales que referencian. |
| D-PM-HISTORICO | No modificar los docs PM de `crear-template-ecomerce-ui-server/`. | Son historico inmutable per D-COMMITS-HISTORIA. Modificarlos retroactivamente falsificaria la bitacora de la iniciativa. |
| D-LINKS-INICIATIVA | Corregir links `crear-template-ecommerce-server` a `crear-template-ecomerce-ui-server` en docs operativos. | El directorio `crear-template-ecommerce-server/` no existe. Los links apuntaban a un path inexistente desde el inicio. |

## Alcance cruzado con otros repos

No aplica. Esta iniciativa opera exclusivamente sobre archivos
del repo `template-ecommerce-server`. No modifica ni referencia
el repo `template-ecommerce-ui`.

## Iniciativas relacionadas

- `integrar-commits-backup-20260522` (cerrada): reintegro los
  commits `fd5fda8` y `10abbf9` que contienen el renombre de
  nomenclatura que esta iniciativa complementa con las rutas.
- `corregir-links-navegacion-historica` (cerrada): iniciativa
  siguiente que corrigio links internos en los docs PM de la
  iniciativa historica.

<!-- Referencias Markdown -->
[doc-index]: index-corregir-paths-ecom-a-tui-server.md
[doc-alcance]: alcance-corregir-paths-ecom-a-tui-server.md
[doc-analisis]: analisis-corregir-paths-ecom-a-tui-server.md
[doc-plan]: plan-corregir-paths-ecom-a-tui-server.md
[doc-tareas]: tareas-corregir-paths-ecom-a-tui-server.md
[doc-progreso]: progreso-corregir-paths-ecom-a-tui-server.md
[repo-server]: https://github.com/jcg-admin/template-ecommerce-server
