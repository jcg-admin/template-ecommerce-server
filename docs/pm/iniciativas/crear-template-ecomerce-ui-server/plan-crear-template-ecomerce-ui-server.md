# Plan — `crear-template-ecommerce-server`

## Fases F0..F11

El trabajo se organiza en **12 fases secuenciales** alineadas
con la propuesta del [analisis previo][analisis-ui]. Cada fase
produce uno o mas commits unitarios.

| Fase | Nombre | Esfuerzo | Pre-condiciones | Que produce |
|------|--------|----------|-----------------|-------------|
| **F0** | Apertura formal | 60 min | Acuerdo del usuario | index, alcance, plan, tareas, progreso (este documento) |
| **F0a** | Validaciones iniciales | 30 min | F0 cerrada | Decision Nginx ratificada, repo de referencia confirmado, 3 ADRs |
| **F1** | Estructura del repo + commit inicial | 30 min | F0a cerrada | README, .gitignore, directorios vacios, primer commit |
| **F2** | Utils + .env.example | 90 min | F1 cerrada | `utils/core.sh`, `logging.sh`, `network.sh`, `validation.sh`, `.env.example` |
| **F3** | Configuracion Nginx | 60 min | F2 cerrada | `config/nginx/template-http.conf`, `template-https.conf` con placeholders |
| **F4** | Provisioners Nginx | 120 min | F3 cerrada | `provisioners/nginx/install.sh`, `setup_vhost.sh` |
| **F5** | Provisioner SSL | 30 min | F4 cerrada | `provisioners/ssl/setup_ssl.sh` (portado 1:1, es agnostic a Apache/Nginx) |
| **F6** | Provisioners seguridad | 90 min | F5 cerrada | `setup_fail2ban.sh` (adaptado con jails `nginx-*`), `setup_ssh_hardening.sh` (1:1) |
| **F7** | Provisioner firewall | 30 min | F6 cerrada | `setup_firewall.sh` (1:1) |
| **F8** | Scripts de operacion | 90 min | F7 cerrada | `scripts/verify.sh` (~10 checks adaptados), `renew_ssl.sh` (1:1) |
| **F9** | Tests bash | 90 min | F8 cerrada | 5 tests adaptados + `run_all.sh` |
| **F10** | Documentacion | 60 min | F9 cerrada | [`docs/operaciones.md`][doc-operaciones], `docs/upgrade-server-systemless.md` |
| **F11** | Integracion con [`template-ecommerce-ui`][repo-ui] | 30 min | F10 cerrada | Commit en el repo UI documentando la relacion |
| **Total** | | **~14 horas (~1.75 dias)** | | |

## Disciplina por fase

Para cada fase:

1. **Antes de empezar**: registrar evento `Inicio de fase` en
   [progreso][doc-progreso].
2. **Durante la ejecucion**: cualquier hallazgo organico se
   registra como `Hallazgo durante la ejecucion` sin pausar.
3. **Antes de commitear**: verificar que los tests aplicables
   pasan (las primeras fases no tienen tests aun; desde F9
   en adelante, todo cambio pasa `bash tests/run_all.sh`).
4. **Al cerrar**: registrar evento `Cierre de fase` con
   resumen.

## Estilo de commits

Tim Pope (subject <=50 chars, wrap body 72 chars). Cada fase
puede producir 1 o N commits. Subject sugerido:
`<Verbo> <objeto> (F<n>)`. Ejemplos:

- `Open initiative crear-template-ecommerce-server`
- `Bootstrap repo structure (F1)`
- `Port shell utils from reference (F2)`
- `Add Nginx vhost templates (F3)`
- `Implement Nginx install provisioner (F4)`

## Decisiones aplicables a todas las fases

- **Patron de provisioners**: idempotente (ejecutables N veces
  sin efecto adverso), placeholder `%%VAR%%` para variables que
  se reemplazan al `setup`, log estructurado a stdout con
  `utils/logging.sh`.
- **Detencion ante error**: `set -euo pipefail` en todos los
  scripts.
- **Sin colores en log** por defecto (CI-safe); el script
  `verify.sh` puede usar colores via flag.
- **Verificacion de sudo**: cada provisioner verifica que se
  ejecuta como root (excepto los que claramente no lo
  necesitan).
- **Compatibilidad WSL2**: detectar entorno y aplicar skip
  documentado donde corresponda (`sshd`, UFW).

## Pre-condiciones globales

- Repo de referencia [`jcg-admin/e-comerce-server`][ref-ecomerce-server]
  clonado en `/tmp/references/e-comerce-server/` (sirve de
  referencia durante todas las fases).
- Iniciativa SCSS pausada formalmente (ya hecho en commit
  `7110527` del [repo UI][repo-ui]).
- Acceso al usuario para confirmar decisiones de arquitectura
  durante F0a si surgen ambiguedades.

## Riesgos del plan

| Riesgo | Mitigacion |
|--------|------------|
| Fase F4 explota porque adaptar `setup_vhost.sh` de Apache a Nginx requiere mas tiempo del estimado | Si excede 50%, dividir en F4a y F4b. Cada provisioner es su propio commit. |
| F6 fail2ban tiene jails muy especificos de Apache que no traducen directo a Nginx | Documentar el cambio explicitamente en el progreso; usar jails de Nginx oficiales (`nginx-limit-req`, `nginx-botsearch`). |
| F11 (integracion) descubre que `webpack.config.js` del UI necesita ajustes para que `dist/` sirva via Nginx | Registrar como hallazgo y NO bloquear la iniciativa server; abrir tarea reactiva en el repo UI. |

## Que sigue tras esta iniciativa

Cuando se cierre:

1. El repo [`template-ecommerce-server`][repo-server] queda
   listo para clone y ejecucion en un Ubuntu 24.04 real.
2. Se puede reanudar la iniciativa SCSS
   `mapear-y-corregir-scss-completo` (T-202 pendiente).
3. Iniciativa futura opcional: CI/CD para el server (GitHub
   Actions ejecutando `tests/run_all.sh` en cada PR).

<!-- Referencias Markdown -->
[doc-progreso]: progreso-crear-template-ecommerce-server.md
[doc-operaciones]: ../../../operaciones.md
[repo-server]: https://github.com/jcg-admin/template-ecommerce-server
[repo-ui]: https://github.com/jcg-admin/template-ecommerce-ui
[ref-ecomerce-server]: https://github.com/jcg-admin/e-comerce-server
[analisis-ui]: https://github.com/jcg-admin/template-ecommerce-ui/blob/main/docs/desarrollo/analisis-servidor-para-template.md
