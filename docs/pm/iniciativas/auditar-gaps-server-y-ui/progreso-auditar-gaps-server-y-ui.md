# Progreso: Auditar y corregir gaps entre analisis y la implementacion

## Eventos atomizados

| Timestamp | Clase | Referencia | Detalle |
|-----------|-------|------------|---------|
| 2026-05-25T22:00:00 | Apertura | iniciativa | **Apertura formal de INI-SRV-007 `auditar-gaps-server-y-ui`.** El usuario solicita verificar si el documento `analisis-servidor-para-template.md` esta cumplido en `template-ecommerce-server` y si `template-ecommerce-ui` necesita actualizaciones. |
| 2026-05-25T22:00:01 | Plan | iniciativa | **Plan en 5 fases aprobado.** F0 (auditoria + PM, 45 min) → F1 (verify.sh, 5 min) ‖ F2 (UI apiService, 30 min) → F3 (docs, 20 min) → F4 (verificacion y cierre, 15 min). F1 y F2 son paralelas. Esfuerzo total: ~2 horas. |
| 2026-05-25T22:00:02 | Decisiones aprobadas | INI-SRV-007 | **4 decisiones D-* aprobadas**: D-PROXY-RELATIVO (corregir apiService para URLs relativas), D-FALLBACK-VACIO (eliminar fallback localhost:8000), D-START-SH-EN-VERIFY (referenciar start.sh en verify.sh), D-UPSTREAM-CONF-NO-APLICA (no crear upstream.conf separado). |
| 2026-05-25T22:00:03 | Inicio de fase | F0 | **Inicio de Fase F0 (Auditoria + PM docs).** Esfuerzo estimado 45 min. |
| 2026-05-25T22:00:04 | Inicio de tarea | T-001 | Comienzo T-001. Leer `analisis-servidor-para-template.md` e inventariar propuestas. |
| 2026-05-25T22:05:00 | Cierre de tarea | T-001 | Cierre T-001. Documento leido. 17 propuestas inventariadas: Nginx, SPA catch-all, reverse proxy, SSL, fail2ban, cuentas, almacenamiento, headers, TLS, ciphers, UFW, SSH, verify.sh, renew_ssl, tests, variables .env, vhosts. |
| 2026-05-25T22:05:01 | Inicio de tarea | T-002 | Comienzo T-002. Auditar template-ecommerce-server contra las 17 propuestas. |
| 2026-05-25T22:10:00 | Hallazgo durante la ejecucion | T-002 | **verify.sh: 3 mensajes de error referencian `systemctl` en lugar de `start.sh`.** Lineas 157, 158, 292 (nginx) y 474 (fail2ban). En entornos sin systemd (WSL2) el operador que sigue estas instrucciones no puede arrancar los daemons. `scripts/start.sh` existe exactamente para este caso y no se referencia. |
| 2026-05-25T22:10:01 | Hallazgo durante la ejecucion | T-002 | **`upstream.conf` no existe; implementacion usa `proxy_pass` directo.** El documento propone 3 vhosts. La implementacion tiene 2. El `proxy_pass %%API_UPSTREAM%%` directo es funcional para el scope del template. Decisado como aceptable (D-UPSTREAM-CONF-NO-APLICA). |
| 2026-05-25T22:11:00 | Cierre de tarea | T-002 | Cierre T-002. 16 de 17 propuestas CUMPLEN. 1 gap real (verify.sh mensajes). 1 divergencia aceptada (upstream.conf). Las variables F2B_NGINX_* son una mejora sobre la propuesta (2 jails vs 1). |
| 2026-05-25T22:11:01 | Inicio de tarea | T-003 | Comienzo T-003. Auditar template-ecommerce-ui: apiService.js, webpack.config.js, MSW en produccion, compatibilidad del dist/ con Nginx. |
| 2026-05-25T22:20:00 | Hallazgo durante la ejecucion | T-003 | **BUG CRITICO: `apiService.js` lanza TypeError con `API_URL` vacio.** `new URL('/api/v1/addresses/')` sin base absoluta lanza TypeError. El fallback a `http://localhost:8000` oculta el bug en produccion pero lo reemplaza por otro: todas las llamadas al backend van directamente a localhost:8000, bypasseando el proxy Nginx de la arquitectura propuesta. |
| 2026-05-25T22:20:01 | Hallazgo durante la ejecucion | T-003 | **MSW correctamente guardado en produccion.** `src/index.jsx` usa `if (process.env.NODE_ENV !== 'production')` que webpack reemplaza con `if (false)` en produccion. Tree shaking elimina el bloque. MSW no se activa en produccion. Sin gap aqui. |
| 2026-05-25T22:20:02 | Hallazgo durante la ejecucion | T-003 | **`webpack.config.js` produce `dist/` compatible con Nginx.** `publicPath: '/'`, `contenthash` en nombres de archivo, `HtmlWebpackPlugin` genera `index.html`. Sin supuestos de Django. El `dist/` es directamente consumible por Nginx con la config del server. |
| 2026-05-25T22:21:00 | Cierre de tarea | T-003 | Cierre T-003. 1 bug critico en apiService.js + 2 archivos relacionados (constants/index.js, webpack.config.js) con el mismo fallback incorrecto. MSW y dist/ correctos. |
| 2026-05-25T22:21:01 | Inicio de tarea | T-004 | Comienzo T-004. Crear 6 documentos PM. |
| 2026-05-25T22:40:00 | Cierre de tarea | T-004 | Cierre T-004. 6 archivos PM creados con hallazgos concretos, evidencia de codigo, diagrama de secuencia del flujo correcto en produccion. |
| 2026-05-25T22:40:01 | Fase cerrada | F0 | **Cierre de Fase F0 (Auditoria + PM docs).** 4 tareas cerradas. 4 gaps identificados: 1 en server (verify.sh, menor), 3 en UI (apiService critico + 2 archivos relacionados). 3 hallazgos positivos: 16/17 propuestas cumplen, MSW guardado correctamente, dist/ compatible con Nginx. Esfuerzo real: ~40 min. Siguiente: F1 y F2 en paralelo. |
| 2026-05-25T22:45:00 | Inicio de fase | F1 | **Inicio de Fase F1 (Corregir verify.sh).** Esfuerzo estimado 5 min. 3 ocurrencias de `systemctl start nginx/fail2ban` a reemplazar. |
| 2026-05-25T22:45:01 | Inicio de tarea | T-101 | Comienzo T-101. Reemplazar mensajes de error en verify.sh. |
| 2026-05-25T22:47:00 | Cierre de tarea | T-101 | Cierre T-101. 3 ocurrencias reemplazadas: lineas 157 (start.sh), 292 (start.sh), 474 (start.sh). La linea 158 de `systemctl status nginx` se mantiene como informacion adicional de diagnostico (no es un comando de arranque). |
| 2026-05-25T22:47:01 | Cierre de tarea | T-102 | Cierre T-102. `bash -n verify.sh`: OK. `bash tests/run_all.sh`: 74 PASS / 0 FAIL / 1 SKIP. Sin regresion. |
| 2026-05-25T22:47:02 | Fase cerrada | F1 | **Cierre de Fase F1 (Corregir verify.sh).** 2 tareas cerradas. verify.sh corregido: 3 mensajes de error actualizados. Esfuerzo real: ~3 min. |
