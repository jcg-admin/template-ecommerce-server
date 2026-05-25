# Arquitectura — `template-ecommerce-server`

| Campo | Valor |
|-------|-------|
| Documento | Arquitectura aprobada del server |
| Estado | Inicial. Refleja las decisiones aprobadas al abrir la iniciativa. |
| Producido en | F0 (apertura de la iniciativa) |
| Fuente principal | Analisis previo en el repo UI (commit `7110527`) — ver [referencias][analisis-ui] |
| Referencia externa | Repo de referencia [`jcg-admin/e-comerce-server`][ref-ecomerce-server] (clonado en `/tmp/references/e-comerce-server/`) |

## Vista de alto nivel

El server es la **capa 1 de una arquitectura 3-tier** que sirve
el template [`template-ecommerce-ui`][repo-ui] en produccion:

```mermaid
%%{init: {'theme':'base', 'themeVariables': {
  'background': '#0f172a',
  'primaryColor': '#1e293b',
  'primaryTextColor': '#f1f5f9',
  'primaryBorderColor': '#94a3b8',
  'lineColor': '#cbd5e1',
  'secondaryColor': '#334155',
  'tertiaryColor': '#1e3a8a',
  'fontFamily': 'monospace',
  'fontSize': '14px'
}}}%%
flowchart TB
    internet_publica([Internet])
    nginx_web_server["<b>Nginx :443</b><br/>Este repo provisiona"]
    bundle_estatico_ui[("Static UI bundle<br/><i>/srv/repos/tui/<br/>template-ecommerce-ui/dist/</i>")]
    backend_api_upstream(["<b>$API_UPSTREAM</b><br/><i>Backend externo,<br/>fuera de scope</i>"])

    internet_publica -- "HTTPS<br/>Let's Encrypt acme.sh" --> nginx_web_server
    nginx_web_server -- "Static + SPA<br/>catch-all" --> bundle_estatico_ui
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

## Componentes

### Componente 1: web server

- **Nginx 1.24+** (Ubuntu 24.04 apt repository).
- Funciones:
  - Terminacion SSL (Let's Encrypt en produccion, self-signed en
    desarrollo).
  - Servir static UI bundle desde filesystem.
  - SPA catch-all: cualquier ruta sin extension cae a
    `index.html` para que React Router lo maneje en cliente.
  - Reverse proxy `/api/*` hacia `$API_UPSTREAM`.
  - Cache largo en assets con hash de webpack.
  - Headers HTTP de seguridad (HSTS, X-Frame-Options, etc).
- Configuracion: dos vhosts — uno HTTP `:80` con redirect a HTTPS
  + excepcion ACME, otro HTTPS `:443`. Templates con placeholders
  `%%VAR%%` que se completan al ejecutar `setup_vhost.sh`.

### Componente 2: SSL

- **acme.sh** (no certbot). Gestiona certificados Let's Encrypt
  con cron de renovacion automatica.
- Modo dual:
  - Produccion: dominio publico + DNS apuntando al server.
  - Desarrollo: fallback self-signed si `DOMAIN=localhost`.
- Permisos canonicos:
  - `cert.pem`, `fullchain.pem` con `0644` (publicos).
  - `key.pem` con `0600 root:root` (Nginx master root la lee
    antes de drop-privileges).

### Componente 3: hardening de seguridad

- **fail2ban** con 2 jails activos:
  - `sshd`: bloquea IPs con fallos de autenticacion SSH.
  - `nginx-limit-req` + `nginx-botsearch`: bloquean abusadores.
- **OpenSSH** endurecido: sin password, sin root, puerto no
  estandar configurable.
- **UFW** firewall: deny incoming + allow outgoing + abre solo
  `SSH_PORT` + `80` + `443`.

Detalles concretos en [seguridad][doc-seguridad].

### Componente 4: modelo de cuentas Linux

Cuatro cuentas con separacion estricta de privilegios:

| Cuenta | UID | Funcion | Sudo | Login |
|--------|-----|---------|------|-------|
| `deploy` | 1000 | Operador admin, ejecuta provisioners | Si | Si |
| `infra` | 1001 | Sudo granular NOPASSWD por binario | Granular | Si |
| `develop` | 1002 | Owner del codigo del UI en `/srv/repos/tui/` | NO | Si |
| `svc-backups` | 999 | Backups del proyecto | NO | nologin |

Cuenta del referente **excluida**: `svc-dbdata` (UID 997) porque
no hay base de datos en scope.

Nginx corre con master `root` que fork-ea workers a `www-data`
(default Ubuntu). Los repos son `develop:develop` con perms
`755/644`, asi `www-data` (que es "other") puede leer.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {
  'background': '#0f172a',
  'primaryColor': '#1e293b',
  'primaryTextColor': '#f1f5f9',
  'primaryBorderColor': '#94a3b8',
  'lineColor': '#cbd5e1',
  'secondaryColor': '#334155',
  'fontSize': '13px'
}}}%%
flowchart LR
    subgraph subgraph_cuentas_linux["Cuentas Linux"]
        cuenta_deploy["<b>deploy</b><br/>UID 1000<br/>sudo"]
        cuenta_infra["<b>infra</b><br/>UID 1001<br/>sudo granular"]
        cuenta_develop["<b>develop</b><br/>UID 1002<br/>sin sudo"]
        cuenta_svc_backups["<b>svc-backups</b><br/>UID 999<br/>nologin"]
        cuenta_www_data["<b>www-data</b><br/>Nginx workers"]
    end

    subgraph subgraph_almacenamiento["Almacenamiento"]
        storage_clase_a_codigo[("Clase A<br/>/srv/repos/tui/<br/>template-ecommerce-ui<br/><i>755/644</i>")]
        storage_clase_b_backups[("Clase B<br/>/srv/backups/<br/>project<br/><i>755</i>")]
    end

    cuenta_develop -- "owner" --> storage_clase_a_codigo
    cuenta_svc_backups -- "owner" --> storage_clase_b_backups
    cuenta_www_data -- "lee como 'other'" --> storage_clase_a_codigo
    cuenta_deploy -- "ejecuta provisioners" --> cuenta_infra
```

### Componente 5: clases de almacenamiento

Dos clases (en lugar de las tres del referente):

| Clase | Path | Owner / perms | Contenido |
|-------|------|---------------|-----------|
| A | `/srv/repos/tui/template-ecommerce-ui` | `develop:develop` 755/644 | Codigo del UI |
| B | `/srv/backups/project` | `svc-backups:svc-backups` 755 | Backups del proyecto |

Clase C del referente (`/srv/backups/database`) **excluida** por
la misma razon que `svc-dbdata`.

## Decisiones arquitectonicas aprobadas

Estas son las **6 decisiones aprobadas al abrir la iniciativa**
(ver [alcance de la iniciativa][doc-alcance]):

| ID | Decision | Resumen |
|----|----------|---------|
| D-WS | Nginx en lugar de Apache | Catch-all SPA en 1 linea, reverse proxy nativo, footprint menor, agnostic a tecnologia backend. Justificacion en el [analisis previo del UI][analisis-ui]. |
| D-CUENTAS | 4 cuentas Linux (sin `svc-dbdata`) | No hay BD en scope. |
| D-STORAGE | 2 clases (A, B) sin C | Idem. |
| D-NOMBRE | `template-ecommerce-server` sin guion entre `e` y `comerce` | Decision explicita del usuario. Asimetria intencional vs [`template-ecommerce-ui`][repo-ui] que tiene guion. |
| D-BACKEND-AGNOSTIC | El server NO asume tecnologia backend | `$API_UPSTREAM` es variable de entorno; vacio por defecto. Si la API no esta, `/api/*` devuelve 502 hasta configurar. |
| D-PROVISIONER-PATTERN | Heredar patron shell idempotente con placeholders `%%VAR%%` del referente | Probado en [`jcg-admin/e-comerce-server`][ref-ecomerce-server], reutilizable. |

ADRs detallados para D-WS, D-CUENTAS, D-STORAGE pendientes en
F0a (validaciones iniciales). Viviran en [`docs/desarrollo/`][doc-desarrollo].

## Flujos importantes

### Flujo 1: aprovisionar el server desde cero

```mermaid
%%{init: {'theme':'base', 'themeVariables': {
  'background': '#0f172a',
  'primaryColor': '#1e293b',
  'primaryTextColor': '#f1f5f9',
  'primaryBorderColor': '#94a3b8',
  'lineColor': '#cbd5e1',
  'secondaryColor': '#334155',
  'actorBorder': '#60a5fa',
  'actorBkg': '#1e3a8a',
  'actorTextColor': '#f1f5f9',
  'fontSize': '13px'
}}}%%
sequenceDiagram
    actor Operador_deploy as Operador (deploy)
    participant Script_setup as scripts/setup.sh
    participant Provisioners as provisioners/
    participant Sistema_Ubuntu as Ubuntu 24.04
    participant Lets_Encrypt_CA as Let's Encrypt

    Operador_deploy->>Script_setup: git clone + cp .env.example .env
    Operador_deploy->>Script_setup: sudo bash scripts/setup.sh
    Note over Script_setup: Fase 1
    Script_setup->>Provisioners: nginx/install.sh
    Provisioners->>Sistema_Ubuntu: apt install nginx
    Script_setup->>Provisioners: security/setup_ssh_hardening.sh
    Provisioners->>Sistema_Ubuntu: Cambia puerto SSH a SSH_PORT
    Script_setup-->>Operador_deploy: PAUSA Reconecta en SSH_PORT

    Note over Operador_deploy,Script_setup: Operador reconecta SSH en nuevo puerto

    Operador_deploy->>Script_setup: sudo bash scripts/setup.sh --continue
    Note over Script_setup: Fase 2
    Script_setup->>Provisioners: firewall/setup_firewall.sh
    Provisioners->>Sistema_Ubuntu: UFW activo
    Script_setup->>Provisioners: security/setup_fail2ban.sh
    Provisioners->>Sistema_Ubuntu: fail2ban con 3 jails
    Script_setup->>Provisioners: ssl/setup_ssl.sh
    Provisioners->>Lets_Encrypt_CA: ACME HTTP-01 challenge
    Lets_Encrypt_CA-->>Provisioners: Cert emitido
    Script_setup->>Provisioners: nginx/setup_vhost.sh
    Provisioners->>Sistema_Ubuntu: Vhosts HTTP + HTTPS activos
    Script_setup->>Script_setup: scripts/verify.sh
    Script_setup-->>Operador_deploy: 12 checks OK
```

Detalle completo en [`docs/operaciones.md`][doc-operaciones].
Flags disponibles: `bash scripts/setup.sh --help`.

### Flujo 2: peticion del usuario al sitio en produccion

```mermaid
%%{init: {'theme':'base', 'themeVariables': {
  'background': '#0f172a',
  'primaryColor': '#1e293b',
  'primaryTextColor': '#f1f5f9',
  'primaryBorderColor': '#94a3b8',
  'lineColor': '#cbd5e1',
  'secondaryColor': '#334155',
  'fontSize': '13px'
}}}%%
flowchart TD
    usuario_navegador([Usuario en browser])
    resolucion_dns{{DNS resolve}}
    nginx_web_server["<b>Nginx :443</b>"]
    handshake_ssl[/"SSL handshake<br/>Let's Encrypt cert"/]
    routing_por_path{Routing por path}
    respuesta_asset_estatico["<b>Asset estatico</b><br/>/main.abc123.js<br/>Cache 1 year"]
    respuesta_spa_indexhtml["<b>SPA catch-all</b><br/>/cart, /checkout<br/>sirve index.html"]
    respuesta_reverse_proxy["<b>Reverse proxy</b><br/>/api/* → $API_UPSTREAM"]
    headers_de_seguridad_anadidos["Headers de seguridad<br/>HSTS, X-Frame-Options"]

    usuario_navegador --> resolucion_dns
    resolucion_dns --> nginx_web_server
    nginx_web_server --> handshake_ssl
    handshake_ssl --> routing_por_path
    routing_por_path -->|extension de asset| respuesta_asset_estatico
    routing_por_path -->|sin extension| respuesta_spa_indexhtml
    routing_por_path -->|/api/*| respuesta_reverse_proxy
    respuesta_asset_estatico --> headers_de_seguridad_anadidos
    respuesta_spa_indexhtml --> headers_de_seguridad_anadidos
    respuesta_reverse_proxy --> headers_de_seguridad_anadidos
    headers_de_seguridad_anadidos --> usuario_navegador

    classDef primaryNode fill:#1e293b,stroke:#60a5fa,stroke-width:2px,color:#f1f5f9
    classDef decisionNode fill:#334155,stroke:#94a3b8,stroke-width:1px,color:#f1f5f9
    classDef userNode fill:#1e3a8a,stroke:#60a5fa,stroke-width:2px,color:#f1f5f9

    class nginx_web_server,respuesta_asset_estatico,respuesta_spa_indexhtml,respuesta_reverse_proxy,headers_de_seguridad_anadidos primaryNode
    class routing_por_path,resolucion_dns,handshake_ssl decisionNode
    class usuario_navegador userNode
```

### Flujo 3: renovacion automatica de SSL

```mermaid
%%{init: {'theme':'base', 'themeVariables': {
  'background': '#0f172a',
  'primaryColor': '#1e293b',
  'primaryTextColor': '#f1f5f9',
  'primaryBorderColor': '#94a3b8',
  'lineColor': '#cbd5e1',
  'secondaryColor': '#334155',
  'actorBorder': '#60a5fa',
  'actorBkg': '#1e3a8a',
  'actorTextColor': '#f1f5f9',
  'fontSize': '13px'
}}}%%
sequenceDiagram
    participant Cron_diario as Cron diario
    participant Script_renew_ssl as renew_ssl.sh
    participant Cliente_ACME_sh as acme.sh
    participant Servidor_Nginx as Nginx
    participant Lets_Encrypt_CA as Let's Encrypt

    Cron_diario->>Script_renew_ssl: Ejecucion programada
    Script_renew_ssl->>Cliente_ACME_sh: Verificar expiracion < 30 dias?
    alt Si por expirar
        Cliente_ACME_sh->>Lets_Encrypt_CA: ACME HTTP-01 challenge
        Note over Servidor_Nginx,Lets_Encrypt_CA: Nginx sirve token en<br/>/.well-known/acme-challenge/<br/>(vhost :80 tiene excepcion)
        Lets_Encrypt_CA-->>Cliente_ACME_sh: Valida dominio
        Lets_Encrypt_CA-->>Cliente_ACME_sh: Cert renovado emitido
        Cliente_ACME_sh->>Cliente_ACME_sh: Instalar cert en $SSL_CERT_DIR<br/>con permisos canonicos
        Script_renew_ssl->>Servidor_Nginx: systemctl reload nginx
        Servidor_Nginx-->>Script_renew_ssl: Toma nuevo cert sin downtime
    else No por expirar
        Cliente_ACME_sh-->>Script_renew_ssl: Nada que hacer
    end
```

## Lo que el server NO hace

Para evitar ambiguedad:

- **No es un backend API**. Reverse-proxy hacia uno, no
  implementa uno.
- **No gestiona base de datos**. Cero scripts de DB; cero
  `svc-dbdata`.
- **No monitoriza**. Solo `verify.sh` puntual.
- **No despliega**. El operador clona el repo del UI y ejecuta
  `npm run build` manualmente o con su sistema CI/CD; este repo
  no automatiza ese paso.
- **No gestiona DNS**. Asume que el dominio esta apuntando al IP
  del server.
- **No incluye CI/CD propio**. Posible iniciativa futura.

## Diferencias con el referente

Tabla rapida vs [`jcg-admin/e-comerce-server`][ref-ecomerce-server]:

| Aspecto | Referente | Este repo |
|---------|-----------|-----------|
| Web server | Apache 2.4 + mod_wsgi | **Nginx 1.24+** |
| Backend | Django (acoplado) | **Externo, `$API_UPSTREAM`** |
| SPA catch-all | Django `serve_spa` view | **Nginx `try_files /index.html`** |
| Modelo cuentas | 5 | **4** (sin `svc-dbdata`) |
| Storage classes | A, B, C | **A, B** (sin C) |
| fail2ban jails | sshd + apache-auth | **sshd + nginx-*** |
| LOC bash estimadas | ~3500 | **~2800** |

## Referencias

- Decisiones detalladas: [alcance de la iniciativa][doc-alcance].
- Analisis previo que motivo esta arquitectura:
  [analisis-servidor-para-template.md][analisis-ui] (en el repo
  UI, commit `7110527`).
- Repo de referencia: [`jcg-admin/e-comerce-server`][ref-ecomerce-server].
- Procedimiento externo de almacenamiento:
  `Procedimiento-Implementacion-Almacenamiento-WSL2-ecomerce-p001 v1.0.0`.
- Glosario de terminos: [glosario][doc-glosario].

<!-- Referencias Markdown (link references) -->
[doc-alcance]: pm/iniciativas/crear-template-ecomerce-ui-server/alcance-crear-template-ecomerce-ui-server.md
[doc-operaciones]: operaciones.md
[doc-seguridad]: seguridad.md
[doc-desarrollo]: desarrollo/index.md
[doc-glosario]: glosario.md
[analisis-ui]: https://github.com/jcg-admin/template-ecommerce-ui/blob/main/docs/desarrollo/analisis-servidor-para-template.md
[repo-ui]: https://github.com/jcg-admin/template-ecommerce-ui
[ref-ecomerce-server]: https://github.com/jcg-admin/e-comerce-server
