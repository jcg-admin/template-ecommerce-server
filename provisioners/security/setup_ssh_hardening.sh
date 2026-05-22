#!/bin/bash
# =============================================================================
# provisioners/security/setup_ssh_hardening.sh
# Aplica hardening de OpenSSH para template-ecommerce-server
# =============================================================================
# Portado 1:1 del referente jcg-admin/e-comerce-server/provisioners/security/
# setup_ssh_hardening.sh (417 LOC). El referente es 100% agnostic al web
# server (no menciona Apache, Django ni Nginx en ninguna linea ejecutable).
# Adaptacion unica: cambio de marca en headers, comentarios, y nombre del
# archivo de override (PracticaYoruba -> template-ecommerce-server).
#
# IDEMPOTENTE: si el override ya existe con la configuracion correcta y
# sshd esta corriendo con esa configuracion, no hace nada.
#
# Estrategia de override:
#   Crea /etc/ssh/sshd_config.d/99-template-ecommerce-server.conf en
#   lugar de modificar /etc/ssh/sshd_config directamente. Esto preserva
#   la compatibilidad con actualizaciones del sistema operativo y permite
#   revertir borrando el archivo de override.
#
# Configuracion aplicada:
#   Port                   SSH_PORT  (default: 22)
#   PermitRootLogin        no
#   PasswordAuthentication no
#   MaxAuthTries           3
#   LoginGraceTime         30
#   ClientAliveInterval    300
#   ClientAliveCountMax    2
#   X11Forwarding          no
#   AllowTcpForwarding     no
#
# GUARDA CONTRA LOCKOUT:
#   Antes de aplicar PasswordAuthentication no, verifica que existe al
#   menos un archivo authorized_keys con contenido en /root/.ssh/ o
#   en /home/*/.ssh/. Si no hay ninguna clave SSH autorizada, el script
#   sale con error en lugar de dejar el servidor inaccesible.
#
# ADVERTENCIA SOBRE EL CAMBIO DE PUERTO:
#   Si SSH_PORT es diferente del puerto actual de sshd, las nuevas
#   conexiones deberan usar el nuevo puerto tras recargar sshd. La
#   sesion SSH activa NO se cierra -- solo las nuevas conexiones deberan
#   usar el nuevo puerto.
#
# COMPORTAMIENTO EN WSL2 / CONTENEDORES:
#   En WSL2 sshd suele ser provisto por Windows (no Linux). En
#   contenedores recien creados sshd puede no estar instalado. El
#   script detecta ausencia de sshd y aborta tempranamente con mensaje
#   informativo -- by design, no es bug.
#
# Uso:
#   sudo bash provisioners/security/setup_ssh_hardening.sh
#
# Variables opcionales en .env:
#   SSH_PORT -- puerto donde escucha sshd (default: 22)
#
# Requiere: root, Ubuntu 24.04, openssh-server instalado.
# Modelo de cuentas (D-CUENTAS): invocar como `deploy` (UID 1000).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
export PROJECT_ROOT

source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/core.sh"
source "${PROJECT_ROOT}/utils/validation.sh"

# =============================================================================
# Cargar .env (opcional)
# =============================================================================
ENV_FILE="${PROJECT_ROOT}/.env"
[[ -f "$ENV_FILE" ]] && { set -a; source "$ENV_FILE"; set +a; }

SSH_PORT="${SSH_PORT:-22}"

# Ruta del archivo de override -- 99- garantiza que carga ultimo,
# sobrescribiendo cualquier otra configuracion. Nombre del archivo
# adaptado al repo (vs 99-practicayoruba.conf del referente).
readonly OVERRIDE_FILE="/etc/ssh/sshd_config.d/99-template-ecommerce-server.conf"

# =============================================================================
# Genera el contenido esperado del override
# La salida se usa tanto para escribir como para comparar (idempotencia)
# =============================================================================
_generate_override() {
    cat << SSHEOF
# ${OVERRIDE_FILE}
# Generado por provisioners/security/setup_ssh_hardening.sh
# No editar manualmente -- ejecutar setup_ssh_hardening.sh para aplicar cambios.
#
# Este archivo se carga via Include en /etc/ssh/sshd_config.
# Los valores aqui tienen precedencia sobre sshd_config.

# Puerto de escucha
# Valor configurado en .env (SSH_PORT). Para que el cambio sea efectivo,
# setup_firewall.sh debe permitir este mismo puerto en UFW.
Port ${SSH_PORT}

# Prohibir login directo como root -- los operadores deben usar
# un usuario no-root y elevar privilegios con sudo.
PermitRootLogin no

# Solo claves SSH -- sin contrasenas. Requiere que el operador tenga
# una clave autorizada en ~/.ssh/authorized_keys antes de aplicar.
PasswordAuthentication no

# Reducir el numero de intentos antes de cerrar la conexion.
# Combinado con fail2ban (setup_fail2ban.sh jail sshd), hace el brute
# force efectivamente inviable.
MaxAuthTries 3

# Cerrar conexiones que no autentican en 30 segundos.
LoginGraceTime 30

# Mantener la conexion activa -- detecta sesiones muertas.
ClientAliveInterval 300
ClientAliveCountMax 2

# Deshabilitar reenvio de pantalla X11 -- el servidor no tiene entorno grafico.
X11Forwarding no

# Deshabilitar reenvio TCP -- previene uso del servidor como proxy SSH.
AllowTcpForwarding no
SSHEOF
}

# =============================================================================
# PASO: Verificar requisitos
# =============================================================================
_check_requisites() {
    log_header "PASO: Verificando requisitos"

    validate_root || {
        log_error "  Ejecuta con: sudo bash provisioners/security/setup_ssh_hardening.sh"
        exit 1
    }
    log_success "Corriendo como root"

    require_command sshd || {
        log_error "sshd no encontrado -- openssh-server no esta instalado"
        log_error ""
        log_error "  Este script configura el hardening de OpenSSH. Sin sshd"
        log_error "  no hay servicio SSH que proteger."
        log_error ""
        log_error "  Instala con: sudo apt-get install openssh-server"
        log_error ""
        log_warn "  Entorno sin sshd detectado -- estas en un contenedor, WSL2 o CI?"
        log_warn "  En ese caso este script no aplica -- es solo para servidores"
        log_warn "  Ubuntu con acceso SSH real (VPS, bare-metal)."
        exit 1
    }
    log_success "sshd disponible"

    # Verificar que el directorio de overrides existe.
    # Ubuntu 24.04 lo crea automaticamente, pero verificamos por seguridad.
    if [[ ! -d /etc/ssh/sshd_config.d ]]; then
        log_error "/etc/ssh/sshd_config.d no existe"
        log_error "  Ubuntu 24.04 crea este directorio automaticamente."
        log_error "  Verifica tu version: lsb_release -a"
        exit 1
    fi
    log_success "/etc/ssh/sshd_config.d disponible"

    # Verificar que sshd_config incluye el directorio de overrides
    if ! grep -q "Include /etc/ssh/sshd_config.d" /etc/ssh/sshd_config 2>/dev/null; then
        log_warn "sshd_config no incluye el directorio sshd_config.d"
        log_warn "  Los overrides pueden no cargarse correctamente"
        log_warn "  Verifica /etc/ssh/sshd_config manualmente"
    fi
}

# =============================================================================
# PASO: Verificar estado actual (idempotencia)
# =============================================================================
_check_current_state() {
    log_header "PASO: Estado actual del hardening SSH"

    if [[ ! -f "$OVERRIDE_FILE" ]]; then
        log_info "Override no encontrado -- se creara"
        return 0
    fi

    # Comparar con la configuracion esperada
    local expected
    expected=$(_generate_override)
    local current
    current=$(cat "$OVERRIDE_FILE")

    if [[ "$expected" != "$current" ]]; then
        log_info "Override desactualizado -- se actualizara"
        return 0
    fi

    # Verificar que sshd esta corriendo con la configuracion del override
    local effective_port
    effective_port=$(sshd -T 2>/dev/null | grep "^port " | awk '{print $2}')
    local effective_rootlogin
    effective_rootlogin=$(sshd -T 2>/dev/null | grep "^permitrootlogin " | awk '{print $2}')
    local effective_passauth
    effective_passauth=$(sshd -T 2>/dev/null | grep "^passwordauthentication " | awk '{print $2}')

    if [[ "$effective_port"       == "$SSH_PORT" ]] && \
       [[ "$effective_rootlogin"  == "no"        ]] && \
       [[ "$effective_passauth"   == "no"        ]]; then
        log_success "sshd ya tiene el hardening correcto -- sin cambios (idempotente)"
        log_success "  Port:                   ${effective_port}"
        log_success "  PermitRootLogin:        ${effective_rootlogin}"
        log_success "  PasswordAuthentication: ${effective_passauth}"
        exit 0
    fi

    log_info "sshd aun no tiene la configuracion del override -- aplicando"
}

# =============================================================================
# PASO: Verificar authorized_keys antes de desactivar contrasenas
# Guarda contra lockout: si no hay claves SSH configuradas y desactivamos
# PasswordAuthentication, el servidor queda inaccesible.
# =============================================================================
_check_authorized_keys() {
    log_header "PASO: Verificando claves SSH autorizadas"

    local found_key=false

    # Verificar /root/.ssh/authorized_keys
    if [[ -s /root/.ssh/authorized_keys ]]; then
        local key_count
        key_count=$(grep -c "^ssh-\|^ecdsa-\|^sk-\|^sk-ecdsa" \
                    /root/.ssh/authorized_keys 2>/dev/null || echo "0")
        if (( key_count > 0 )); then
            log_success "  /root/.ssh/authorized_keys: ${key_count} clave(s)"
            found_key=true
        fi
    fi

    # Verificar /home/*/.ssh/authorized_keys
    while IFS= read -r -d '' keyfile; do
        if [[ -s "$keyfile" ]]; then
            local key_count
            key_count=$(grep -c "^ssh-\|^ecdsa-\|^sk-\|^sk-ecdsa" \
                        "$keyfile" 2>/dev/null || echo "0")
            if (( key_count > 0 )); then
                local user_home
                user_home=$(dirname "$(dirname "$keyfile")")
                log_success "  ${keyfile}: ${key_count} clave(s) (${user_home})"
                found_key=true
            fi
        fi
    done < <(find /home -name "authorized_keys" -print0 2>/dev/null)

    if [[ "$found_key" == "false" ]]; then
        log_error "No se encontro ninguna clave SSH autorizada"
        log_error ""
        log_error "  Antes de desactivar PasswordAuthentication, agrega tu clave publica:"
        log_error ""
        log_error "  En tu maquina local:"
        log_error "    ssh-keygen -t ed25519 -C 'tu@email.com'  # si no tienes clave"
        log_error "    ssh-copy-id -p ${SSH_PORT} usuario@<IP_DEL_SERVIDOR>"
        log_error ""
        log_error "  O manualmente en el servidor:"
        log_error "    mkdir -p ~/.ssh && chmod 700 ~/.ssh"
        log_error "    echo '<tu_clave_publica>' >> ~/.ssh/authorized_keys"
        log_error "    chmod 600 ~/.ssh/authorized_keys"
        log_error ""
        log_error "  Luego vuelve a ejecutar este script."
        exit 1
    fi

    log_success "Claves SSH encontradas -- seguro aplicar PasswordAuthentication no"
}

# =============================================================================
# PASO: Escribir override y verificar sintaxis
# Si sshd -t falla, el override se elimina para no dejar sshd en estado
# inconsistente. El servidor queda con la configuracion anterior.
# =============================================================================
_apply_override() {
    log_header "PASO: Aplicando override de sshd"

    # Advertir sobre cambio de puerto si es diferente al actual
    local current_port
    current_port=$(sshd -T 2>/dev/null | grep "^port " | awk '{print $2}' || echo "22")
    if [[ "$SSH_PORT" != "$current_port" ]]; then
        log_warn "Cambio de puerto SSH: ${current_port} -> ${SSH_PORT}"
        log_warn "  La sesion SSH activa continuara en el puerto ${current_port}"
        log_warn "  Las nuevas conexiones deberan usar el puerto ${SSH_PORT}"
        log_warn "  Asegurate de que UFW permite el puerto ${SSH_PORT}:"
        log_warn "    sudo ufw status | grep ${SSH_PORT}"
    fi

    # Escribir el override
    _generate_override > "$OVERRIDE_FILE"
    chmod 644 "$OVERRIDE_FILE"
    log_success "Override escrito: ${OVERRIDE_FILE}"

    # Garantizar /run/sshd -- sshd -t lo exige aun para validacion.
    # En contenedores recien creados puede no existir aun.
    [[ -d /run/sshd ]] || mkdir -p /run/sshd

    # Verificar sintaxis -- si falla, revertir inmediatamente
    log_info "  Verificando sintaxis con sshd -t..."
    if ! sshd -t 2>/dev/null; then
        log_error "sshd -t fallo -- revirtiendo override para evitar lockout"
        rm -f "$OVERRIDE_FILE"
        log_error "  Override eliminado. sshd queda con la configuracion anterior."
        log_error "  Revisa el error:"
        sshd -t 2>&1 | while IFS= read -r line; do
            log_error "    ${line}"
        done
        exit 1
    fi
    log_success "Sintaxis verificada (sshd -t OK)"
}

# =============================================================================
# PASO: Recargar sshd
# =============================================================================
_reload_sshd() {
    log_header "PASO: Recargando sshd"

    # Sin systemd y sin pidfile el daemon no esta corriendo (caso tipico
    # en contenedores). La configuracion queda aplicada y se cargara
    # cuando el operador arranque sshd manualmente.
    if ! is_systemd && [[ ! -f /run/sshd.pid ]] && ! pgrep -x sshd >/dev/null 2>&1; then
        log_warn "  sshd no corre (sin systemd y sin /run/sshd.pid) -- omitiendo reload"
        log_manual_start sshd "/usr/sbin/sshd"
        log_info "  Al arrancar, sshd cargara ${OVERRIDE_FILE} automaticamente."
        return 0
    fi

    # svc_reload usa SIGHUP sin systemd (sin cerrar sesiones activas)
    if ! svc_reload sshd 2>/dev/null; then
        if ! svc_reload ssh 2>/dev/null; then
            log_error "No se pudo recargar sshd"
            if is_systemd; then
                log_error "  Intenta manualmente: sudo systemctl reload sshd"
            else
                log_error "  Intenta manualmente: sudo kill -HUP \$(cat /run/sshd.pid)"
            fi
            exit 1
        fi
    fi

    log_success "sshd recargado -- nueva configuracion activa"
    log_info "  La sesion SSH activa continua sin interrupcion"
}

# =============================================================================
# PASO: Verificar configuracion efectiva
# =============================================================================
_verify_hardening() {
    log_header "PASO: Verificando configuracion efectiva"

    # sshd -T vuelca la configuracion efectiva incluyendo overrides
    local effective_port
    effective_port=$(sshd -T 2>/dev/null | grep "^port " | awk '{print $2}')
    local effective_rootlogin
    effective_rootlogin=$(sshd -T 2>/dev/null | grep "^permitrootlogin " | awk '{print $2}')
    local effective_passauth
    effective_passauth=$(sshd -T 2>/dev/null | grep "^passwordauthentication " | awk '{print $2}')
    local effective_maxretry
    effective_maxretry=$(sshd -T 2>/dev/null | grep "^maxauthtries " | awk '{print $2}')

    local all_ok=true

    if [[ "$effective_port" == "$SSH_PORT" ]]; then
        log_success "  Port:                   ${effective_port}"
    else
        log_error "  Port esperado ${SSH_PORT}, efectivo: ${effective_port}"
        all_ok=false
    fi

    if [[ "$effective_rootlogin" == "no" ]]; then
        log_success "  PermitRootLogin:        no"
    else
        log_error "  PermitRootLogin efectivo: ${effective_rootlogin} (se esperaba no)"
        all_ok=false
    fi

    if [[ "$effective_passauth" == "no" ]]; then
        log_success "  PasswordAuthentication: no"
    else
        log_error "  PasswordAuthentication efectivo: ${effective_passauth} (se esperaba no)"
        all_ok=false
    fi

    log_info "  MaxAuthTries:           ${effective_maxretry}"

    if [[ "$all_ok" == "false" ]]; then
        log_error "La configuracion efectiva no coincide con el override"
        log_error "  Verifica: sshd -T | grep -E 'port|permitroot|passwordauth'"
        exit 1
    fi
}

# =============================================================================
# MAIN
# =============================================================================
log_header "Hardening de SSH -- template-ecommerce-server"
log_info "  SSH_PORT: ${SSH_PORT}"
log_info "  Override: ${OVERRIDE_FILE}"
echo ""

_check_requisites;      echo ""
_check_current_state;   echo ""
_check_authorized_keys; echo ""
_apply_override;        echo ""
_reload_sshd;           echo ""
_verify_hardening;      echo ""

log_separator 60 "="
log_success "SSH hardening aplicado en puerto ${SSH_PORT}"
echo ""
log_info "Configuracion activa:"
log_info "  PermitRootLogin        no"
log_info "  PasswordAuthentication no"
log_info "  MaxAuthTries           3"
log_info "  LoginGraceTime         30s"
log_info "  X11Forwarding          no"
log_info "  AllowTcpForwarding     no"
echo ""
if [[ "$SSH_PORT" != "22" ]]; then
    log_warn "  Puerto SSH cambiado a ${SSH_PORT}."
    log_warn "  Nuevas conexiones: ssh -p ${SSH_PORT} usuario@<IP>"
    log_warn "  Actualiza tu ~/.ssh/config si usas alias de host."
fi
log_info "Verificar:"
log_info "  bash scripts/verify.sh"
