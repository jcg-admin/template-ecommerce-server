# Iniciativa: Corregir links de navegacion rotos en iniciativa historica

| Campo | Valor |
|-------|-------|
| Artefacto | INI-SRV-004 |
| Tipo | Correccion de links de navegacion rotos |
| Submodulo | server (template-ecommerce-server) |
| Estado | Cerrada |
| Version | 1.0.0 |
| Fecha de creacion | 2026-05-25 |
| Fecha de cierre | 2026-05-25 |
| Autor | NestorMonroy |
| Clasificacion | Interno |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 |

## Filosofia rectora

Corregir exclusivamente los links de navegacion rotos sin tocar
el contenido historico de ningun documento. El principio
D-PM-HISTORICO protege el contenido; los links de navegacion
que impiden usar el documento son bugs funcionales, no historia.

Excepciones explicitas:

- D-LINKS-BYPASS: override de D-PM-HISTORICO para links de
  navegacion rotos unicamente. El texto visible, los titulos,
  los slugs y `progreso-*.md` permanecen intactos.
- El patron sed incluye `.md` como sufijo obligatorio para no
  afectar texto visible que menciona el nombre sin extension.

## Que produce esta iniciativa

| Entregable | Estado al cierre |
|------------|------------------|
| `index.md` de iniciativa historica corregido | Producido — 8 links de navegacion reparados |
| `alcance-crear-template-ecomerce-ui-server.md` corregido | Producido — 1 ref-def reparada |
| `plan-crear-template-ecomerce-ui-server.md` corregido | Producido — 1 ref-def reparada |

## Indice de documentos

| Documento | Proposito |
|-----------|-----------|
| [index-corregir-links-navegacion-historica.md](index-corregir-links-navegacion-historica.md) | Este archivo. Metadata, filosofia, entregables, decisiones. |
| [alcance-corregir-links-navegacion-historica.md](alcance-corregir-links-navegacion-historica.md) | Que cubre, criterio de completitud, fuera de alcance, estimacion. |
| [analisis-corregir-links-navegacion-historica.md](analisis-corregir-links-navegacion-historica.md) | Inventario exacto de links rotos, patron sed, validacion. |
| [plan-corregir-links-navegacion-historica.md](plan-corregir-links-navegacion-historica.md) | DAG de fases, tareas por fase con esfuerzo. |
| [tareas-corregir-links-navegacion-historica.md](tareas-corregir-links-navegacion-historica.md) | Lista plana de tareas con estado y entregable. |
| [progreso-corregir-links-navegacion-historica.md](progreso-corregir-links-navegacion-historica.md) | Bitacora cronologica de eventos atomizados. |
| [decisiones-corregir-links-navegacion-historica.md](decisiones-corregir-links-navegacion-historica.md) | Decisiones de diseno, hallazgos y verificacion post-ejecucion. |

## Decisiones aprobadas

| ID | Decision | Contenido |
|----|----------|-----------|
| D-LINKS-BYPASS | Override de D-PM-HISTORICO para links de navegacion rotos. | D-PM-HISTORICO protege el contenido historico, no los links que impiden la navegacion. Los links rotos son bugs funcionales. Los archivos `progreso-*.md` y el texto visible permanecen intactos. |
| D-PATRON-EXACTO | Patron sed con sufijo `.md` obligatorio: `crear-template-ecommerce-server\.md`. | Protege titulos, slugs y texto visible que contienen el nombre de la iniciativa sin extension. Sin el sufijo el sed modificaria texto que debe permanecer intacto. |
| D-PROGRESO-INTACTO | `progreso-crear-template-ecomerce-ui-server.md` no se toca. | No tiene links rotos. Es bitacora historica. No hay razon tecnica ni funcional para modificarlo. |

## Alcance cruzado con otros repos

No aplica. Esta iniciativa opera exclusivamente sobre
documentos PM del repo `template-ecommerce-server`.

## Iniciativas relacionadas

- INI-SRV-003 `corregir-paths-ecom-a-tui-server` (cerrada):
  iniciativa previa que corrigio rutas y nomenclatura. Esta
  iniciativa completa la correccion en los docs PM historicos.
- INI-SRV-001 `crear-template-ecomerce-ui-server` (cerrada):
  la iniciativa cuyos docs PM se corrigen en esta iniciativa.
