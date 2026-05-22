# template-ecomerce-ui-server

Repositorio de infraestructura de servidor web para servir el
build de produccion del template
[`template-e-comerce-ui`][repo-ui]. Proyecto hermano: provisiona
un Ubuntu listo para servir el UI React via Nginx + SSL
Let's Encrypt + fail2ban + SSH hardening.

| Campo | Valor |
|-------|-------|
| Naturaleza | Devops / aprovisionamiento de servidor Linux |
| OS objetivo | Ubuntu 24.04 LTS |
| Stack | Nginx + SSL via [`acme.sh`][acme-sh] + fail2ban + UFW |
| Proyecto al que sirve | [`template-e-comerce-ui`][repo-ui] (UI React) |
| Backend | **Externo, agnostic** (reverse-proxy a `$API_UPSTREAM`) |
| Inspirado en | [`jcg-admin/e-comerce-server`][ref-ecomerce-server] (Apache + Django) |
| Estado | **Operativo**. Iniciativa cerrada (12 fases, 31 tareas, 29 commits). |
| Autor | Nestor Monroy |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 + arc42 |

## Arquitectura 3-tier

```mermaid
%%{init: {'theme':'base', 'themeVariables': {
  'background': '#0f172a',
  'primaryColor': '#1e293b',
  'primaryTextColor': '#f1f5f9',
  'primaryBorderColor': '#94a3b8',
  'lineColor': '#cbd5e1',
  'secondaryColor': '#334155',
  'tertiaryColor': '#1e3a8a',
  'fontSize': '13px'
}}}%%
flowchart TB
    internet_publica([Internet])
    nginx_web_server["<b>Nginx :443</b><br/>Este repo provisiona"]
    bundle_estatico_ui[("Static UI bundle<br/><i>$UI_DIST</i><br/><i>(output de npm run build)</i>")]
    backend_api_upstream(["<b>$API_UPSTREAM</b><br/><i>Backend externo<br/>fuera de scope</i>"])

    internet_publica -- "HTTPS :443" --> nginx_web_server
    nginx_web_server -- "Static + SPA catch-all<br/>/, /cart, /checkout..." --> bundle_estatico_ui
    nginx_web_server -- "Reverse proxy<br/>/api/*" --> backend_api_upstream

    classDef primaryNode fill:#1e293b,stroke:#60a5fa,stroke-width:2px,color:#f1f5f9
    classDef externalNode fill:#334155,stroke:#94a3b8,stroke-width:1px,color:#cbd5e1,stroke-dasharray: 5 5
    classDef internetNode fill:#1e3a8a,stroke:#60a5fa,stroke-width:2px,color:#f1f5f9

    class nginx_web_server primaryNode
    class bundle_estatico_ui primaryNode
    class backend_api_upstream externalNode
    class internet_publica internetNode
```

**Punto clave**: este server **no asume** que existe un backend
API ni que tecnologia usa. Provee la capa de servir el UI y un
reverse proxy configurable hacia donde la API exista cuando
exista.

Detalle completo en [`docs/arquitectura.md`][doc-arquitectura].

## Estado actual del repositorio

Iniciativa
[`crear-template-ecomerce-ui-server`][doc-iniciativa]
**cerrada**: 12 fases, 31 tareas, 29 commits unitarios. Todos los
provisioners, scripts operativos, tests, configs y documentacion
estan en su lugar.

### Inventario

| Categoria | Path | LOC |
|-----------|------|-----|
| Utils bash | [`utils/`](utils/) (4 archivos) | 832 |
| Provisioners | [`provisioners/`](provisioners/) (6 archivos en nginx/, ssl/, security/, firewall/) | 2315 |
| Scripts operativos | [`scripts/verify.sh`](scripts/verify.sh) + [`renew_ssl.sh`](scripts/renew_ssl.sh) | 802 |
| Tests bash | [`tests/`](tests/) (6 scripts: 5 suites + run_all) | 707 |
| Templates Nginx | [`config/nginx/template-{http,https}.conf`](config/nginx/) | 388 |
| Docs tecnica | [`docs/`](docs/) (arquitectura, operaciones, seguridad, glosario, upgrade-systemless) | ~2200 (Markdown) |
| Docs PM (iniciativa) | [`docs/pm/iniciativas/crear-template-ecomerce-ui-server/`][doc-iniciativa] | ~5000 (Markdown) |

**Tests agregados**: 5 suites OK, 72 PASS / 0 FAIL / 1 SKIP
(ejecutar `bash tests/run_all.sh`).

## Quick start

> **Antes de empezar**: verifica que tienes clave SSH en
> `~/.ssh/authorized_keys` o el paso 3 te dejara locked-out.

```bash
# 0. Clonar
git clone https://github.com/jcg-admin/template-ecomerce-ui-server.git
cd template-ecomerce-ui-server

# 1. Configurar
cp .env.example .env
nano .env   # editar DOMAIN, UI_DIST, SSL_EMAIL, SSH_PORT, SSL_STAGING=true

# 2. Instalar Nginx
sudo bash provisioners/nginx/install.sh

# 3. Endurecer SSH (cambia el puerto; reconectar despues)
sudo bash provisioners/security/setup_ssh_hardening.sh
# >>> reconectar: ssh -p $SSH_PORT deploy@server <<<

# 4. Firewall (permite SSH_PORT ANTES de activar UFW)
sudo bash provisioners/firewall/setup_firewall.sh

# 5. fail2ban (requiere UFW activo)
sudo bash provisioners/security/setup_fail2ban.sh

# 6. SSL (empezar con SSL_STAGING=true; cambiar a false cuando todo funcione)
sudo bash provisioners/ssl/setup_ssl.sh

# 7. Activar virtualhosts (sustituye placeholders %%VAR%% con valores de .env)
sudo bash provisioners/nginx/setup_vhost.sh

# 8. Verificar (12 checks end-to-end)
bash scripts/verify.sh
```

**Orden critico** (no es arbitrario):

1. `nginx install` primero -- los provisioners siguientes asumen
   que `/etc/nginx/sites-available/` existe.
2. `ssh_hardening` **ANTES** que `firewall` -- el hardening
   define `SSH_PORT` efectivo; UFW debe permitirlo antes de
   activarse o cortas tu propia sesion.
3. `firewall` **ANTES** que `fail2ban` -- `banaction=ufw`
   requiere UFW activo.
4. `ssl` **ANTES** que `setup_vhost` -- el template HTTPS
   referencia el cert; si no existe, `nginx -t` falla.
5. `verify.sh` al final.

Detalle completo y operacion continua en
[`docs/operaciones.md`][doc-operaciones] (955 lineas, 8 secciones,
incluye walkthrough VPS Ubuntu fresh + recuperacion de fallos +
FAQ + apendices).

Para entornos sin systemd (WSL2, contenedores, CI), ver
[`docs/upgrade-server-systemless.md`][doc-upgrade].

## Pre-requisitos

- Ubuntu 24.04 LTS (servidor) o WSL2 (desarrollo)
- Acceso `sudo` al servidor
- Dominio publico (para SSL Let's Encrypt real; opcional para
  setup self-signed en desarrollo via `--dev`)
- [`template-e-comerce-ui`][repo-ui] clonado en
  `/srv/repos/ecom/template-e-comerce-ui` (o donde decidas, ajustando
  `UI_DIST` en `.env`) y compilado con `npm run build` (produce el
  `dist/` que Nginx sirve)

## Modelo de cuentas

El server opera bajo 4 cuentas Linux con separacion estricta de
privilegios:

| Cuenta | UID | Función | Sudo |
|--------|-----|---------|------|
| `deploy` | 1000 | Operador, ejecuta provisioners | Si |
| `infra` | 1001 | Sudo granular NOPASSWD por binario | Granular |
| `develop` | 1002 | Owner del codigo del UI | NO |
| `svc-backups` | 999 | Backups del proyecto | NO + nologin |

El procedimiento externo
`Procedimiento-Implementacion-Almacenamiento-WSL2-ecomerce-p001 v1.0.0`
rige la creacion de cuentas y storage layout.

## Diferencias con el referente [`jcg-admin/e-comerce-server`][ref-ecomerce-server]

| Aspecto | Referente | Este repo |
|---------|-----------|-----------|
| Web server | Apache 2.4 + mod_wsgi | Nginx 1.24+ |
| Backend | Django (acoplado via mod_wsgi + serve_spa) | Externo, agnostic (`$API_UPSTREAM`) |
| SPA catch-all | Django `serve_spa` view | Nginx `try_files $uri /index.html` |
| Modelo cuentas | 5 | 4 (sin `svc-dbdata`) |
| Clases storage | A, B, C | A, B (sin C, no hay BD) |
| fail2ban jails | sshd + apache-auth | sshd + nginx-* |

Justificacion completa de la eleccion Nginx en el documento de
analisis: [analisis-servidor-para-template.md][analisis-ui]
(en el repo del UI).

## Como contribuir

Sigue PROC-GESTION-001 v4.0.0. Trabajo registrado en la
iniciativa
[`docs/pm/iniciativas/crear-template-ecomerce-ui-server/`][doc-iniciativa].
Commits siguen el formato Tim Pope (subject <=50 chars, body
wrap 72 chars).

## Licencia

A definir.

<!-- Referencias Markdown -->
[repo-ui]: https://github.com/jcg-admin/template-e-comerce-ui
[ref-ecomerce-server]: https://github.com/jcg-admin/e-comerce-server
[acme-sh]: https://github.com/acmesh-official/acme.sh
[doc-arquitectura]: docs/arquitectura.md
[doc-iniciativa]: docs/pm/iniciativas/crear-template-ecomerce-ui-server/
[doc-desarrollo]: docs/desarrollo/
[doc-operaciones]: docs/operaciones.md
[doc-upgrade]: docs/upgrade-server-systemless.md
[analisis-ui]: https://github.com/jcg-admin/template-e-comerce-ui/blob/main/docs/desarrollo/analisis-servidor-para-template.md
