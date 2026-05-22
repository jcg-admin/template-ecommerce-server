# Operacion sin systemd — WSL2, contenedores y CI

| Campo | Valor |
|-------|-------|
| Documento | Comportamiento de los provisioners cuando systemd NO esta disponible. |
| Estado | **Completo** (cerrado en F10/T-1002). |
| Audiencia | Operadores y devs que ejecuten el repo en entornos sin systemd. |

---

## Por que existe este documento

Los provisioners del repo asumen Ubuntu 24.04 con systemd como
init system. En esos entornos `systemctl start nginx`, `systemctl
status fail2ban`, etc funcionan tal cual.

Pero hay 3 escenarios donde systemd no esta disponible o no es
funcional:

1. **WSL2 sin systemd activado**: el default historico de WSL2
   en Windows 10/11 no arrancaba systemd. Versiones recientes
   (WSL >= 0.67) lo soportan tras editar `/etc/wsl.conf`.
2. **Contenedores Docker / Podman**: ejecutar provisioners
   dentro de un contenedor Ubuntu para testing. No hay init
   system real.
3. **CI runners**: GitHub Actions, GitLab CI, Buildkite -- el
   runner suele ejecutar steps en contenedores efimeros.

Los provisioners detectan estos casos via `is_systemd()` de
`utils/core.sh` y aplican comportamiento alternativo. Este
documento describe **exactamente que pasa en cada escenario**
para que el operador no se sorprenda.

---

## Funcion clave: `is_systemd()`

Definida en `utils/core.sh`. Retorna:

- **0 (true)** si:
  - `/run/systemd/system/` existe (esto solo lo crea systemd al
    arrancar), Y
  - `systemctl` esta disponible en PATH, Y
  - `systemctl is-system-running --quiet` retorna codigo 0 o el
    estado es "running"/"degraded" (no "offline").

- **1 (false)** en cualquier otro caso.

Los provisioners usan esta funcion para 2 cosas distintas:

1. **Branch de `svc_*` wrappers**: `svc_start nginx` usa
   `systemctl start nginx` con systemd; sin systemd usa el
   comando equivalente del binario (`nginx`, `fail2ban-server
   -b`, etc).
2. **Skip de pasos que dependen del daemon corriendo**:
   `_verify_jails` de `setup_fail2ban.sh` consulta
   `fail2ban-client status` que requiere socket runtime; sin
   systemd, ese socket no existe (daemon no arrancado) y el
   paso emite warn en lugar de fail.

---

## Comportamiento por provisioner

### `provisioners/nginx/install.sh`

| Paso | Con systemd | Sin systemd |
|------|-------------|-------------|
| `apt-get install nginx` | Igual | Igual |
| `nginx -t` post-install | Igual | Igual |
| `svc_enable nginx` | `systemctl enable nginx` | No-op |
| Start at boot | systemd | No (operador inicia manual) |

Output sin systemd: warn `Sin systemd detectado -- ejecutar
manualmente: nginx` al final del script.

### `provisioners/nginx/setup_vhost.sh`

Funcionalidad idempotente identica. La diferencia es el reload
final: con systemd usa `systemctl reload nginx`; sin systemd
ejecuta `nginx -s reload` directamente (graceful, sin
downtime).

Si `nginx` no esta corriendo aun (escenario sin systemd y
sin arranque manual previo), el reload falla -- el script
emite warn pero el override esta aplicado y se cargara
cuando el operador arranque Nginx manualmente.

### `provisioners/ssl/setup_ssl.sh`

| Aspecto | Con systemd | Sin systemd |
|---------|-------------|-------------|
| `acme.sh --install-cronjob` | Configura cron | Si crontab disponible: configura; si no: warn |
| `--reloadcmd 'nginx -s reload'` | Funciona si Nginx corre | Idem; falla si Nginx no corre |
| Self-signed (modo `--dev`) | Funciona | Funciona (openssl no necesita systemd) |

### `provisioners/security/setup_fail2ban.sh`

Diferencia mayor:

| Paso | Con systemd | Sin systemd |
|------|-------------|-------------|
| `apt-get install fail2ban` | Igual | Igual |
| Escribir `jail.d/*.conf` | Igual | Igual |
| `svc_enable fail2ban` | `systemctl enable` | No-op |
| `svc_start fail2ban` | `systemctl start` | No-op (warn) |
| `_verify_jails` | `fail2ban-client status sshd` | SKIP con info |
| Validacion sintaxis | (implicita en start) | `fail2ban-client -d` |

Output sin systemd: la config queda escrita pero el daemon NO
arranca automaticamente. El script emite:
```
Sin systemd detectado -- omitiendo arranque del daemon.
Configuracion valida (fail2ban-client -d OK)
Arranque manual: fail2ban-server -b
```

El operador debe arrancar el daemon manualmente despues:
```bash
sudo fail2ban-server -b
sudo fail2ban-client status   # verificar
```

### `provisioners/security/setup_ssh_hardening.sh`

Diferencia interesante: el script funciona aun sin sshd
corriendo. Escribe el override en
`/etc/ssh/sshd_config.d/99-template-ecomerce-ui-server.conf`,
valida con `sshd -t`, pero NO recarga sshd si no detecta
PID. La config se aplicara cuando sshd arranque.

| Paso | Con systemd | Sin systemd y sshd corriendo | Sin systemd y sshd NO corriendo |
|------|-------------|------------------------------|----------------------------------|
| `_check_authorized_keys` | Igual | Igual | Igual (lockout guard) |
| `_apply_override` | Igual | Igual | Igual |
| `sshd -t` | Igual | Igual | Igual (requiere `/run/sshd/`) |
| Reload sshd | `systemctl reload sshd` | `kill -HUP $(cat /run/sshd.pid)` | SKIP (no PID) |

El paso 8 `sshd -t` requiere `/run/sshd/` existente. El script
lo crea con `mkdir -p /run/sshd` defensivamente para este caso.

### `provisioners/firewall/setup_firewall.sh`

UFW interactua con netfilter (kernel). En contenedores que
NO comparten el host kernel namespace (poco frecuente con
Docker default), UFW puede no funcionar. En WSL2 funciona
porque comparte el kernel del host.

| Aspecto | Comportamiento |
|---------|----------------|
| `apt-get install ufw` | Igual |
| `ufw --force enable` | Funciona si el kernel soporta netfilter |
| `ufw default deny incoming` | Idem |
| `ufw allow $PORT/tcp` | Idem |
| Persistencia entre reboots | Solo con systemd; sin systemd hay que `ufw enable` cada vez |

En contenedores efimeros (CI runners) el script tipicamente
emitira warn sobre persistencia pero las reglas se aplicaran
durante la sesion.

### `scripts/verify.sh`

Cada check inspecciona si el entorno aplica. Comportamiento por
check sin systemd:

| Check | Sin systemd |
|-------|-------------|
| 1. `.env` vars | Idem (no requiere systemd) |
| 2. Nginx version | Idem |
| 3. Nginx :80 | Idem (`tcp_is_reachable`) |
| 4. SSL :443 | Idem |
| 5. SSL cert | Idem |
| 6. API upstream | Idem (curl) |
| 7. Redirect HTTP->HTTPS | Idem |
| 8. SPA catch-all | Idem |
| 9. UFW | Idem (`ufw status`) |
| 10. Min privilege | Idem (`stat` + `ps`) |
| 11. fail2ban | WARN ("fail2ban corriendo -- jails no verificadas") |
| 12. SSH hardening | Idem (`sshd -T`) |

---

## Habilitar systemd en WSL2

Si tu WSL2 es version >= 0.67 (verificar con `wsl.exe --version`
en PowerShell), puedes habilitar systemd:

```bash
# Dentro de WSL2:
sudo tee /etc/wsl.conf << 'EOF'
[boot]
systemd=true
EOF
```

Luego, en PowerShell de Windows:
```powershell
wsl --shutdown
# Esperar 8 segundos, reabrir el terminal WSL
```

Tras reabrir:
```bash
systemctl is-system-running
# Si retorna "running" o "degraded" -> systemd ok
```

Si retorna "offline" o el comando no existe, hay versiones
viejas de WSL que no soportan systemd. Upgrade desde Microsoft
Store o `wsl --update`.

---

## Habilitar systemd en contenedores

NO recomendado para casos de uso normales (los provisioners
estan disenados para tolerar la ausencia). Si aun asi quieres
correr systemd en un contenedor, necesitas:

- Imagen base con systemd: `jrei/systemd-ubuntu:24.04` u otra
  equivalente.
- Flags al ejecutar: `--privileged` + montar `/sys/fs/cgroup`.

Ejemplo Docker (entornos de testing solo):

```bash
docker run --privileged -it \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    --cap-add SYS_ADMIN \
    jrei/systemd-ubuntu:24.04 \
    /lib/systemd/systemd
```

Para CI, lo correcto es:

- Usar runners con sistema "fat" (no containerized) cuando
  necesites systemd, o
- Cambiar los tests para que NO dependan de systemd (que es
  exactamente lo que hacen los provisioners de este repo:
  detectan y degradan correctamente).

---

## Como saber rapido si tu entorno tiene systemd

```bash
# Una linea:
bash -c 'source utils/core.sh && is_systemd && echo SI || echo NO'
```

Resultados esperados:

| Entorno | Resultado |
|---------|-----------|
| Ubuntu 24.04 VPS / bare-metal | SI |
| WSL2 con `systemd=true` | SI |
| WSL2 sin `systemd=true` | NO |
| Docker Ubuntu plain | NO |
| Docker `jrei/systemd-ubuntu` con `--privileged` | SI |
| GitHub Actions ubuntu-latest runner | SI (runner es VM) |
| GitHub Actions con container: image: ubuntu | NO (container) |

---

## Resumen ejecutivo

- Los provisioners detectan systemd via `is_systemd()` y degradan
  funcionalmente cuando no esta.
- En entornos sin systemd, el operador debe arrancar los daemons
  manualmente (`nginx`, `fail2ban-server -b`).
- WSL2 puede habilitar systemd via `/etc/wsl.conf`.
- Contenedores: NO recomendado intentar systemd; el repo
  funciona sin el.
- `verify.sh` reporta warnings (no errores) para los checks que
  dependen de daemons corriendo cuando el daemon no esta.

<!-- Referencias Markdown -->
[doc-operaciones]: operaciones.md
[doc-arquitectura]: arquitectura.md
