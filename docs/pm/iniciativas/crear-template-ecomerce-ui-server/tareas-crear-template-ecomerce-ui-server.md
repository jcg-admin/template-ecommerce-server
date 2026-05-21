# Tareas — `crear-template-ecomerce-ui-server`

Lista de tareas detalladas por fase. Cada tarea genera uno o
mas commits unitarios. El esfuerzo es estimado y se afina segun
hallazgos.

## F0 — Apertura formal (60 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-001 | Abrir iniciativa: crear este documento + alcance + plan + progreso vacio | 30 min | **Cerrada** | 5 archivos de iniciativa |
| T-002 | Commit inicial del repo con estructura minima y los 5 archivos de iniciativa | 30 min | **Cerrada** | Commit `32f2b9e` |

## F0a — Validaciones iniciales (30 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-011 | Verificar Nginx vs Apache: ratificar decision con el [analisis previo][analisis-ui], considerar Caddy como alternativa rapida. Producir [`docs/desarrollo/decision-nginx-vs-apache.md`][adr-nginx] | 15 min | **Cerrada** | ADR + nota en progreso |
| T-012 | Verificar acceso a la referencia: confirmar [`/tmp/references/e-comerce-server/`][ref-ecomerce-server] accesible y enumerar archivos a portar. Producir [`docs/desarrollo/decision-modelo-cuentas.md`][adr-cuentas] y [`docs/desarrollo/decision-storage-clases.md`][adr-storage] | 15 min | **Cerrada** | Tabla en progreso + 2 ADRs |

## F1 — Estructura del repo (30 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-101 | Crear arbol completo de directorios vacios: `provisioners/{nginx,ssl,security,firewall}/`, `scripts/`, `tests/`, `utils/`, `config/nginx/` | 15 min | Pendiente | Carpetas + `.gitkeep` en cada una |
| T-102 | Commit "Bootstrap repo structure (F1)" | 15 min | Pendiente | Commit |

## F2 — Utils + .env.example (90 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-201 | Portar `utils/core.sh` del referente con adaptacion minima (cambio de marca, mensajes) | 25 min | Pendiente | `utils/core.sh` |
| T-202 | Portar `utils/logging.sh` (1:1 si es posible) | 15 min | Pendiente | `utils/logging.sh` |
| T-203 | Portar `utils/network.sh` (1:1) | 10 min | Pendiente | `utils/network.sh` |
| T-204 | Portar `utils/validation.sh` con adaptacion (vars de entorno propias) | 20 min | Pendiente | `utils/validation.sh` |
| T-205 | Disenar `.env.example` propio (~80 lineas, basado en analisis previo) | 20 min | Pendiente | `.env.example` |

## F3 — Configuracion Nginx (60 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-301 | Crear `config/nginx/template-http.conf` (redirect HTTPS + ACME excepcion) | 20 min | Pendiente | Archivo |
| T-302 | Crear `config/nginx/template-https.conf` (SSL + UI static + SPA catch-all + reverse proxy + headers) | 40 min | Pendiente | Archivo |

## F4 — Provisioners Nginx (120 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-401 | `provisioners/nginx/install.sh`: apt nginx + verificar version + start + enable | 40 min | Pendiente | Script |
| T-402 | `provisioners/nginx/setup_vhost.sh`: reemplazar `%%VAR%%` en configs, validar `nginx -t`, recargar | 60 min | Pendiente | Script |
| T-403 | Tests basicos manuales locales (en WSL2 o contenedor) | 20 min | Pendiente | Verificacion |

## F5 — Provisioner SSL (30 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-501 | Portar `provisioners/ssl/setup_ssl.sh` del referente 1:1 + adaptar `SSL_CERT_DIR` | 30 min | Pendiente | Script |

## F6 — Provisioners seguridad (90 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-601 | `provisioners/security/setup_fail2ban.sh`: adaptar jails (`sshd` + `nginx-limit-req` + `nginx-botsearch`) | 60 min | Pendiente | Script |
| T-602 | `provisioners/security/setup_ssh_hardening.sh`: portar 1:1 | 30 min | Pendiente | Script |

## F7 — Provisioner firewall (30 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-701 | `provisioners/firewall/setup_firewall.sh`: portar 1:1 | 30 min | Pendiente | Script |

## F8 — Scripts de operacion (90 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-801 | `scripts/verify.sh`: ~10 checks adaptados (Nginx running, certs validos, fail2ban, UFW, disk, perms) | 60 min | Pendiente | Script |
| T-802 | `scripts/renew_ssl.sh`: portar 1:1 | 30 min | Pendiente | Script |

## F9 — Tests bash (90 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-901 | `tests/test_provisioner_syntax.sh`: `bash -n` sobre todos los `.sh` | 15 min | Pendiente | Script |
| T-902 | `tests/test_install_idempotency.sh`: ejecutar install dos veces | 25 min | Pendiente | Script |
| T-903 | `tests/test_ssl_self_signed.sh`: setup_ssl con dominio localhost | 20 min | Pendiente | Script |
| T-904 | `tests/test_nginx_ssl_provisioning.sh`: integracion end-to-end | 20 min | Pendiente | Script |
| T-905 | `tests/run_all.sh` + `tests/test_systemd_detection.sh` | 10 min | Pendiente | Scripts |

## F10 — Documentacion (60 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-1001 | [`docs/operaciones.md`][doc-operaciones]: paso a paso de aprovisionamiento | 45 min | Pendiente | Documento |
| T-1002 | `docs/upgrade-server-systemless.md`: si aplica | 15 min | Pendiente | Documento |

## F11 — Integracion con [`template-e-comerce-ui`][repo-ui] (30 min)

| ID | Tarea | Esfuerzo | Estado | Salida |
|----|-------|----------|--------|--------|
| T-1101 | Commit en el repo UI documentando la relacion con este server | 15 min | Pendiente | Commit en otro repo |
| T-1102 | Verificar que `npm run build` del UI produce `dist/` consumible por Nginx (paths relativos, etc) | 15 min | Pendiente | Nota en progreso |

## Resumen ejecutivo

| Fase | Tareas | Esfuerzo |
|------|--------|----------|
| F0 | 2 | 60 min |
| F0a | 2 | 30 min |
| F1 | 2 | 30 min |
| F2 | 5 | 90 min |
| F3 | 2 | 60 min |
| F4 | 3 | 120 min |
| F5 | 1 | 30 min |
| F6 | 2 | 90 min |
| F7 | 1 | 30 min |
| F8 | 2 | 90 min |
| F9 | 5 | 90 min |
| F10 | 2 | 60 min |
| F11 | 2 | 30 min |
| **Total** | **31 tareas** | **~14 horas** |

<!-- Referencias Markdown -->
[doc-operaciones]: ../../../operaciones.md
[adr-nginx]: ../../../desarrollo/decision-nginx-vs-apache.md
[adr-cuentas]: ../../../desarrollo/decision-modelo-cuentas.md
[adr-storage]: ../../../desarrollo/decision-storage-clases.md
[repo-ui]: https://github.com/jcg-admin/template-e-comerce-ui
[ref-ecomerce-server]: https://github.com/jcg-admin/e-comerce-server
[analisis-ui]: https://github.com/jcg-admin/template-e-comerce-ui/blob/main/docs/desarrollo/analisis-servidor-para-template.md
