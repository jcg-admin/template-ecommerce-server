#!/bin/bash
# =============================================================================
# provisioners/firewall/setup_firewall.sh
# Configura el firewall UFW para template-ecommerce-server
# =============================================================================
# Portado 1:1 del referente jcg-admin/e-comerce-server/provisioners/firewall/
# setup_firewall.sh (215 LOC). El referente es 100% agnostic al web server
# (no menciona Apache, Django ni Nginx). Adaptacion unica: cambio de marca
# en headers y comentarios.
#
# IDEMPOTENTE: si UFW ya esta activo con las reglas correctas, no hace nada.
#
# Principio de privilegio minimo:
#   Solo se abren los puertos estrictamente necesarios para operar.
#   Todo el trafico entrante no listado explicitamente es denegado.
#
# Puertos permitidos:
#   ${SSH_PORT}/tcp (SSH)   -- acceso administrativo al servidor
#   80/tcp          (HTTP)  -- ACME challenge (Let's Encrypt) + redirect HTTPS
#   443/tcp         (HTTPS) -- trafico de la aplicacion
#
# ADVERTENCIA -- RIESGO DE LOCKOUT:
#   Habilitar UFW sin permitir SSH primero cierra la sesion activa.
#   Este script permite el puerto SSH ANTES de habilitar UFW.
#   Si usas un puerto SSH no estandar, edita SSH_PORT en .env o
#   pasa SSH_PORT=XXXX al entorno antes de ejecutar:
#     SSH_PORT=2222 sudo bash provisioners/firewall/setup_firewall.sh
#
# ORDEN DE INSTALACION:
#   1) provisioners/nginx/install.sh
#   2) provisioners/security/setup_ssh_hardening.sh    (define SSH_PORT)
#   3) provisioners/firewall/setup_firewall.sh         (permite ese SSH_PORT)
#   4) provisioners/security/setup_fail2ban.sh         (banaction=ufw)
#   Asi UFW conoce el puerto SSH correcto antes de cualquier cambio que
#   podria cerrar la sesion activa.
#
# Uso:
#   sudo bash provisioners/firewall/setup_firewall.sh
#
# Variables opcionales (con defaults seguros):
#   SSH_PORT -- puerto SSH (default: 22)
#
# Requiere: root, Ubuntu 24.04 (ufw incluido).
# Modelo de cuentas (D-CUENTAS): invocar como `deploy` (UID 1000).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
export PROJECT_ROOT

source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/core.sh"
source "${PROJECT_ROOT}/utils/validation.sh"

# Cargar .env si existe (para que SSH_PORT venga de ahi automaticamente)
ENV_FILE="${PROJECT_ROOT}/.env"
[[ -f "$ENV_FILE" ]] && { set -a; source "$ENV_FILE"; set +a; }

# Puerto SSH -- configurable para instalaciones no estandar
SSH_PORT="${SSH_PORT:-22}"

# Puertos requeridos por template-ecommerce-server
readonly REQUIRED_PORTS=("${SSH_PORT}/tcp" "80/tcp" "443/tcp")

# =============================================================================
# PASO: Verificar requisitos
# =============================================================================
_check_requisites() {
    log_header "PASO: Verificando requisitos"

    validate_root || {
        log_error "  Ejecuta con: sudo bash provisioners/firewall/setup_firewall.sh"
        exit 1
    }
    log_success "Corriendo como root"

    require_command ufw || {
        log_info "  ufw no encontrado -- instalando..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y ufw > /dev/null
        log_success "ufw instalado"
        return 0
    }
    log_success "ufw disponible"
}

# =============================================================================
# Detectar si UFW ya tiene una regla para un puerto
# =============================================================================
_ufw_has_rule() {
    local port_proto="$1"  # ej: "22/tcp" o "443/tcp"
    ufw status 2>/dev/null | grep -qE "^${port_proto%/tcp}\b|^${port_proto}\b"
}

# =============================================================================
# PASO: Verificar si UFW ya esta correctamente configurado
# =============================================================================
_check_current_state() {
    log_header "PASO: Estado actual del firewall"

    local ufw_status_line
    ufw_status_line=$(ufw status 2>/dev/null | head -1)

    if ! echo "$ufw_status_line" | grep -q "Status: active"; then
        log_info "UFW inactivo -- configurando desde cero"
        return 0
    fi

    log_info "UFW activo -- verificando reglas"

    local all_ok=true
    for port_proto in "${REQUIRED_PORTS[@]}"; do
        if _ufw_has_rule "$port_proto"; then
            log_success "  Regla presente: ALLOW ${port_proto}"
        else
            log_info "  Regla faltante: ${port_proto}"
            all_ok=false
        fi
    done

    if [[ "$all_ok" == "true" ]]; then
        log_success "UFW activo con todas las reglas requeridas -- sin cambios (idempotente)"
        exit 0
    fi

    log_info "  Algunas reglas faltantes -- aplicando..."
}

# =============================================================================
# PASO: Configurar reglas UFW
# CRITICO: SSH se permite ANTES de habilitar UFW para evitar lockout.
# Sin este orden, habilitar UFW con politica default-deny corta la sesion
# SSH activa antes de poder aplicar la regla de SSH.
# =============================================================================
_configure_rules() {
    log_header "PASO: Configurando reglas de firewall"

    # Politica por defecto: denegar entrante, permitir saliente.
    # `allow outgoing` es esencial para que el server pueda hablar con
    # apt (instalar paquetes), acme.sh (renovar SSL), API_UPSTREAM si
    # esta en otro host, etc.
    log_info "  Politica: deny incoming, allow outgoing"
    ufw default deny incoming  > /dev/null 2>&1
    ufw default allow outgoing > /dev/null 2>&1

    # SSH -- SIEMPRE primero para evitar lockout
    log_info "  Permitiendo SSH en puerto ${SSH_PORT}/tcp"
    ufw allow "${SSH_PORT}/tcp" comment "SSH -- administracion" > /dev/null 2>&1
    log_success "  SSH ${SSH_PORT}/tcp: ALLOW"

    # HTTP -- necesario para ACME HTTP-01 challenge (Let's Encrypt) +
    # redirect a HTTPS (template-http.conf)
    log_info "  Permitiendo HTTP en puerto 80/tcp"
    ufw allow 80/tcp comment "HTTP -- ACME challenge + redirect a HTTPS" > /dev/null 2>&1
    log_success "  HTTP 80/tcp: ALLOW"

    # HTTPS -- trafico de la aplicacion (template-https.conf)
    log_info "  Permitiendo HTTPS en puerto 443/tcp"
    ufw allow 443/tcp comment "HTTPS -- template-ecommerce-server aplicacion" > /dev/null 2>&1
    log_success "  HTTPS 443/tcp: ALLOW"
}

# =============================================================================
# PASO: Habilitar UFW
# =============================================================================
_enable_ufw() {
    log_header "PASO: Habilitando UFW"

    local ufw_status_line
    ufw_status_line=$(ufw status 2>/dev/null | head -1)

    if echo "$ufw_status_line" | grep -q "Status: active"; then
        # UFW ya activo -- recargar para aplicar las nuevas reglas
        log_info "  UFW ya activo -- recargando para aplicar cambios"
        ufw reload > /dev/null 2>&1
        log_success "UFW recargado"
        return 0
    fi

    # Habilitar con --force para evitar el prompt interactivo
    log_warn "  Habilitando UFW -- asegurate de tener acceso SSH alternativo si algo falla"
    ufw --force enable > /dev/null 2>&1
    log_success "UFW habilitado"
}

# =============================================================================
# PASO: Verificar reglas aplicadas
# =============================================================================
_verify_rules() {
    log_header "PASO: Verificando reglas aplicadas"

    local ufw_status
    ufw_status=$(ufw status verbose 2>/dev/null)

    log_info "  Estado UFW:"
    echo "$ufw_status" | head -10 | while IFS= read -r line; do
        log_info "    ${line}"
    done
    echo ""

    local all_ok=true
    for port_proto in "${REQUIRED_PORTS[@]}"; do
        if _ufw_has_rule "$port_proto"; then
            log_success "  ALLOW ${port_proto}"
        else
            log_error "  FALTA regla para ${port_proto}"
            all_ok=false
        fi
    done

    [[ "$all_ok" == "true" ]] || {
        log_error "Una o mas reglas no se aplicaron correctamente"
        exit 1
    }
}

# =============================================================================
# MAIN
# =============================================================================
log_header "Configuracion de firewall UFW -- template-ecommerce-server"
log_info "  Principio de privilegio minimo: solo puertos SSH/HTTP/HTTPS"
log_info "  SSH_PORT: ${SSH_PORT}"
echo ""

_check_requisites;    echo ""
_check_current_state; echo ""
_configure_rules;     echo ""
_enable_ufw;          echo ""
_verify_rules;        echo ""

log_separator 60 "="
log_success "Firewall configurado. Puertos activos: SSH(${SSH_PORT}), HTTP(80), HTTPS(443)"
echo ""
log_info "Verifica el estado completo:"
log_info "  sudo ufw status verbose"
log_info "  bash scripts/verify.sh"
