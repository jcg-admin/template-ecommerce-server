# Tareas: Auditar y corregir gaps entre analisis y la implementacion

## F0 - Auditoria + PM docs (45 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-001 | Leer `analisis-servidor-para-template.md` e inventariar propuestas | 10 min | **Cerrada** | Lista de propuestas del documento |
| T-002 | Auditar `template-ecommerce-server` contra la propuesta | 15 min | **Cerrada** | Tabla de cumplimiento + 2 gaps |
| T-003 | Auditar `template-ecommerce-ui` (apiService, webpack, MSW) | 15 min | **Cerrada** | 3 bugs criticos identificados con evidencia de codigo |
| T-004 | Crear 6 docs PM con hallazgos concretos | 5 min | **Cerrada** | 6 archivos PM en `auditar-gaps-server-y-ui/` |

## F1 - Corregir verify.sh en server (5 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-101 | Reemplazar 3 ocurrencias de `systemctl start nginx/fail2ban` | 3 min | Pendiente | `scripts/verify.sh` corregido |
| T-102 | `bash -n verify.sh` + `bash tests/run_all.sh` | 2 min | Pendiente | PASS >= 74, FAIL = 0 |

## F2 - Corregir UI apiService + constants + webpack (30 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-201 | Corregir `src/services/apiService.js`: soporte URL relativa | 15 min | Pendiente | apiService sin TypeError con API_URL vacio |
| T-202 | Corregir `src/constants/index.js`: eliminar fallback localhost | 5 min | Pendiente | `constants/index.js` corregido |
| T-203 | Corregir `webpack.config.js`: eliminar fallback localhost en API_URL | 5 min | Pendiente | `webpack.config.js` corregido |
| T-204 | `npm test` en el UI | 5 min | Pendiente | Tests UI sin regresion |

## F3 - Actualizar documentacion (20 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-301 | `.env.example` server: documentar API_UPSTREAM y relacion con API_URL del UI | 10 min | Pendiente | `.env.example` actualizado |
| T-302 | `README.md` server: nota sobre API_URL en despliegue | 5 min | Pendiente | `README.md` server actualizado |
| T-303 | `README.md` UI: documentar API_URL para produccion | 5 min | Pendiente | `README.md` UI actualizado |

## F4 - Verificacion y cierre (15 min)

| ID | Descripcion | Esfuerzo | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-401 | `bash tests/run_all.sh` server + auditoria links | 5 min | Pendiente | PASS >= 74, FAIL = 0 |
| T-402 | Verificar apiService con API_URL vacio: sin TypeError | 5 min | Pendiente | Comportamiento verificado |
| T-403 | Crear `decisiones-*.md`; cerrar index e indice; commits de cierre | 5 min | Pendiente | Iniciativa cerrada en ambos repos |
