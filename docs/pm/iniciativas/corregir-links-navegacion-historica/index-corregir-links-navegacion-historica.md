# Iniciativa: `corregir-links-navegacion-historica`

| Campo | Valor |
|-------|-------|
| Artefacto | `corregir-links-navegacion-historica` |
| Tipo | Correccion de links de navegacion rotos |
| Estado | Cerrada |
| Version | 1.0.0 |
| Fecha de creacion | 2026-05-25 |
| Fecha de apertura formal | 2026-05-25 |
| Fecha de cierre | 2026-05-25 |
| Autor | Nestor Monroy |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 |
| Repositorio | [`template-ecommerce-server`][repo-server] |
| Orden de backlog | (no aplica: abierta directamente al detectar links de navegacion rotos via auditoria Python) |

## Que hace esta iniciativa

Los documentos PM de la iniciativa cerrada
`crear-template-ecomerce-ui-server` tienen links de
navegacion internos que apuntan a nombres de archivo
incorrectos. Los archivos referenciados no existen; los
archivos reales tienen el sufijo `-ui-server` en el nombre.

Auditoria con script Python detecto 10 ocurrencias rotas
en 3 archivos. Patron unico:
`crear-template-ecommerce-server.md`
→ `crear-template-ecomerce-ui-server.md`

El sufijo `.md` en el patron protege texto visible (titulos,
slugs) que contienen el nombre sin extension. Solo se
corrigen los nombres de archivo en ref-defs y texto de tabla.

## Filosofia rectora

Corregir exclusivamente los links de navegacion rotos sin
tocar el contenido historico de ningun documento. El
principio D-PM-HISTORICO protege el contenido; los links
de navegacion que impiden usar el documento son bugs, no
historia.

Excepciones explicitas:

- D-LINKS-BYPASS: override de D-PM-HISTORICO para links
  de navegacion rotos unicamente. El texto visible, los
  titulos, los slugs y `progreso-*.md` permanecen intactos.
- El patron sed incluye `.md` como sufijo obligatorio para
  no afectar texto visible que menciona el nombre de la
  iniciativa sin extension de archivo.

## Que produce

| Entregable | Descripcion |
|------------|-------------|
| `index.md` corregido | 8 links de navegacion reparados (4 en texto de tabla + 4 ref-defs) |
| `alcance-crear-template-ecomerce-ui-server.md` corregido | 1 ref-def reparada |
| `plan-crear-template-ecomerce-ui-server.md` corregido | 1 ref-def reparada |

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
| D-LINKS-BYPASS | Override explicito de D-PM-HISTORICO para links de navegacion rotos. | D-PM-HISTORICO protege el contenido historico de las bitacoras; no aplica a links de navegacion que impiden usar el documento. Los links rotos son bugs funcionales, no historia inmutable. |
| D-PATRON-EXACTO | El sed usa el patron `crear-template-ecommerce-server\.md` (con `.md` como sufijo obligatorio). | Protege titulos, slugs y texto visible que contienen el nombre de la iniciativa sin extension de archivo. Sin el sufijo `.md` el sed modificaria texto que debe permanecer intacto. |
| D-PROGRESO-INTACTO | `progreso-crear-template-ecomerce-ui-server.md` no se toca. | No tiene links rotos. Es bitacora historica. No hay razon tecnica ni funcional para modificarlo. |

## Alcance cruzado con otros repos

No aplica. Esta iniciativa opera exclusivamente sobre
documentos PM del repo `template-ecommerce-server`. No
modifica ni referencia el repo `template-ecommerce-ui`.

## Iniciativas relacionadas

- `corregir-paths-ecom-a-tui-server` (cerrada): iniciativa
  previa que corrigio rutas y nomenclatura en docs operativos.
  Esta iniciativa completa la correccion en los docs PM de
  la iniciativa historica.
- `crear-template-ecomerce-ui-server` (cerrada): la
  iniciativa cuyos docs PM se corrigen en esta iniciativa.

<!-- Referencias Markdown -->
[doc-index]: index-corregir-links-navegacion-historica.md
[doc-alcance]: alcance-corregir-links-navegacion-historica.md
[doc-analisis]: analisis-corregir-links-navegacion-historica.md
[doc-plan]: plan-corregir-links-navegacion-historica.md
[doc-tareas]: tareas-corregir-links-navegacion-historica.md
[doc-progreso]: progreso-corregir-links-navegacion-historica.md
[repo-server]: https://github.com/jcg-admin/template-ecommerce-server
