# ADR — Decision D-WS: Nginx en lugar de Apache

| Campo | Valor |
|-------|-------|
| ID | D-WS |
| Estado | **Aceptada** |
| Fecha de decision | 2026-05-21 |
| Decididor | Nestor Monroy (autor del repo) |
| Fase | F0a — Validaciones iniciales |
| Iniciativa | [crear-template-ecomerce-ui-server][doc-iniciativa] |

## Contexto

El repo de referencia [`jcg-admin/e-comerce-server`][ref-ecomerce-server]
usa **Apache 2.4 + mod_wsgi** para servir una arquitectura
**3-tier** (server + api Django + ui React). En su README
declara: "Provisiona Apache 2.4 con mod_wsgi para el API
Django, servicio de archivos estaticos del UI React,
terminacion SSL...".

Nuestro repo `template-ecomerce-ui-server` se inspira en ese
referente pero tiene **un contexto distinto**:

- **No incluye backend**. La decision aprobada D-BACKEND-AGNOSTIC
  establece que `$API_UPSTREAM` es una variable de entorno; el
  server no sabe ni decide la tecnologia del backend.
- **Sirve un UI React** que es un SPA con React Router.
- **Reverse-proxy a un upstream externo** es la operacion
  principal del server.

La pregunta: ¿continuamos con Apache (por inercia del referente)
o cambiamos a Nginx?

## Decision

**Adoptar Nginx 1.24+** como web server del repo.

## Alternativas evaluadas

### Alternativa 1: Apache 2.4 + mod_wsgi (descartada)

**Pro**:

- **Familiaridad del usuario**: el referente lo usa, el
  patron de scripts ya esta probado.
- **mod_wsgi**: si alguna vez se quiere embeber un backend
  Python directamente, Apache lo soporta nativo.

**Contra**:

- **SPA catch-all complicado**: en Apache, para que las rutas
  del SPA (`/cart`, `/checkout`, etc.) devuelvan `index.html`,
  hace falta acoplamiento con el backend. El referente lo
  resuelve con una vista `serve_spa` en Django. **Sin Django,
  ese acoplamiento se rompe**.
- **mod_wsgi pierde valor**: sin backend Python, mod_wsgi es
  codigo muerto. Pierde el unico diferenciador sustancial vs
  Nginx.
- **Footprint mayor**: ~25 MB por worker en pre-fork mode.
- **Configuracion verbosa**: el `<VirtualHost>`, `<Directory>`,
  `<Files>`, etc., son mas tokens que la equivalente en Nginx.

### Alternativa 2: Nginx 1.24+ (elegida)

**Pro**:

- **SPA catch-all en 1 linea**: `try_files $uri $uri/ /index.html;`.
  Sin acoplamiento con backend.
- **Reverse proxy nativo**: `proxy_pass $API_UPSTREAM;`
  directamente, sin modulos adicionales.
- **Footprint menor**: ~10 MB por worker. Importante para
  hosting economico.
- **Performance superior en static files**: event-driven, mejor
  serving de chunks pequenos de webpack.
- **Agnostic a tecnologia backend**: con `proxy_pass` apuntando
  a `$API_UPSTREAM`, da igual si el backend es Django, Node,
  Go o lo que sea.
- **Documentacion abundante** para patrones SPA + reverse
  proxy en la comunidad.
- **HTTP/2 nativo** sin modulos adicionales.

**Contra**:

- **No tenemos ejemplo bash del referente para Nginx**: hay que
  reescribir `setup_vhost.sh` y `install.sh` desde cero
  (vs portar 1:1 desde Apache). Riesgo cuantificado en el
  [plan F4][doc-plan].
- **No embebe Python**: si en el futuro se decide servir un
  backend Python en el mismo server, habria que anadir
  gunicorn/uWSGI como proceso separado. **Pero D-BACKEND-AGNOSTIC
  ya excluye esto del scope**.

### Alternativa 3: Caddy 2.x (evaluada y descartada)

**Pro**:

- HTTPS automatico (sin acme.sh manual).
- Configuracion declarativa muy concisa (`Caddyfile`).
- Reverse proxy + SPA catch-all triviales.

**Contra**:

- **Apt repository menos estandar** en Ubuntu 24.04 (requiere
  PPA externo o snap).
- **Comunidad menor**: menos docs cuando algo se rompe en
  produccion.
- **Diferencia conceptual mayor vs el referente**: el patron
  de `%%VAR%%` placeholder no aplica igual; tendriamos que
  reinventar el patron de provisioning.
- **acme.sh ya nos da renovacion automatica** sin depender de
  Caddy.

## Consecuencias

### Positivas

- **Codigo mas simple** en el vhost: el SPA catch-all es 1
  linea en lugar de una vista en el backend.
- **Reverse proxy declarativo**: `proxy_pass $API_UPSTREAM`
  como API publica del server.
- **Portable**: si el usuario cambia de backend (Django -> Node),
  el server no requiere cambios.
- **Performance mejor** en serving del SPA.

### Negativas

- **No podemos copiar 1:1** los scripts de Apache del referente.
  Adaptarlos a Nginx requiere trabajo en F4. Estimado en 120
  min de la fase.
- **Si en el futuro se quiere embeber un backend Python**, no
  basta Nginx; habria que anadir gunicorn como proceso separado
  + proxy_pass via socket Unix. Trade-off aceptado.

### Mitigaciones de las negativas

- F4 ya planifica el trabajo de reescritura como dos tareas
  separadas (`install.sh`, `setup_vhost.sh`).
- Tests bash en F9 cubren el riesgo de regresion.

## Implementacion

- F4: implementar `provisioners/nginx/install.sh` y
  `setup_vhost.sh`.
- F3: implementar `config/nginx/template-http.conf` y
  `template-https.conf` con placeholders.
- F6: `fail2ban` jails adaptados a `nginx-limit-req` y
  `nginx-botsearch` (en lugar de `apache-auth` del referente).
- F8: `scripts/verify.sh` valida estado de Nginx.

## Referencias

- Analisis previo que motivo esta decision:
  [analisis-servidor-para-template.md][analisis-ui] en el repo
  UI (seccion "Decision arquitectonica: Apache vs Nginx").
- Repo de referencia con Apache: [`jcg-admin/e-comerce-server`][ref-ecomerce-server].
- Documentacion Nginx oficial: <https://nginx.org/en/docs/>.
- Comparativa de performance: ver fuentes en el analisis
  previo, tabla "Apache vs Nginx" lado a lado.

<!-- Referencias Markdown -->
[doc-iniciativa]: ../pm/iniciativas/crear-template-ecomerce-ui-server/index.md
[doc-plan]: ../pm/iniciativas/crear-template-ecomerce-ui-server/plan-crear-template-ecomerce-ui-server.md
[ref-ecomerce-server]: https://github.com/jcg-admin/e-comerce-server
[analisis-ui]: https://github.com/jcg-admin/template-e-comerce-ui/blob/main/docs/desarrollo/analisis-servidor-para-template.md
