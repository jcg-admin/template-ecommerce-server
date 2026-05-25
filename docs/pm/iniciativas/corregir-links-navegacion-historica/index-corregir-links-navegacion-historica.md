# Iniciativa: `corregir-links-navegacion-historica`

| Campo | Valor |
|-------|-------|
| Slug | `corregir-links-navegacion-historica` |
| Estado | Cerrada |
| Fecha de apertura | 2026-05-25 |
| Autor / responsable | Nestor Monroy |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 |
| Repositorio | [`template-ecommerce-server`][repo-server] |
| Tipo | Correccion de links de navegacion rotos |

## Que hace esta iniciativa

Los documentos PM de la iniciativa cerrada
`crear-template-ecomerce-ui-server` tienen links de
navegacion internos que apuntan a nombres de archivo
incorrectos. Los archivos referenciados no existen;
los archivos reales tienen el sufijo `-ui-server` en
el nombre.

Auditoria con script Python detecto 10 ocurrencias
rotas en 3 archivos. Patron unico:

```
crear-template-ecommerce-server.md
  -> crear-template-ecomerce-ui-server.md
```

El sufijo `.md` en el patron protege texto visible
(titulos, slugs) que contienen el nombre sin extension.
Solo se corrigen los nombres de archivo en ref-defs
y texto de tabla.

## Entregables

| Entregable | Descripcion |
|------------|-------------|
| `index.md` corregido | 8 links de navegacion reparados |
| `alcance-*.md` corregido | 1 ref-def reparada |
| `plan-*.md` corregido | 1 ref-def reparada |

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
| D-LINKS-BYPASS | Override explicito de D-PM-HISTORICO para links de navegacion rotos. D-PM-HISTORICO protege el contenido historico de las bitacoras; no aplica a links de navegacion que impiden usar el documento. Los archivos `progreso-*.md` y el contenido de texto de todos los docs permanecen intactos. Solo se corrigen los nombres de archivo en ref-defs y texto de tabla que apuntan a archivos inexistentes. |
| D-PATRON-EXACTO | El sed usa el patron `crear-template-ecommerce-server\.md` (con `.md` como sufijo obligatorio) para evitar tocar titulos, slugs y texto visible que contienen el nombre de la iniciativa sin extension. |
| D-PROGRESO-INTACTO | El archivo `progreso-crear-template-ecomerce-ui-server.md` no tiene links rotos y no se toca en ninguna fase. |

<!-- Referencias Markdown -->
[doc-index]: index-corregir-links-navegacion-historica.md
[doc-alcance]: alcance-corregir-links-navegacion-historica.md
[doc-analisis]: analisis-corregir-links-navegacion-historica.md
[doc-plan]: plan-corregir-links-navegacion-historica.md
[doc-tareas]: tareas-corregir-links-navegacion-historica.md
[doc-progreso]: progreso-corregir-links-navegacion-historica.md
[repo-server]: https://github.com/jcg-admin/template-ecommerce-server
