# Tareas — `integrar-commits-backup-20260522`

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-001 | Verificar MD5 del tarball contra archivo `.md5` | 2 min | CERRADA | MD5 coincidente confirmado |
| T-002 | Listar contenido del tarball sin extraer | 2 min | CERRADA | Estructura interna confirmada |
| T-003 | Comparar historiales backup vs repo activo | 5 min | CERRADA | 2 commits faltantes identificados |
| T-004 | Identificar impacto de commits faltantes | 6 min | CERRADA | 28 archivos con nomenclatura vieja confirmados |
| T-101 | Copiar tarball a Clase B como `svc-backups` | 2 min | CERRADA | Tarball en `/srv/backups/project/template-ecommerce-server/` |
| T-102 | Extraer tarball en Clase B como `svc-backups` | 2 min | CERRADA | Directorio extraido disponible |
| T-103 | Verificar extraccion | 1 min | CERRADA | `ls` confirma tarball + directorio |
| T-201 | Agregar remoto `backup-local` apuntando a Clase B | 1 min | CERRADA | Remoto registrado |
| T-202 | Fetch del remoto `backup-local` | 1 min | CERRADA | 48 objetos recibidos |
| T-203 | Cherry-pick `10abbf9` | 1 min | CERRADA | `c481ca0` en historial local |
| T-204 | Cherry-pick `fd5fda8` | 1 min | CERRADA | `ae77a46` en historial local |
| T-301 | Verificar log y status post-cherry-pick | 2 min | CERRADA | 32 commits, working tree limpio |
| T-302 | grep de nomenclatura vieja en archivos operativos | 2 min | CERRADA | 0 apariciones en archivos operativos |
| T-303 | Push a origin | 1 min | CERRADA | `origin/main` = `ae77a46` |
| T-304 | Eliminar remoto `backup-local` | 1 min | CERRADA | Solo `origin` visible |

## Resumen por fase

| Fase | Tareas | Estado |
|------|--------|--------|
| F0 — Analisis | T-001..T-004 | CERRADA |
| F1 — Extraccion | T-101..T-103 | CERRADA |
| F2 — Integracion | T-201..T-204 | CERRADA |
| F3 — Verificacion | T-301..T-304 | CERRADA |
| Total | 15 tareas | TODAS CERRADAS |
