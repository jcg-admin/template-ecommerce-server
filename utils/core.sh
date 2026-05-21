#!/bin/bash
# =============================================================================
# utils/core.sh -- Funciones utilitarias core
#                  template-ecomerce-ui-server
# =============================================================================
# Portado desde jcg-admin/e-comerce-server/utils/core.sh con adaptaciones:
#   - Marca cambiada (PracticaYoruba-server -> template-ecomerce-ui-server)
#   - Wrappers svc_* adaptados: apache2 -> nginx en todas las ramas
#     (svc_start/stop/reload/restart)
#   - Funciones agnostic (command_exists, is_systemd, log_manual_start)
#     portadas 1:1
#
# Notas de adaptacion:
#   - Nginx control sin systemd:
#       start:   /usr/sbin/nginx
#       stop:    nginx -s quit       (graceful)
#       reload:  nginx -s reload     (config reload, no downtime)
#       restart: quit + start (no hay -s restart)
#   - nginx -t valida config ANTES de cualquier reload/restart; los
#     provisioners deben llamarlo explicitamente, no este utils.
#
# Depende de: logging.sh
#
# Provee:
#   command_exists <cmd>
#   require_command <cmd>
#   exists_file <path>
#   exists_dir  <path>
#   is_systemd
#   log_manual_start <servicio> <comando-manual>
#   svc_is_active <nombre>
#   svc_start    <nombre>
#   svc_stop     <nombre>
#   svc_reload   <nombre>
#   svc_restart  <nombre>
#   svc_enable   <nombre>
#
# Uso:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/core.sh"
# =============================================================================

# -----------------------------------------------------------------------------
# command_exists <cmd>
#   Retorna 0 si el comando existe en PATH, 1 si no.
# -----------------------------------------------------------------------------
command_exists() {
    command -v "$1" &>/dev/null
}

# -----------------------------------------------------------------------------
# require_command <cmd>
#   Igual que command_exists pero emite log_warn si el comando no existe.
# -----------------------------------------------------------------------------
require_command() {
    local cmd="$1"
    if ! command_exists "$cmd"; then
        log_warn "Comando no encontrado: ${cmd}"
        return 1
    fi
    return 0
}

exists_file() { [[ -f "$1" ]]; }
exists_dir()  { [[ -d "$1" ]]; }

# =============================================================================
# Deteccion de systemd
# =============================================================================
#
# is_systemd
#   Retorna 0 si el sistema corre con systemd como init (PID 1).
#   Retorna 1 en contenedores, entornos CI, WSL2 sin systemd, o sistemas
#   con otro init.
#
#   Estrategia (alineada con el referente jcg-admin/e-comerce-server):
#     1) /run/systemd/system existe -- indicador canonico del init.
#     2) systemctl existe en PATH.
#     3) systemctl puede consultar el bus (is-system-running o list-units
#        no fallan con "Host is down" / "Failed to connect to bus").
#   No basta con (1) o (2): en contenedores el binario existe pero falla
#   con "System has not been booted with systemd as init system".
# =============================================================================
is_systemd() {
    [[ -d /run/systemd/system ]] || return 1
    command -v systemctl >/dev/null 2>&1 || return 1
    if systemctl is-system-running --quiet 2>/dev/null \
            || systemctl list-units --type=service >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# =============================================================================
# log_manual_start <servicio> <comando-manual>
#   Emite un mensaje uniforme cuando no hay systemd para arrancar un
#   servicio. Centraliza el formato para que los provisioners lo reutilicen.
# =============================================================================
log_manual_start() {
    local name="$1"
    local cmd="$2"
    log_warn "  Sin systemd: '${name}' no se arrancara automaticamente."
    log_warn "  Arranque manual: ${cmd}"
}

# =============================================================================
# Wrappers de gestion de servicios -- systemd o fallback directo
#
# Todos los provisioners usan estas funciones en lugar de llamar
# systemctl directamente. Esto garantiza que los scripts funcionen
# correctamente en:
#   - VPS Ubuntu 24.04 con systemd (entorno objetivo de produccion)
#   - Contenedores Docker/LXC sin systemd (desarrollo, CI, pruebas)
#   - WSL2 con o sin systemd habilitado
#   - Entornos cloud-init donde systemd puede no estar completamente activo
#
# Convencion de nombres: svc_<accion> <nombre_servicio>
# Todos los wrappers propagan el codigo de salida de la herramienta usada.
# =============================================================================

# svc_is_active <nombre>
#   Retorna 0 si el servicio esta corriendo, 1 si no.
svc_is_active() {
    local name="$1"
    if is_systemd; then
        systemctl is-active --quiet "$name" 2>/dev/null
    else
        service "$name" status &>/dev/null
    fi
}

# svc_start <nombre>
#   Arranca el servicio. En modo sin-systemd usa la herramienta nativa
#   de cada servicio cuando 'service' no es suficiente.
svc_start() {
    local name="$1"
    if is_systemd; then
        systemctl start "$name" 2>/dev/null
    else
        case "$name" in
            nginx)
                # Sin systemd, arrancar el binario directamente.
                # Nginx hace fork al master + workers automaticamente.
                /usr/sbin/nginx 2>/dev/null
                ;;
            fail2ban)
                # fail2ban-server -b arranca en background sin systemd
                fail2ban-server -b 2>/dev/null
                ;;
            sshd|ssh)
                service ssh start 2>/dev/null || service sshd start 2>/dev/null
                ;;
            *)
                service "$name" start 2>/dev/null
                ;;
        esac
    fi
}

# svc_stop <nombre>
svc_stop() {
    local name="$1"
    if is_systemd; then
        systemctl stop "$name" 2>/dev/null
    else
        case "$name" in
            nginx)
                # nginx -s quit hace graceful shutdown:
                # espera a que los workers terminen las conexiones activas.
                nginx -s quit 2>/dev/null
                ;;
            fail2ban)
                fail2ban-client stop 2>/dev/null
                ;;
            *)
                service "$name" stop 2>/dev/null
                ;;
        esac
    fi
}

# svc_reload <nombre>
#   Recarga la configuracion sin cortar conexiones activas (graceful).
svc_reload() {
    local name="$1"
    if is_systemd; then
        systemctl reload "$name" 2>/dev/null
    else
        case "$name" in
            nginx)
                # nginx -s reload manda SIGHUP al master que:
                # 1. Relee la config.
                # 2. Lanza nuevos workers con la config nueva.
                # 3. Termina los workers viejos cuando completen conexiones.
                # Cero downtime.
                nginx -s reload 2>/dev/null
                ;;
            fail2ban)
                fail2ban-client reload 2>/dev/null
                ;;
            sshd|ssh)
                # SIGHUP recarga sshd sin cerrar sesiones activas
                local pid_file="/run/sshd.pid"
                if [[ -f "$pid_file" ]]; then
                    kill -HUP "$(cat "$pid_file")" 2>/dev/null
                else
                    service ssh reload 2>/dev/null || service sshd reload 2>/dev/null
                fi
                ;;
            *)
                service "$name" reload 2>/dev/null
                ;;
        esac
    fi
}

# svc_restart <nombre>
#   Para y vuelve a arrancar el servicio.
svc_restart() {
    local name="$1"
    if is_systemd; then
        systemctl restart "$name" 2>/dev/null
    else
        case "$name" in
            nginx)
                # Nginx no tiene -s restart; equivalente: quit + start.
                # Para uso productivo preferir svc_reload (no downtime).
                nginx -s quit 2>/dev/null || true
                # Esperar a que el master termine
                local i=0
                while [[ -f /run/nginx.pid ]] && (( i < 10 )); do
                    sleep 1
                    ((i++))
                done
                /usr/sbin/nginx 2>/dev/null
                ;;
            fail2ban)
                # Para correctamente y espera antes de rearrancar
                fail2ban-client stop 2>/dev/null || true
                sleep 1
                fail2ban-server -b 2>/dev/null
                ;;
            *)
                service "$name" restart 2>/dev/null
                ;;
        esac
    fi
}

# svc_enable <nombre>
#   Habilita el inicio automatico del servicio al arrancar el sistema.
#   En entornos sin systemd esta operacion no aplica -- se documenta.
svc_enable() {
    local name="$1"
    if is_systemd; then
        systemctl enable "$name" 2>/dev/null || true
    else
        # Sin systemd (contenedor, CI, WSL2 sin systemd) el inicio
        # automatico no aplica. En un VPS con systemd real esto se
        # gestionara correctamente.
        log_info "  (sin systemd -- inicio automatico de '${name}' no configurado)"
        log_info "  En el servidor de produccion con systemd se habilitara automaticamente."
    fi
}
