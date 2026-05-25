# Analisis — `crear-start-sh`

## Inventario del estado actual

### Scripts existentes en `scripts/`

| Archivo | Proposito |
|---------|-----------|
| `scripts/setup.sh` | Aprovisionamiento en dos fases |
| `scripts/verify.sh` | Verificacion del entorno (12 checks) |
| `scripts/renew_ssl.sh` | Renovacion periodica de SSL |

`scripts/start.sh` no existe.

### Helpers disponibles en `utils/core.sh`

`start.sh` puede reutilizar directamente:

| Funcion | Comportamiento con systemd | Comportamiento sin systemd |
|---------|---------------------------|----------------------------|
| `svc_is_active nginx` | `systemctl is-active nginx` | `service nginx status` |
| `svc_start nginx` | `systemctl start nginx` | `/usr/sbin/nginx` |
| `svc_is_active fail2ban` | `systemctl is-active fail2ban` | `service fail2ban status` |
| `svc_start fail2ban` | `systemctl start fail2ban` | `fail2ban-server -b` |
| `is_systemd` | Retorna 0 (true) | Retorna 1 (false) |
| `command_exists` | Guards de prerequisito | Guards de prerequisito |

Estos wrappers encapsulan completamente la logica de deteccion
de entorno. `start.sh` no necesita invocar comandos nativos
directamente.

### Daemons a arrancar

| Daemon | Comando sin systemd | Nota |
|--------|--------------------|----|
| Nginx | `/usr/sbin/nginx` (via `svc_start nginx`) | Master hace fork a workers automaticamente |
| fail2ban | `fail2ban-server -b` (via `svc_start fail2ban`) | `-b` = background |

`sshd` excluido por D-NO-SSHD.

## Diagrama de flujo de `start.sh`

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
    inicio([start.sh invocado])
    check_sudo{"Corre con\nsudo o root?"}
    error_sudo(["ERROR: requiere sudo"])
    start_nginx["_start_daemon nginx"]
    start_fail2ban["_start_daemon fail2ban"]
    resumen["Imprimir resumen\nde estado"]
    fin_ok(["Daemons activos"])

    check_instalado{"daemon\ninstalado?"}
    warn_no_instalado["WARN: no instalado\nomitir"]
    check_activo{"daemon ya\ncorriendo?"}
    info_ya_activo["INFO: ya activo\nomitir"]
    arrancar["svc_start daemon"]
    check_arranque{"arranque\nexitoso?"}
    ok_arrancado["OK: daemon arrancado"]
    error_arranque(["ERROR: fallo al arrancar"])

    inicio --> check_sudo
    check_sudo -->|NO| error_sudo
    check_sudo -->|SI| start_nginx
    start_nginx --> start_fail2ban
    start_fail2ban --> resumen
    resumen --> fin_ok

    check_instalado -->|NO| warn_no_instalado
    check_instalado -->|SI| check_activo
    check_activo -->|SI| info_ya_activo
    check_activo -->|NO| arrancar
    arrancar --> check_arranque
    check_arranque -->|SI| ok_arrancado
    check_arranque -->|NO| error_arranque

    classDef primaryNode fill:#1e293b,stroke:#60a5fa,stroke-width:2px,color:#f1f5f9
    classDef errorNode fill:#7f1d1d,stroke:#f87171,stroke-width:2px,color:#fef2f2
    classDef okNode fill:#14532d,stroke:#4ade80,stroke-width:2px,color:#f0fdf4
    classDef warnNode fill:#78350f,stroke:#fb923c,stroke-width:2px,color:#fff7ed
    classDef decisionNode fill:#334155,stroke:#94a3b8,stroke-width:1px,color:#f1f5f9

    class inicio,start_nginx,start_fail2ban,arrancar,resumen primaryNode
    class error_sudo,error_arranque errorNode
    class fin_ok,ok_arrancado okNode
    class warn_no_instalado,info_ya_activo warnNode
    class check_sudo,check_instalado,check_activo,check_arranque decisionNode
```

## Validacion de no-colisiones

`start.sh` no modifica ningun archivo de configuracion.
Solo invoca wrappers de `core.sh` que internamente llaman
a los binarios o a systemd. `test_provisioner_syntax.sh`
cubre automaticamente `start.sh` sin modificacion.

## Estrategia de ejecucion

Una funcion privada `_start_daemon <nombre>` encapsula el
flujo: verificar instalacion, verificar si ya corre, arrancar
si es necesario, reportar resultado. El MAIN la invoca dos
veces: primero para nginx, luego para fail2ban.

## Riesgos identificados

| ID | Riesgo | Mitigacion |
|----|--------|------------|
| R-1 | `svc_is_active` retorna falso positivo en WSL2 para un daemon que arranco pero fallo | Despues de `svc_start`, el script verifica de nuevo con `svc_is_active` para confirmar que el daemon esta realmente activo |
| R-2 | fail2ban no puede arrancar si nginx no esta corriendo (las jails nginx-* monitorizan logs de nginx) | El script arranca nginx primero; fail2ban se arranca despues. El orden esta documentado y es fijo. |

## Conclusion

`start.sh` es el script mas simple de esta serie. Toda la
complejidad de deteccion de entorno ya vive en `core.sh`.
El unico riesgo no trivial (R-1, falso positivo de
`svc_is_active`) se mitiga con una segunda verificacion
post-arranque. La implementacion es de muy bajo riesgo.
