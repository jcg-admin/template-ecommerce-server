# Tareas — `corregir-links-navegacion-historica`

| ID | Descripcion | Estimado | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-001 | Auditoria con script Python: identificar todos los links rotos | 10 min | CERRADA | 10 ocurrencias rotas en 3 archivos identificadas |
| T-002 | Verificar existencia de archivos destino correctos | 3 min | CERRADA | Los 5 archivos reales existen en `crear-template-ecomerce-ui-server/` |
| T-003 | Verificar inexistencia de archivos apuntados por links rotos | 2 min | CERRADA | Los 4 archivos con nombre incorrecto NO existen |
| T-004 | Definir patron sed y validar no-colision con texto visible | 5 min | CERRADA | Patron `crear-template-ecommerce-server\.md` validado |
| T-005 | Crear 6 documentos PM de la iniciativa | 20 min | CERRADA | 6 archivos en `corregir-links-navegacion-historica/` |
| T-101 | Aplicar sed en `index.md` | 1 min | CERRADA | `index.md` con 8 links corregidos |
| T-102 | Aplicar sed en `alcance-crear-template-ecomerce-ui-server.md` | 1 min | CERRADA | `alcance-*.md` con 1 ref-def corregida |
| T-103 | Aplicar sed en `plan-crear-template-ecomerce-ui-server.md` | 1 min | CERRADA | `plan-*.md` con 1 ref-def corregida |
| T-104 | Verificar que `progreso-*.md` y `tareas-*.md` no fueron modificados | 2 min | CERRADA | `git diff` muestra 0 cambios en esos archivos |
| T-105 | Verificar que titulos y slugs siguen intactos | 1 min | CERRADA | grep del patron sin `.md` retorna los mismos resultados |
| T-106 | Commit F1 | 1 min | CERRADA | Commit en `main` con subject Tim Pope <=50 |
| T-201 | Ejecutar script Python de auditoria completo | 3 min | CERRADA | Script ejecutado sin errores |
| T-202 | Confirmar 0 links rotos en `crear-template-ecomerce-ui-server/` | 2 min | CERRADA | Script retorna 0 rotos en el directorio historico |
| T-301 | Actualizar progreso con eventos de cierre | 2 min | CERRADA | Bitacora completa con todos los eventos |
| T-302 | Actualizar index con Estado=Cerrada | 1 min | CERRADA | index con Estado=Cerrada y fecha de cierre |
| T-303 | Actualizar tareas con estados CERRADA | 1 min | CERRADA | Todas las tareas en CERRADA |
| T-304 | Commit de cierre F3 | 1 min | CERRADA | Commit final de la iniciativa |

## Resumen por fase

| Fase | Tareas | Estado |
|------|--------|--------|
| F0 — Analisis + PM docs | T-001..T-005 | CERRADA |
| F1 — Aplicar correccion | T-101..T-106 | CERRADA |
| F2 — Verificacion | T-201..T-202 | CERRADA |
| F3 — Cierre | T-301..T-304 | CERRADA |
