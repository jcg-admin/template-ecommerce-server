# Analisis — `crear-setup-sh`

## Inventario del estado actual

### Scripts existentes en `scripts/`

| Archivo | LOC | Proposito |
|---------|-----|-----------|
| `scripts/verify.sh` | ~350 | Verificacion del entorno (12 checks) |
| `scripts/renew_ssl.sh` | ~120 | Renovacion periodica de SSL |

`scripts/setup.sh` no existe. Tampoco `scripts/start.sh`.

### Provisioners existentes y orden critico

El orden de ejecucion NO es arbitrario. Las dependencias son:

| Paso | Script | Depende de |
|------|--------|------------|
| 1 | `provisioners/nginx/install.sh` | Ninguno |
| 2 | `provisioners/security/setup_ssh_hardening.sh` | Paso 1 (define SSH_PORT efectivo antes que UFW) |
| 3 | `provisioners/firewall/setup_firewall.sh` | Paso 2 (UFW permite SSH_PORT; si se activa antes, lockout) |
| 4 | `provisioners/security/setup_fail2ban.sh` | Paso 3 (banaction=ufw requiere UFW activo) |
| 5 | `provisioners/ssl/setup_ssl.sh` | Paso 1 (nginx instalado para ACME challenge) |
| 6 | `provisioners/nginx/setup_vhost.sh` | Paso 5 (cert SSL debe existir para vhost HTTPS) |
| 7 | `scripts/verify.sh` | Pasos 1-6 completos |

### Helpers disponibles en `utils/`

`setup.sh` puede sourcer los mismos utils que usan los provisioners:

| Funcion | Archivo | Uso en setup.sh |
|---------|---------|-----------------|
| `is_systemd()` | `core.sh` | Detectar entorno para mensajes |
| `command_exists()` | `core.sh` | Verificar que nginx esta instalado (guard Fase 2) |
| `log_header()`, `log_info()`, `log_success()`, `log_error()`, `log_warn()` | `logging.sh` | Output estructurado |

### Problema central: lockout SSH

`setup_ssh_hardening.sh` escribe
`/etc/ssh/sshd_config.d/99-template-ecommerce-server.conf`
con el nuevo `SSH_PORT` y recarga sshd. A partir de ese
momento el servidor solo acepta conexiones en el nuevo
puerto. Si `setup_firewall.sh` se ejecuta inmediatamente
despues (mismo proceso), UFW activa `deny incoming` y permite
solo el nuevo puerto — cortando la sesion SSH activa si el
operador no ha reconectado.

La unica solucion segura es pausar entre paso 2 y paso 3,
dar instrucciones de reconexion al operador, y retomar con
un flag.

## Diagrama de flujo de decision de `setup.sh`

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
    inicio([setup.sh invocado])
    parse_flags["Parsear flags\n--continue --skip-ssh\n--ssl-dev --ssl-staging"]
    check_flags_invalidos{"Combinacion\nde flags\ninvalida?"}
    error_flags(["ERROR: flags incompatibles"])
    check_sudo{"Corre con sudo\no como root?"}
    error_sudo(["ERROR: requiere sudo"])
    check_env{"¿.env existe?"}
    error_env(["ERROR: cp .env.example .env\nprimero"])
    check_vars{"Variables\nrequeridas\npresentes?"}
    error_vars(["ERROR: var faltante en .env"])
    flag_continue{"--continue?"}
    arrancar_fase2(["Arrancar Fase 2"])
    check_nginx_instalado{"nginx\ninstalado?\n(guard Fase 2)"}
    error_no_fase1(["ERROR: ejecuta Fase 1 primero\n(sin --continue)"])
    check_ssh_key{"Clave SSH en\nauthorized_keys?"}
    error_ssh_key(["ERROR: agrega clave SSH\nantes de continuar"])
    step_nginx["nginx/install.sh"]
    flag_skip_ssh{"--skip-ssh?"}
    step_ssh["setup_ssh_hardening.sh"]
    pausa(["PAUSA\nReconecta en puerto SSH_PORT\nluego: setup.sh --continue"])
    step_firewall["setup_firewall.sh"]
    step_fail2ban["setup_fail2ban.sh"]
    step_ssl["setup_ssl.sh\n[--dev / --staging / prod]"]
    step_vhost["setup_vhost.sh"]
    step_verify["verify.sh"]
    fin_ok(["Server operativo"])

    inicio --> parse_flags
    parse_flags --> check_flags_invalidos
    check_flags_invalidos -->|"SI"| error_flags
    check_flags_invalidos -->|"NO"| check_sudo
    check_sudo -->|"NO"| error_sudo
    check_sudo -->|"SI"| check_env
    check_env -->|"NO"| error_env
    check_env -->|"SI"| check_vars
    check_vars -->|"FAIL"| error_vars
    check_vars -->|"OK"| flag_continue
    flag_continue -->|"SI"| arrancar_fase2
    arrancar_fase2 --> check_nginx_instalado
    check_nginx_instalado -->|"NO"| error_no_fase1
    check_nginx_instalado -->|"SI"| step_firewall
    flag_continue -->|"NO"| check_ssh_key
    check_ssh_key -->|"NO"| error_ssh_key
    check_ssh_key -->|"SI"| step_nginx
    step_nginx --> flag_skip_ssh
    flag_skip_ssh -->|"SI"| step_firewall
    flag_skip_ssh -->|"NO"| step_ssh
    step_ssh --> pausa
    step_firewall --> step_fail2ban
    step_fail2ban --> step_ssl
    step_ssl --> step_vhost
    step_vhost --> step_verify
    step_verify --> fin_ok

    classDef primaryNode fill:#1e293b,stroke:#60a5fa,stroke-width:2px,color:#f1f5f9
    classDef errorNode fill:#7f1d1d,stroke:#f87171,stroke-width:2px,color:#fef2f2
    classDef warnNode fill:#78350f,stroke:#fb923c,stroke-width:2px,color:#fff7ed
    classDef okNode fill:#14532d,stroke:#4ade80,stroke-width:2px,color:#f0fdf4
    classDef decisionNode fill:#334155,stroke:#94a3b8,stroke-width:1px,color:#f1f5f9

    class inicio,parse_flags,step_nginx,step_ssh,step_firewall,step_fail2ban,step_ssl,step_vhost,step_verify primaryNode
    class error_flags,error_sudo,error_env,error_vars,error_ssh_key,error_no_fase1 errorNode
    class pausa warnNode
    class fin_ok,arrancar_fase2 okNode
    class check_flags_invalidos,check_sudo,check_env,check_vars,flag_continue,check_nginx_instalado,check_ssh_key,flag_skip_ssh decisionNode
```

## Diagrama de interaccion operador-script

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
    actor Op as Operador (deploy)
    participant S as setup.sh
    participant P as provisioners/
    participant U as Ubuntu 24.04
    participant L as Let's Encrypt

    Op->>S: sudo bash scripts/setup.sh
    S->>S: Validar flags + prerequisitos
    S->>P: nginx/install.sh
    P->>U: apt install nginx
    S->>P: security/setup_ssh_hardening.sh
    P->>U: Cambia puerto SSH a SSH_PORT
    S-->>Op: PAUSA Reconecta en puerto SSH_PORT

    Note over Op,S: Operador reconecta SSH en el nuevo puerto

    Op->>S: sudo bash scripts/setup.sh --continue
    S->>S: Validar prerequisitos + nginx instalado
    S->>P: firewall/setup_firewall.sh
    P->>U: UFW activo con puertos correctos
    S->>P: security/setup_fail2ban.sh
    P->>U: fail2ban con 3 jails activas
    S->>P: ssl/setup_ssl.sh
    P->>L: ACME HTTP-01 challenge
    L-->>P: Cert emitido
    S->>P: nginx/setup_vhost.sh
    P->>U: Vhosts HTTP y HTTPS activos
    S->>S: scripts/verify.sh
    S-->>Op: 12 checks OK — Server operativo
```

## Diagrama de estados del servidor

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
stateDiagram-v2
    [*] --> sin_provisionar: Ubuntu 24.04 limpio

    sin_provisionar --> nginx_instalado: install.sh OK
    nginx_instalado --> ssh_endurecido: ssh_hardening.sh OK
    ssh_endurecido --> en_pausa: PAUSA reconexion SSH

    en_pausa --> firewall_activo: --continue\nsetup_firewall.sh OK
    firewall_activo --> fail2ban_activo: setup_fail2ban.sh OK
    fail2ban_activo --> ssl_configurado: setup_ssl.sh OK
    ssl_configurado --> vhosts_activos: setup_vhost.sh OK
    vhosts_activos --> operativo: verify.sh 0 ERR

    nginx_instalado --> firewall_activo: --skip-ssh\nFase 1 sin hardening

    operativo --> [*]

    note right of en_pausa
        Reconectar SSH en SSH_PORT
        antes de invocar --continue
    end note

    note right of operativo
        Nginx sirviendo UI
        SSL activo
        fail2ban + UFW activos
        SSH endurecido (si aplica)
    end note
```

## Validacion de no-colisiones

`setup.sh` no modifica ningun archivo de configuracion
existente. Solo invoca provisioners como subprocesos.
Los provisioners son los que modifican el sistema; cada uno
tiene su propia logica de idempotencia y rollback.

`test_provisioner_syntax.sh` usa `find` sobre todos los `.sh`
del repo. Al agregar `scripts/setup.sh`, queda cubierto
automaticamente sin tocar el test.

## Estrategia de ejecucion

El script se construye en funciones privadas con prefijo `_`,
igual que los provisioners existentes. Sourcera
`utils/logging.sh` y `utils/core.sh` para usar los mismos
helpers de output y deteccion de entorno. El MAIN al final
parsea flags, llama guards, y despacha a `_run_fase1` o
`_run_fase2` segun corresponda.

## Riesgos identificados

| ID | Riesgo | Mitigacion |
|----|--------|------------|
| R-1 | Operador usa `--continue` sin haber ejecutado Fase 1 | Guard verifica que nginx este instalado (`command_exists nginx`) antes de Fase 2; si falla, aborta con instrucciones |
| R-2 | Combinacion invalida de flags (`--skip-ssh` + `--continue`) | `_parse_flags` detecta combinaciones invalidas y aborta antes de ejecutar nada |
| R-3 | `--ssl-dev` usado en servidor de produccion real | Advertencia visible si `DOMAIN` != `localhost`; el operador debe confirmar |
| R-4 | Guard de clave SSH no detecta la clave del usuario real | Documentado en usage: ejecutar como el usuario que tiene la clave SSH, no como otro usuario distinto |

## Conclusion

El unico problema de diseno no trivial es el lockout SSH,
y tiene solucion clara: dos fases con pausa y flag `--continue`.
El resto es orquestacion directa de provisioners existentes
reutilizando los helpers de `utils/`. La implementacion
es de bajo riesgo porque no modifica nada existente y los
provisioners individuales siguen siendo el mecanismo de
fallback si `setup.sh` no funciona en algun escenario.
