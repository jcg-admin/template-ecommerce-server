# Indice de iniciativas — `template-ecommerce-server`

Registro centralizado de todas las iniciativas del repo,
requerido por PROC-GESTION-001 v4.0.0 NORMA 5. Se actualiza
al cerrar cada iniciativa.

| Artefacto | Tipo | Estado | Apertura | Cierre | Autor |
|-----------|------|--------|----------|--------|-------|
| [`crear-template-ecomerce-ui-server`][i-crear] | Desarrollo | Cerrada | 2026-05-21 | 2026-05-22 | Nestor Monroy |
| [`integrar-commits-backup-20260522`][i-integrar] | Mantenimiento retroactivo | Cerrada | 2026-05-25 | 2026-05-25 | Nestor Monroy |
| [`corregir-paths-ecom-a-tui-server`][i-paths] | Correccion nomenclatura y rutas | Cerrada | 2026-05-25 | 2026-05-25 | Nestor Monroy |
| [`corregir-links-navegacion-historica`][i-links] | Correccion links rotos | Cerrada | 2026-05-25 | 2026-05-25 | Nestor Monroy |
| [`crear-setup-sh`][i-setup] | Desarrollo | Cerrada | 2026-05-25 | 2026-05-25 | Nestor Monroy |
| [`crear-start-sh`][i-start] | Desarrollo | Cerrada | 2026-05-25 | 2026-05-25 | Nestor Monroy |

## Descripcion resumida por iniciativa

### `crear-template-ecomerce-ui-server`

Creo desde cero el repo `template-ecommerce-server`: 8
provisioners bash, utils, configs Nginx, SSL, fail2ban, UFW,
SSH hardening, tests (72 PASS / 0 FAIL / 1 SKIP) y
documentacion completa. 12 fases, 31 tareas, 30 commits.

### `integrar-commits-backup-20260522`

Reintegro 2 commits presentes en el backup
`20260522-050927` pero ausentes en el historial activo via
cherry-pick desde remoto local en Clase B. Corrijo
nomenclatura desincronizada en 28 archivos.

### `corregir-paths-ecom-a-tui-server`

Corrigio 4 patrones de nomenclatura y rutas desactualizadas
en 9 archivos operativos: rutas `/srv/repos/ecom/` a `tui/`,
nombre viejo del server y del UI en `.env.example`, y links
rotos a directorio de iniciativa inexistente.

### `corregir-links-navegacion-historica`

Corrigio 10 links de navegacion rotos en 3 documentos PM de
la iniciativa historica `crear-template-ecomerce-ui-server`.
Aplicando D-LINKS-BYPASS: override de D-PM-HISTORICO para
bugs funcionales de navegacion.

### `crear-setup-sh`

Crea `scripts/setup.sh`, punto de entrada unico para
aprovisionar el servidor. Resuelve el problema del lockout
SSH mediante dos fases con flag `--continue`. 4 flags:
`--continue`, `--skip-ssh`, `--ssl-dev`, `--ssl-staging`.

### `crear-start-sh`

Crea `scripts/start.sh` para arrancar Nginx y fail2ban en
entornos sin systemd (WSL2). Reutiliza `svc_is_active` y
`svc_start` de `utils/core.sh`. Idempotente.

<!-- Referencias Markdown -->
[i-crear]: iniciativas/crear-template-ecomerce-ui-server/index.md
[i-integrar]: iniciativas/integrar-commits-backup-20260522/index-integrar-commits-backup-20260522.md
[i-paths]: iniciativas/corregir-paths-ecom-a-tui-server/index-corregir-paths-ecom-a-tui-server.md
[i-links]: iniciativas/corregir-links-navegacion-historica/index-corregir-links-navegacion-historica.md
[i-setup]: iniciativas/crear-setup-sh/index-crear-setup-sh.md
[i-start]: iniciativas/crear-start-sh/index-crear-start-sh.md

<!-- indice actualizado al cerrar INI-SRV-005 y INI-SRV-006 -->
| [`auditar-gaps-server-y-ui`][i-audit] | Auditoria y correccion | En ejecucion | 2026-05-25 | — | Nestor Monroy |

### `auditar-gaps-server-y-ui`

Confronta el documento de analisis `analisis-servidor-para-template.md`
contra la implementacion real. 16/17 propuestas cumplen en el server.
Bug critico en el UI: `apiService.js` bypasea el proxy Nginx cuando
`API_URL` tiene el fallback `http://localhost:8000` hardcodeado.

[i-audit]: iniciativas/auditar-gaps-server-y-ui/index-auditar-gaps-server-y-ui.md
