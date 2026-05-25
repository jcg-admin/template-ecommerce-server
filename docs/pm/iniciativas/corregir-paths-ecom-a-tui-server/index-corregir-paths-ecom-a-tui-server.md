# Iniciativa: `corregir-paths-ecom-a-tui-server`

| Campo | Valor |
|-------|-------|
| Slug | `corregir-paths-ecom-a-tui-server` |
| Estado | Cerrada |
| Fecha de apertura | 2026-05-25 |
| Autor / responsable | Nestor Monroy |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 |
| Repositorio | [`template-ecommerce-server`][repo-server] |
| Tipo | Correccion de nomenclatura y rutas |

## Que hace esta iniciativa

Los documentos operativos del repo contienen rutas y nombres
desactualizados heredados del proceso de creacion inicial:

- Rutas `/srv/repos/ecom/` deben ser `/srv/repos/tui/` para
  coincidir con el punto de montaje real del WSL2
  (`ubuntu-template-ui-e-commerce`) definido en el
  procedimiento de almacenamiento.
- Nombre viejo del server `template-ecomerce-ui-server` en
  comentarios de `.env.example`.
- Nombre viejo del UI `template-e-comerce-ui` en
  `.env.example`.
- Links rotos apuntando a
  `docs/pm/iniciativas/crear-template-ecommerce-server/`
  (directorio inexistente; el real es
  `crear-template-ecomerce-ui-server`).

## Entregables

| Entregable | Descripcion |
|------------|-------------|
| `.env.example` corregido | Nomenclatura y rutas actualizadas |
| `README.md` corregido | Rutas y links reparados |
| `docs/` operativos corregidos | 5 archivos con rutas `tui` |
| `docs/desarrollo/` corregido | 2 archivos con links reparados |

## Documentos de la iniciativa

| Documento | Estado |
|-----------|--------|
| [index][doc-index] | Este archivo |
| [alcance][doc-alcance] | Completado |
| [analisis][doc-analisis] | Completado |
| [plan][doc-plan] | Completado |
| [tareas][doc-tareas] | Completado |
| [progreso][doc-progreso] | Activo |

## Decisiones aprobadas

| ID | Descripcion |
|----|-------------|
| D-PATHS-TUI | Reemplazar `/srv/repos/ecom/` por `/srv/repos/tui/` en todos los archivos operativos. El punto de montaje canonico del WSL2 es `tui`, definido en el procedimiento de almacenamiento v1.1.0. |
| D-REFERENTES-PRESERVADOS | No modificar: `jcg-admin/e-comerce-server` (repo externo real), `Procedimiento-Implementacion-Almacenamiento-WSL2-ecomerce-p001 v1.0.0` (nombre de procedimiento externo). Ambos tienen nombres con `ecom` que son correctos. |
| D-PM-HISTORICO | No modificar los docs PM de la iniciativa cerrada `crear-template-ecomerce-ui-server/`. Son historico inmutable per D-COMMITS-HISTORIA. |
| D-LINKS-INICIATIVA | Los links `crear-template-ecommerce-server` en `README.md`, `decision-modelo-cuentas.md` y `decision-nginx-vs-apache.md` apuntan a un directorio inexistente. Corregir a `crear-template-ecomerce-ui-server`. |

<!-- Referencias Markdown -->
[doc-index]: index-corregir-paths-ecom-a-tui-server.md
[doc-alcance]: alcance-corregir-paths-ecom-a-tui-server.md
[doc-analisis]: analisis-corregir-paths-ecom-a-tui-server.md
[doc-plan]: plan-corregir-paths-ecom-a-tui-server.md
[doc-tareas]: tareas-corregir-paths-ecom-a-tui-server.md
[doc-progreso]: progreso-corregir-paths-ecom-a-tui-server.md
[repo-server]: https://github.com/jcg-admin/template-ecommerce-server
