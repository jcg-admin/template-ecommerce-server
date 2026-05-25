# Alcance — `corregir-paths-ecom-a-tui-server`

## Que cubre

| Categoria | Detalle |
|-----------|---------|
| P1 nomenclatura server | `template-ecomerce-ui-server` → `template-ecommerce-server` en `.env.example` |
| P2 nomenclatura UI | `template-e-comerce-ui` → `template-ecommerce-ui` en `.env.example` |
| P3 rutas ecom → tui | `/srv/repos/ecom/` → `/srv/repos/tui/` en 7 archivos operativos |
| P4 links rotos | `crear-template-ecommerce-server` → `crear-template-ecomerce-ui-server` en 3 archivos |

## Criterio de completitud

- `grep -r "template-ecomerce-ui-server"` en archivos operativos: 0 resultados.
- `grep -r "template-e-comerce-ui"` en archivos operativos: 0 resultados.
- `grep -r "/srv/repos/ecom/"` en archivos operativos: 0 resultados.
- `grep -r "crear-template-ecommerce-server"` en archivos operativos: 0 resultados.
- Referentes externos preservados: `jcg-admin/e-comerce-server` intacto.
- Procedimiento externo preservado: `ecomerce-p001` intacto.
- Working tree limpio antes de cada commit de fase.

## Fuera de alcance

| Item | Razon |
|------|-------|
| PM docs de `crear-template-ecomerce-ui-server/` | Historico inmutable per D-COMMITS-HISTORIA y D-PM-HISTORICO |
| PM docs de `integrar-commits-backup-20260522/` | Referencias al nombre viejo son contexto historico, no errores |
| `progreso-*.md` de iniciativas cerradas | Bitacoras inmutables |
| Rutas en scripts `.sh` | Los scripts no tienen rutas hardcoded; usan variables de `.env` |
| Referentes externos | `jcg-admin/e-comerce-server` y `ecomerce-p001` son nombres reales preservados |

## Estimacion de esfuerzo por fase

| Fase | Estimado |
|------|----------|
| F0 — Analisis + PM docs | 20 min |
| F1 — Fix `.env.example` | 5 min |
| F2 — Fix `README.md` | 5 min |
| F3 — Fix `docs/` operativos | 10 min |
| F4 — Fix `docs/desarrollo/` links | 5 min |
| F5 — Verificacion | 5 min |
| F6 — Cierre | 5 min |
| Total | 55 min |
