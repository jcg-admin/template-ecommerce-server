# template-ecommerce-server

Repositorio de infraestructura de servidor web para servir el
build de produccion del template
[`template-ecommerce-ui`][repo-ui]. Proyecto hermano: provisiona
un Ubuntu listo para servir el UI React via Nginx + SSL
Let's Encrypt + fail2ban + SSH hardening.

| Campo | Valor |
|-------|-------|
| Naturaleza | Devops / aprovisionamiento de servidor Linux |
| OS objetivo | Ubuntu 24.04 LTS |
| Stack | Nginx + SSL via [`acme.sh`][acme-sh] + fail2ban + UFW |
| Proyecto al que sirve | [`template-ecommerce-ui`][repo-ui] (UI React) |
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

7 iniciativas cerradas (INI-SRV-001..007) + 1 en ejecucion
(INI-SRV-008). 61 commits. Todos los provisioners, scripts
operativos, tests, configs y documentacion estan en su lugar.

| Iniciativa | Descripcion | Estado |
|------------|-------------|--------|
| [INI-SRV-001][doc-ini-001] | Crear template-ecommerce-server (12 fases, 31 tareas) | Cerrada |
| [INI-SRV-002][doc-ini-002] | Integrar commits faltantes desde backup 20260522 | Cerrada |
| [INI-SRV-003][doc-ini-003] | Corregir rutas ecom a tui y nomenclatura en docs | Cerrada |
| [INI-SRV-004][doc-ini-004] | Corregir links de navegacion rotos en iniciativa historica | Cerrada |
| [INI-SRV-005][doc-ini-005] | Crear script de aprovisionamiento unificado (setup.sh) | Cerrada |
| [INI-SRV-006][doc-ini-006] | Crear script de arranque de daemons (start.sh) | Cerrada |
| [INI-SRV-007][doc-ini-007] | Auditar y corregir gaps entre analisis y la implementacion | Cerrada |
| [INI-SRV-008][doc-ini-008] | Actualizar README y crear indice de documentacion | En ejecucion |

Ver [indice completo de iniciativas][doc-indice-ini].

### Inventario

| Categoria | Path | LOC |
|-----------|------|-----|
| Utils bash | [`utils/`](utils/) (4 archivos) | 832 |
| Provisioners | [`provisioners/`](provisioners/) (6 archivos en nginx/, ssl/, security/, firewall/) | 2326 |
| Scripts operativos | [`scripts/`](scripts/) (4 archivos: `setup.sh`, `start.sh`, `verify.sh`, `renew_ssl.sh`) | 1318 |
| Tests bash | [`tests/`](tests/) (6 scripts: 5 suites + run_all) | 907 |
| Templates Nginx | [`config/nginx/template-{http,https}.conf`](config/nginx/) | 388 |
| Docs tecnica | [`docs/`](docs/) (arquitectura, operaciones, seguridad, glosario, upgrade-systemless) | ~2200 (Markdown) |
| Docs PM | [`docs/pm/iniciativas/`](docs/pm/iniciativas/) (8 iniciativas INI-SRV-001..008) | ~15000 (Markdown) |

**Tests agregados**: 5 suites OK, 74 PASS / 0 FAIL / 1 SKIP
(ejecutar `bash tests/run_all.sh`).

## Quick start

> **Antes de empezar**: verifica que tienes clave SSH en
> `~/.ssh/authorized_keys`. El script lo verifica antes de
> ejecutar y aborta si no la encuentra.

**Flujo normal (servidor de produccion):**

```bash
# 0. Clonar
git clone https://github.com/jcg-admin/template-ecommerce-server.git
cd template-ecommerce-server

# 1. Configurar
cp .env.example .env
nano .env   # editar DOMAIN, UI_DIST, SSL_EMAIL, SSH_PORT

# 2. Fase 1: Nginx + SSH hardening
sudo bash scripts/setup.sh

# El script pausa aqui con instrucciones de reconexion.
# Reconectar en el nuevo puerto: ssh -p $SSH_PORT deploy@server

# 3. Fase 2: firewall + fail2ban + SSL + vhosts + verify
sudo bash scripts/setup.sh --continue
```

**Flujo WSL2 / CI (sin SSH nativo):**

```bash
sudo bash scripts/setup.sh --skip-ssh --ssl-dev
```

**Flujo staging (validar ACME antes de produccion):**

```bash
sudo bash scripts/setup.sh                         # Fase 1
# Reconectar
sudo bash scripts/setup.sh --continue --ssl-staging # Fase 2
```

```bash
# Ver todos los flags disponibles:
bash scripts/setup.sh --help
```

Detalle completo del aprovisionamiento en
[`docs/operaciones.md`][doc-operaciones] (8 secciones,
walkthrough VPS Ubuntu fresh + recuperacion de fallos +
FAQ + apendices).

Para entornos sin systemd (WSL2, contenedores, CI), ver
[`docs/upgrade-server-systemless.md`][doc-upgrade].

**Arranque de daemons en WSL2 (cada reinicio):**

En WSL2 sin systemd los daemons no arrancan automaticamente.
Tras cada reinicio:

```bash
sudo bash scripts/start.sh
```

## Pre-requisitos

- Ubuntu 24.04 LTS (servidor) o WSL2 (desarrollo)
- Acceso `sudo` al servidor como cuenta `deploy` (UID 1000).
  `develop` no tiene sudo y no puede ejecutar provisioners ni scripts.
- Dominio publico (para SSL Let's Encrypt real; opcional para
  setup self-signed en desarrollo via `--dev`)
- [`template-ecommerce-ui`][repo-ui] clonado en
  `/srv/repos/tui/template-ecommerce-ui` (o donde decidas, ajustando
  `UI_DIST` en `.env`) y compilado con `API_URL` vacio para activar
  el proxy Nginx:
  ```bash
  cd template-ecommerce-ui
  API_URL='' npm run build
  ```
  El `dist/` resultante usa URLs relativas (`/api/v1/...`) que Nginx
  intercepta y proxea a `API_UPSTREAM`. Si el backend esta en un host
  distinto al del servidor, configurar `API_URL=https://api.dominio.com`
  en su lugar.

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

Sigue PROC-GESTION-001 v4.0.0 + arc42. El trabajo se registra en
iniciativas bajo [`docs/pm/iniciativas/`][doc-indice-ini].
Commits siguen el formato Tim Pope (subject <=50 chars, body
wrap 72 chars).

## Licencia

A definir.

<!-- Referencias Markdown -->
[repo-ui]: https://github.com/jcg-admin/template-ecommerce-ui
[ref-ecomerce-server]: https://github.com/jcg-admin/e-comerce-server
[acme-sh]: https://github.com/acmesh-official/acme.sh
[doc-arquitectura]: docs/arquitectura.md
[doc-operaciones]: docs/operaciones.md
[doc-upgrade]: docs/upgrade-server-systemless.md
[doc-desarrollo]: docs/desarrollo/
[doc-docs]: docs/README.md
[doc-indice-ini]: docs/pm/indice-de-iniciativas.md
[doc-ini-001]: docs/pm/iniciativas/crear-template-ecomerce-ui-server/
[doc-ini-002]: docs/pm/iniciativas/integrar-commits-backup-20260522/index-integrar-commits-backup-20260522.md
[doc-ini-003]: docs/pm/iniciativas/corregir-paths-ecom-a-tui-server/index-corregir-paths-ecom-a-tui-server.md
[doc-ini-004]: docs/pm/iniciativas/corregir-links-navegacion-historica/index-corregir-links-navegacion-historica.md
[doc-ini-005]: docs/pm/iniciativas/crear-setup-sh/index-crear-setup-sh.md
[doc-ini-006]: docs/pm/iniciativas/crear-start-sh/index-crear-start-sh.md
[doc-ini-007]: docs/pm/iniciativas/auditar-gaps-server-y-ui/index-auditar-gaps-server-y-ui.md
[doc-ini-008]: docs/pm/iniciativas/actualizar-readme-y-crear-docs-indice/index-actualizar-readme-y-crear-docs-indice.md
[analisis-ui]: https://github.com/jcg-admin/template-ecommerce-ui/blob/main/docs/desarrollo/analisis-servidor-para-template.md
