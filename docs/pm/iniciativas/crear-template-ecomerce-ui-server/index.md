# Iniciativa: `crear-template-ecommerce-server`

| Campo | Valor |
|-------|-------|
| Slug | `crear-template-ecommerce-server` |
| Estado | En ejecucion |
| Orden de backlog | (no aplica: abierta directamente sin pasar por backlog) |
| Fecha de creacion (directorio) | 2026-05-21 |
| Fecha de apertura formal | 2026-05-21 |
| Autor / responsable | Nestor Monroy |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 + arc42 |
| Repositorio | [`template-ecommerce-server`][repo-server] (recien creado, commit inicial pendiente) |
| Iniciativa origen / inspiracion | [`jcg-admin/e-comerce-server`][ref-ecomerce-server] (clonado en `/tmp/references/e-comerce-server/`) |
| Iniciativa hermana | `mapear-y-corregir-scss-completo` (en [`template-ecommerce-ui`][repo-ui], pausada para priorizar esta) |

## Que hace esta iniciativa

Crear desde cero un proyecto de infraestructura inspirado en
[`jcg-admin/e-comerce-server`][ref-ecomerce-server] pero
**adaptado al contexto del template UI**: sin asumir tecnologia
backend, usando Nginx en lugar de Apache, modelo de cuentas
simplificado a 4 (sin `svc-dbdata`), clases de almacenamiento
simplificadas a A y B (sin C).

El resultado sera un repositorio de scripts de
aprovisionamiento que, ejecutados en un Ubuntu 24.04 (VPS o
WSL2), dejen el servidor listo para servir el build de
produccion del [`template-ecommerce-ui`][repo-ui] con SSL,
fail2ban, SSH hardening, UFW, y reverse-proxy configurable
hacia una API externa cuyo binding tecnico no es problema de
este repo.

## Documentos de la iniciativa

| Documento | Estado |
|-----------|--------|
| [index.md][doc-index] | Este archivo |
| [alcance-crear-template-ecomerce-ui-server.md][doc-alcance] | Completado |
| [plan-crear-template-ecomerce-ui-server.md][doc-plan] | Completado |
| [tareas-crear-template-ecomerce-ui-server.md][doc-tareas] | Completado |
| [progreso-crear-template-ecomerce-ui-server.md][doc-progreso] | Activo (bitacora cronologica) |

## Referencias externas

- Repo de referencia: [`jcg-admin/e-comerce-server`][ref-ecomerce-server]
  (clonado en `/tmp/references/e-comerce-server/`).
- Analisis previo que motivo esta iniciativa:
  [analisis-servidor-para-template.md][analisis-ui] (en el repo
  UI, commit `7110527`).
- Procedimiento externo de almacenamiento:
  `Procedimiento-Implementacion-Almacenamiento-WSL2-ecomerce-p001 v1.0.0`.
- Documentacion tecnica del repo: [arquitectura][doc-arquitectura],
  [seguridad][doc-seguridad], [glosario][doc-glosario],
  [desarrollo/][doc-desarrollo].

<!-- Referencias Markdown -->
[doc-index]: index.md
[doc-alcance]: alcance-crear-template-ecomerce-ui-server.md
[doc-plan]: plan-crear-template-ecomerce-ui-server.md
[doc-tareas]: tareas-crear-template-ecomerce-ui-server.md
[doc-progreso]: progreso-crear-template-ecomerce-ui-server.md
[doc-arquitectura]: ../../../arquitectura.md
[doc-seguridad]: ../../../seguridad.md
[doc-glosario]: ../../../glosario.md
[doc-desarrollo]: ../../../desarrollo/index.md
[repo-server]: https://github.com/jcg-admin/template-ecommerce-server
[repo-ui]: https://github.com/jcg-admin/template-ecommerce-ui
[ref-ecomerce-server]: https://github.com/jcg-admin/e-comerce-server
[analisis-ui]: https://github.com/jcg-admin/template-ecommerce-ui/blob/main/docs/desarrollo/analisis-servidor-para-template.md
