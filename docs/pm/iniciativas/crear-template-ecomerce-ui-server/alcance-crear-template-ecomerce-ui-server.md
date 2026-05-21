# Alcance — `crear-template-ecomerce-ui-server`

## Resumen del alcance

Crear el repositorio [`template-ecomerce-ui-server`][repo-server],
un proyecto de aprovisionamiento de servidor Linux,
**inspirado en** [`jcg-admin/e-comerce-server`][ref-ecomerce-server]
pero **adaptado al contexto del template UI**. Resultado:
scripts ejecutables que dejan un Ubuntu 24.04 listo para servir
el build de produccion del [`template-e-comerce-ui`][repo-ui]
con SSL, fail2ban, SSH hardening, UFW y reverse proxy hacia una
API externa.

## Esta dentro del alcance

1. **Estructura del repositorio** siguiendo PROC-GESTION-001
   con sus directorios canonicos: `docs/`, `provisioners/`,
   `scripts/`, `tests/`, `utils/`, `config/`, `backups/`.

2. **Provisioners Nginx**:
   - `install.sh`: instala Nginx 1.24+ desde apt.
   - `setup_vhost.sh`: reemplaza placeholders `%%VAR%%` con
     valores de `.env` y activa los vhosts.

3. **Configuracion Nginx** (templates con placeholders):
   - `config/nginx/template-http.conf`: vhost `:80` redirige a
     HTTPS + excepcion `/.well-known/` para ACME challenge.
   - `config/nginx/template-https.conf`: vhost `:443` SSL +
     reverse proxy `/api/*` + servir static UI + SPA catch-all
     + headers de seguridad.

4. **Provisioners SSL**:
   - `setup_ssl.sh`: acme.sh + Let's Encrypt + fallback
     self-signed para desarrollo.

5. **Provisioners de seguridad**:
   - `setup_fail2ban.sh`: jails `sshd` + `nginx-limit-req` +
     `nginx-botsearch`.
   - `setup_ssh_hardening.sh`: sin password, sin root, puerto
     no estandar configurable.

6. **Provisioners de firewall**:
   - `setup_firewall.sh`: UFW deny incoming + allow outgoing +
     abre SSH_PORT, 80, 443.

7. **Scripts de operacion**:
   - `verify.sh`: checks de salud (Nginx running, certs validos,
     fail2ban activo, espacio disco, perms, etc, ~10 checks).
   - `renew_ssl.sh`: cron quincenal renueva certificados.

8. **Tests bash**:
   - `test_provisioner_syntax.sh`: `bash -n` sobre todos los
     `.sh`.
   - `test_install_idempotency.sh`: ejecutar install dos veces.
   - `test_ssl_self_signed.sh`: setup_ssl con dominio localhost.
   - `test_nginx_ssl_provisioning.sh`: integracion completa.
   - `test_systemd_detection.sh`: WSL2 vs VPS.

9. **Utilidades reutilizables**:
   - `utils/core.sh`, `logging.sh`, `network.sh`,
     `validation.sh` (portadas y adaptadas del referente; en su
     mayoria son agnostic a Apache vs Nginx).

10. **Documentacion**:
    - `README.md` del repo (creado inicialmente).
    - [`docs/operaciones.md`][doc-operaciones]: como aprovisionar
      paso a paso.
    - `docs/upgrade-server-systemless.md`: si aplica.

11. **`.env.example`** con todas las variables documentadas
    (`DOMAIN`, `UI_DIST`, `API_UPSTREAM`, `SSL_*`, `SSH_PORT`,
    `F2B_*`, `NGINX_*`).

12. **Modelo de cuentas Linux**: 4 cuentas (`deploy`, `infra`,
    `develop`, `svc-backups`) con UIDs canonicos. Documentacion
    en [operaciones][doc-operaciones] + referencia al
    procedimiento externo de almacenamiento.

13. **Soporte WSL2 y VPS**: provisioners detectan el entorno y
    aplican skip cuando corresponde (caso `sshd` en WSL2 que lo
    maneja Windows).

## Esta fuera del alcance

1. **No se implementa ningun backend API**. El server hace
   reverse-proxy a `$API_UPSTREAM` pero no decide ni provee
   tecnologia (Django, Node, Go, etc).

2. **No se modifica el repo** [`template-e-comerce-ui`][repo-ui]
   mas alla de un commit final que documente la relacion entre
   ambos (paso F11). Cualquier ajuste al `webpack.config.js` o
   al build del template UI es decision separada y no
   bloqueante.

3. **No se hace despliegue real**. La iniciativa termina con el
   repo listo para ser clonado en un servidor real y ejecutado;
   no incluye ejecutarlo en un servidor concreto del usuario.

4. **No se incluye monitorizacion** (Prometheus, Grafana, etc).
   Solo `verify.sh` como check puntual.

5. **No se incluye CI/CD**. Posible iniciativa futura.

6. **No se hace push del repo a GitHub**. Eso es accion del
   usuario; el repo queda listo en local con la URL del remote
   anotada para que el usuario haga
   `git remote add origin ... && git push -u origin main`
   cuando le convenga.

7. **No incluye gestion de DB ni `svc-dbdata`**. Diferencia
   intencional vs el referente.

## Decisiones aprobadas al abrir la iniciativa

| ID | Decision | Justificacion |
|----|----------|---------------|
| D-WS | Nginx en lugar de Apache | Ver analisis exhaustivo en [analisis-servidor-para-template.md][analisis-ui]. Resumido: catch-all SPA en 1 linea, reverse proxy nativo, footprint menor, agnostic a tecnologia backend. |
| D-CUENTAS | 4 cuentas (sin `svc-dbdata`) | No hay BD en scope. |
| D-STORAGE | 2 clases (A, B) sin C | Idem. |
| D-NOMBRE | `template-ecomerce-ui-server` (sin guion entre `e` y `comerce`) | Decision explicita del usuario en este turno. Difiere del template UI que usa `template-e-comerce-ui` con guion (asimetria intencional registrada). |
| D-BACKEND-AGNOSTIC | El server NO asume tecnologia backend | `$API_UPSTREAM` es variable de entorno; vacio por defecto. Si la API no esta, `/api/*` devuelve 502 hasta configurar. |
| D-PROVISIONER-PATTERN | Heredar patron de scripts shell idempotentes con `%%VAR%%` placeholders del referente | Probado y reutilizable. |

## Criterios de aceptacion

La iniciativa se considera cerrada cuando:

1. El repo [`template-ecomerce-ui-server`][repo-server] existe
   en `/tmp/project/` con commits limpios.
2. Los 4 provisioners principales (Nginx, SSL, seguridad,
   firewall) estan implementados con tests basicos bash.
3. `verify.sh` ejecuta sin error en un Ubuntu 24.04 fresco
   despues de ejecutar todos los provisioners.
4. Los 5 tests bash pasan: `bash tests/run_all.sh` (a definir).
5. El [README][doc-readme] del repo describe la arquitectura,
   el modelo de cuentas, los pre-requisitos y como aprovisionar.
6. `template-e-comerce-ui`/README.md (en el otro repo, commit
   separado) referencia este repo como su server de produccion.

## Riesgos

| Riesgo | Mitigacion |
|--------|------------|
| Reescribir scripts bash del referente para Nginx introduce bugs nuevos | Tests bash en F9 antes de cerrar iniciativa |
| Modelo cuentas Linux complejo de testear en CI | Tests focales en filesystem y permisos; los tests de Nginx-en-vivo requieren entorno real |
| Acoplamiento residual entre webpack output del UI y lo que Nginx espera | F11 (integracion) audita esto |
| `acme.sh` cambia API entre versiones | Pinear version o testear contra ultima durante F5 |
| Tiempo total excede 14h estimadas | Dividir en sub-iniciativas si una fase explota |

## Esfuerzo total estimado

**~14 horas (~1.75 dias de trabajo)** distribuidas en 12 fases
F0..F11. Detalle en [plan][doc-plan].

<!-- Referencias Markdown -->
[doc-plan]: plan-crear-template-ecomerce-ui-server.md
[doc-readme]: ../../../../README.md
[doc-operaciones]: ../../../operaciones.md
[repo-server]: https://github.com/jcg-admin/template-ecomerce-ui-server
[repo-ui]: https://github.com/jcg-admin/template-e-comerce-ui
[ref-ecomerce-server]: https://github.com/jcg-admin/e-comerce-server
[analisis-ui]: https://github.com/jcg-admin/template-e-comerce-ui/blob/main/docs/desarrollo/analisis-servidor-para-template.md
