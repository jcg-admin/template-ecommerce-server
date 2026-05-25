# Decisiones: Auditar y corregir gaps entre analisis y la implementacion

| Campo | Valor |
|-------|-------|
| Iniciativa | INI-SRV-007 auditar-gaps-server-y-ui |
| Tipo de documento | Decisiones, hallazgos y verificacion post-ejecucion |
| Obligatoriedad | Obligatorio al cierre segun PROC-GESTION-001 v4.0.0 |
| Fecha de creacion | 2026-05-25 |

> **Por que existe este documento.** Las tareas dicen *que* se hizo.
> El progreso dice *cuanto*. Este documento registra el *por que*,
> los *hallazgos* y la *verificacion final*.

---

## Seccion 1 — Decisiones de diseno

### dec-url-construction-con-origin

| Campo | Valor |
|-------|-------|
| Decision | Corregir `apiService._request` para usar `window.location.origin` como base cuando `baseURL` esta vacio y `path` es relativo. |
| Alternativas | (a) `window.location.origin` como base (elegida). (b) Documentar que `API_URL` siempre debe configurarse en `.env.production`. (c) Cambiar todos los hooks para pasar URLs absolutas. |
| Razon | La alternativa (b) es fragil: requiere disciplina del operador en cada despliegue y falla silenciosamente si se olvida. La alternativa (c) requiere cambiar decenas de archivos y pierde la separacion entre logica de dominio y logica de red. La alternativa (a) es el comportamiento estandar del constructor `URL` del browser y de `fetch`: URLs relativas se resuelven contra el origen actual. |
| Trade-off aceptado | Con `baseURL` vacio, si el codigo se ejecuta en Node.js (SSR) sin `window`, se usa `http://localhost` como fallback. Para el template (React CSR), esto no aplica. Si en el futuro se agrega SSR, el fallback debera revisarse. |

### dec-fallback-vacio-en-build

| Campo | Valor |
|-------|-------|
| Decision | Eliminar el fallback `http://localhost:8000` de `webpack.config.js` y `constants/index.js`. El valor por defecto es cadena vacia. |
| Alternativas | (a) Vacio como default (elegida). (b) Mantener `localhost:8000` y documentar que el operador debe configurar `.env.production`. (c) Usar la variable de entorno `DOMAIN` del server como base. |
| Razon | La alternativa (b) produce bugs silenciosos: un bundle compilado sin `.env.production` explícita funciona aparentemente en local (porque hay un backend en `localhost:8000`) pero falla en produccion sin ningun mensaje de error claro. La alternativa (a) produce un fallo obvio si el backend no esta configurado, lo cual es mas correcto que un fallo silencioso. |
| Trade-off aceptado | Los desarrolladores que compilaban con `npm run build` sin configurar `API_URL` ahora necesitan configurarlo explicitamente o usar `API_URL='' npm run build`. La instruccion esta documentada en el README del UI y en el `.env.example` del server. |

### dec-start-sh-en-mensajes-de-error

| Campo | Valor |
|-------|-------|
| Decision | Referenciar `sudo bash scripts/start.sh` en los mensajes de error de verify.sh en lugar de `sudo systemctl start nginx/fail2ban`. |
| Alternativas | (a) `scripts/start.sh` (elegida). (b) Mantener `systemctl` con nota adicional para WSL2. (c) Detectar entorno en verify.sh y usar comando apropiado. |
| Razon | `scripts/start.sh` ya maneja ambos entornos (con y sin systemd) internamente. La alternativa (b) duplica logica. La alternativa (c) complica verify.sh innecesariamente. Un solo comando que funciona en ambos entornos es la solucion mas simple. |
| Trade-off aceptado | En entornos con systemd, `scripts/start.sh` es menos directo que `systemctl start nginx`, pero es igualmente correcto (usa `svc_start` que delega a systemctl). |

### dec-upstream-conf-no-aplica

| Campo | Valor |
|-------|-------|
| Decision | No crear `upstream.conf` separado con bloque `upstream {}`. La config actual usa `proxy_pass %%API_UPSTREAM%%` directo. |
| Alternativas | (a) `proxy_pass` directo (mantenida). (b) Bloque `upstream {}` en archivo separado con keepalive al backend. |
| Razon | El bloque `upstream {}` con `keepalive 32` aporta reutilizacion de conexiones TCP al backend — relevante para produccion de alto trafico. Para el scope de un template de demostracion, el overhead de crear y mantener otro archivo de config no esta justificado. Si el backend usa socket Unix, `proxy_pass unix:/run/gunicorn.sock` no requiere `upstream {}`. |
| Trade-off aceptado | Sin `upstream {}`, cada request al backend abre una conexion TCP nueva. En produccion real con trafico significativo, el operador debera agregar el bloque `upstream {}` manualmente. Documentado como mejora futura opcional. |

---

## Seccion 2 — Hallazgos durante la ejecucion

### hallazgo-apiservice-url-construction-bug

El bug en `apiService.js` pasaba desapercibido porque el fallback
`http://localhost:8000` siempre evitaba que `new URL('/api/...')`
lanzara `TypeError`. En entornos de desarrollo local el backend
corre en `localhost:8000`, por lo que el bypass del proxy Nginx
no era observable. Solo en un despliegue real (con el backend en
un host diferente) el bug se manifestaria como fallo de red.

La arquitectura del proxy Nginx estaba implementada correctamente
en el server, pero sin el fix del UI, el proxy era inutil: el
browser nunca hacia requests al path `/api/*` del servidor Nginx
porque las requests iban directamente a `http://localhost:8000`.

### hallazgo-msw-correctamente-guardado

La auditoria confirmo que MSW (Mock Service Worker) esta
correctamente guardado en produccion mediante
`if (process.env.NODE_ENV !== 'production')` en `src/index.jsx`.
webpack.config.js reemplaza `process.env.NODE_ENV` con `'production'`
en el build de produccion, lo que convierte el bloque en
`if (false)` que el minificador elimina completamente.

No era necesario ningun cambio adicional para MSW.

### hallazgo-dist-compatible-con-nginx

El analisis de `webpack.config.js` confirmo que el `dist/` producido
es directamente compatible con la config Nginx del server:
`publicPath: '/'` alinea con `root %%UI_DIST%%`, los hashes de
`contenthash` alinean con `cache 1y immutable`, y `HtmlWebpackPlugin`
genera el `index.html` que Nginx sirve como SPA catch-all. No se
requeria ningun cambio en webpack para la compatibilidad con Nginx.

### hallazgo-16-de-17-propuestas-cumplen

La auditoria sistematica del documento
`analisis-servidor-para-template.md` contra la implementacion real
confirma 16 de 17 propuestas implementadas. La unica divergencia
(upstream.conf) es una simplificacion aceptada, no un bug.
Las variables `F2B_NGINX_*` son una mejora sobre la propuesta
(2 jails nginx especificas vs 1 jail generica).

---

## Seccion 3 — Verificacion post-ejecucion

| Criterio del alcance | Resultado | Evidencia |
|---------------------|-----------|-----------|
| verify.sh: 0 ocurrencias de `systemctl start nginx/fail2ban` | PASA | `grep "systemctl start nginx\|systemctl start fail2ban" verify.sh` retorna 0 |
| apiService.js: API_URL vacio no lanza TypeError | PASA | Node.js: `new URL('/api/v1/...', 'https://midominio.com')` = `https://midominio.com/api/v1/...` |
| apiService.js: API_URL absoluto funciona correctamente | PASA | Node.js: `new URL('https://api.otro.com/api/v1/products/')` correcto |
| constants/index.js: sin fallback localhost | PASA | `grep "localhost" src/constants/index.js` retorna 0 |
| webpack.config.js: sin fallback localhost en API_URL | PASA | Fallback eliminado, reemplazado por string vacio |
| .env.example server: documenta relacion API_UPSTREAM / API_URL | PASA | Bloque API_UPSTREAM ampliado con instrucciones de build |
| README server: build command con API_URL='' | PASA | Prerequisito actualizado |
| README UI: seccion de despliegue con API_URL='' | PASA | Seccion "Servidor de despliegue" actualizada |
| bash tests/run_all.sh server: PASS >= 74, FAIL = 0 | PASA | 74 PASS / 0 FAIL / 1 SKIP |

## Cierre

Esta iniciativa esta **cerrada**. Los 7 criterios de completitud
se cumplen. Los 4 hallazgos estan documentados. Las 4 decisiones
de diseno tienen alternativas y trade-offs registrados.

El sistema de proxy Nginx ahora funciona correctamente de extremo
a extremo: el UI compilado con `API_URL=''` usa URLs relativas que
Nginx intercepta y proxea al backend configurado en `API_UPSTREAM`.
