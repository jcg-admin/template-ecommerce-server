# Alcance — `corregir-links-navegacion-historica`

## Que cubre

| Categoria | Detalle |
|-----------|---------|
| Links de navegacion rotos | 10 ocurrencias en 3 archivos dentro de `crear-template-ecomerce-ui-server/` |
| Patron unico | `crear-template-ecommerce-server.md` → `crear-template-ecomerce-ui-server.md` |

## Archivos en scope

| Archivo | Ocurrencias | Tipo de link |
|---------|-------------|--------------|
| `docs/pm/iniciativas/crear-template-ecomerce-ui-server/index.md` | 8 | Texto de tabla + ref-defs |
| `docs/pm/iniciativas/crear-template-ecomerce-ui-server/alcance-crear-template-ecomerce-ui-server.md` | 1 | ref-def |
| `docs/pm/iniciativas/crear-template-ecomerce-ui-server/plan-crear-template-ecomerce-ui-server.md` | 1 | ref-def |

## Criterio de completitud

- Script de auditoria Python retorna 0 links rotos en
  `crear-template-ecomerce-ui-server/` (excluye
  `progreso-*.md` que no tiene links rotos).
- Texto visible de titulos y slugs sin modificar:
  `grep "crear-template-ecommerce-server[^.]"` retorna
  los mismos resultados que antes de la ejecucion.
- `progreso-crear-template-ecomerce-ui-server.md`
  sin modificaciones (verificado con `git diff`).

## Fuera de alcance

| Item | Razon |
|------|-------|
| `progreso-crear-template-ecomerce-ui-server.md` | Sin links rotos. No se toca per D-PROGRESO-INTACTO. |
| `tareas-crear-template-ecomerce-ui-server.md` | Sin links rotos. Solo tiene titulo con nombre viejo que es texto visible, no un link. |
| Titulos y slugs con el nombre de la iniciativa | Texto historico inmutable. El patron incluye `.md` como sufijo para no tocarlos. |
| Otras iniciativas PM | Sin links rotos confirmado por auditoria. |

## Estimacion de esfuerzo por fase

| Fase | Estimado |
|------|----------|
| F0 — Analisis + PM docs | 20 min |
| F1 — Aplicar correccion en 3 archivos | 5 min |
| F2 — Verificacion con script auditoria | 5 min |
| F3 — Cierre | 5 min |
| Total | 35 min |
