# Iniciativa: Auditar y corregir gaps entre analisis y la implementacion

| Campo | Valor |
|-------|-------|
| Artefacto | INI-SRV-007 |
| Tipo | Auditoria y correccion |
| Submodulo | server (template-ecommerce-server) + ui (template-ecommerce-ui) |
| Estado | Cerrada |
| Version | 1.0.0 |
| Fecha de creacion | 2026-05-25 |
| Fecha de cierre | 2026-05-25 |
| Autor | NestorMonroy |
| Clasificacion | Interno |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 |

## Filosofia rectora

Confrontar el documento de analisis
`template-ecommerce-ui/docs/desarrollo/analisis-servidor-para-template.md`
contra la implementacion real de `template-ecommerce-server`, y
detectar en `template-ecommerce-ui` cualquier incompatibilidad
arquitectonica con el modelo de despliegue propuesto.

Solo se corrigen gaps que tienen impacto real en produccion. Las
divergencias que son mejoras sobre la propuesta (mas granular,
mas flexible) se documentan pero no se cambian.

Excepciones explicitas:

- `upstream.conf` ausente: la propuesta menciona tres vhosts pero
  la implementacion usa `proxy_pass` directo. Es una simplificacion
  funcional equivalente para el scope del template, no un bug.
- Variables `F2B_NGINX_*` con nomenclatura mas granular: el
  documento propone una sola jail nginx generica; la implementacion
  tiene dos jails separadas. La implementacion es mejor.

## Que produce esta iniciativa

| Entregable | Estado al cierre |
|------------|------------------|
| `scripts/verify.sh` corregido | Producido — mensajes de error usan start.sh en lugar de systemctl |
| `src/services/apiService.js` corregido | Producido — URL construction soporta baseURL vacio |
| `src/constants/index.js` corregido | Producido — API_BASE sin fallback a localhost |
| `webpack.config.js` actualizado | Producido — API_URL sin fallback a localhost:8000 |
| Documentacion actualizada | Producido — README y .env.example documentan API_URL para produccion |

## Indice de documentos

| Documento | Proposito |
|-----------|-----------|
| [index-auditar-gaps-server-y-ui.md](index-auditar-gaps-server-y-ui.md) | Este archivo. Metadata, filosofia, entregables, decisiones. |
| [alcance-auditar-gaps-server-y-ui.md](alcance-auditar-gaps-server-y-ui.md) | Que cubre, criterio de completitud, fuera de alcance, estimacion. |
| [analisis-auditar-gaps-server-y-ui.md](analisis-auditar-gaps-server-y-ui.md) | Inventario exhaustivo de gaps con evidencia concreta. |
| [plan-auditar-gaps-server-y-ui.md](plan-auditar-gaps-server-y-ui.md) | DAG de fases, tareas por fase con esfuerzo. |
| [tareas-auditar-gaps-server-y-ui.md](tareas-auditar-gaps-server-y-ui.md) | Lista plana de tareas con estado y entregable. |
| [progreso-auditar-gaps-server-y-ui.md](progreso-auditar-gaps-server-y-ui.md) | Bitacora cronologica de eventos atomizados. |
| [decisiones-auditar-gaps-server-y-ui.md](decisiones-auditar-gaps-server-y-ui.md) | Decisiones de diseno, hallazgos y verificacion post-ejecucion. |

## Decisiones aprobadas

| ID | Decision | Contenido |
|----|----------|-----------|
| D-PROXY-RELATIVO | Corregir `apiService.js` para que funcione con `API_URL` vacio usando `window.location.origin` como base. | Con `API_URL` vacio, las llamadas al backend usan URLs relativas (`/api/v1/...`) que el browser resuelve contra el mismo origen. Nginx intercepta `/api/*` y proxea al backend. Esto es la arquitectura correcta para el modelo servidor + proxy. |
| D-FALLBACK-VACIO | Eliminar el fallback `http://localhost:8000` de `webpack.config.js` y `constants/index.js`. | El fallback a `localhost:8000` hace que en produccion sin `.env.production` las llamadas al backend vayan directamente a localhost:8000, bypasseando el proxy Nginx. Un valor vacio fuerza URLs relativas y hace que el error de configuracion sea obvio en lugar de silencioso. |
| D-START-SH-EN-VERIFY | En `verify.sh`, los mensajes de error de arranque de daemons referencian `start.sh` en lugar de `systemctl`. | El script `scripts/start.sh` existe precisamente para entornos sin systemd. Referenciar `systemctl` directamente en los mensajes de error crea confusion en WSL2. |
| D-UPSTREAM-CONF-NO-APLICA | No crear `upstream.conf` separado. | El `proxy_pass` directo con `%%API_UPSTREAM%%` es funcional y mas simple para el scope del template. Un `upstream {}` separado aportaria keepalive al backend, util en produccion de alto trafico pero no para un template de demostracion. |

## Alcance cruzado con otros repos

Esta iniciativa coordina trabajo en DOS repos:

- `template-ecommerce-server` — correccion de `scripts/verify.sh`
  y documentacion de `API_URL` en `.env.example` y `README.md`.
- `template-ecommerce-ui` — correccion de `src/services/apiService.js`,
  `src/constants/index.js` y `webpack.config.js`.

El progreso PM vive en `template-ecommerce-server`. Cada repo
registra sus propios commits unitarios.

## Iniciativas relacionadas

- INI-SRV-001 `crear-template-ecomerce-ui-server` (cerrada):
  produjo la implementacion auditada en esta iniciativa.
- INI-SRV-006 `crear-start-sh` (cerrada): produjo `start.sh`
  que esta iniciativa referencia en los mensajes de verify.sh.
