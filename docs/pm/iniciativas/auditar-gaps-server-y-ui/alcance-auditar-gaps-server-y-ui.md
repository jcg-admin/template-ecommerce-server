# Alcance: Auditar y corregir gaps entre analisis y la implementacion

## Que cubre esta iniciativa

### Repo template-ecommerce-server

Correccion de `scripts/verify.sh`: los mensajes de error de
arranque de daemons (nginx, fail2ban) referencian
`sudo systemctl start nginx` y `sudo systemctl start fail2ban`.
En entornos sin systemd (WSL2) esto es incorrecto; el comando
correcto es `sudo bash scripts/start.sh`. Se corrigen 3
ocurrencias en las funciones `check_nginx_port_80`,
`check_ssl_port_443` y `check_fail2ban`.

Documentacion de `API_URL`: `.env.example` y `README.md`
explicitan que en produccion con el proxy Nginx activo, `API_URL`
debe configurarse como vacio o como el origen del servidor, no
como `http://localhost:8000`.

### Repo template-ecommerce-ui

Correccion de `src/services/apiService.js`: la construccion de
URLs mediante `new URL(path)` lanza `TypeError` cuando `baseURL`
esta vacio y `path` es relativo. Se corrige para usar
`window.location.origin` como base cuando `baseURL` es vacio.

Correccion de `src/constants/index.js`: `API_BASE` tiene un
fallback a `http://localhost:8000` que en produccion sin
configuracion explicita hace que las llamadas al backend vayan
directamente a localhost:8000, bypasseando el proxy Nginx.

Correccion de `webpack.config.js`: `API_URL` tiene un fallback
a `'http://localhost:8000'` que produce el mismo problema.

## Criterio de completitud

1. `verify.sh`: `grep "systemctl start nginx\|systemctl start fail2ban"` retorna 0 resultados.
2. `apiService.js`: con `API_URL = ''`, `new URL('/api/v1/test/', origin)` resuelve correctamente.
3. `constants/index.js`: `API_BASE` es `process.env.API_URL || ''` sin fallback a localhost.
4. `webpack.config.js`: `API_URL` es `process.env.API_URL || resolvedEnv.API_URL || ''` sin fallback a localhost:8000.
5. `.env.example` del server documenta el valor correcto de `API_UPSTREAM` para el modelo de proxy.
6. `bash tests/run_all.sh` en server: PASS >= 74, FAIL = 0.
7. `npm test` en UI: baseline mantenido o mejorado.

## Fuera de alcance

| Item | Razon |
|------|-------|
| Crear `upstream.conf` separado | El `proxy_pass` directo es funcional para el scope del template. D-UPSTREAM-CONF-NO-APLICA. |
| Cambiar las variables F2B_NGINX_* | La nomenclatura mas granular de la implementacion es una mejora, no un gap. |
| Cambiar el numero de checks de verify.sh (12 vs ~10) | 12 checks es dentro del rango esperado y todos son relevantes. |
| Implementar OCSP stapling | Comentado en el https.conf intencionalmente; requiere decisiones de DNS que el template no puede tomar. |
| Configurar Permissions-Policy y CSP | Comentados intencionalmente; dependen del UI especifico. |
| Crear `.env.production` en el UI | Es responsabilidad del operador que despliega, no del template. |

## Estimacion de esfuerzo

| Fase | Descripcion | Esfuerzo |
|------|-------------|----------|
| F0 | Auditoria + PM docs | 45 min |
| F1 | Corregir verify.sh (server) | 5 min |
| F2 | Corregir apiService.js + constants + webpack (UI) | 30 min |
| F3 | Actualizar documentacion (ambos repos) | 20 min |
| F4 | Verificacion y cierre | 15 min |
| Total | | ~2 horas |
