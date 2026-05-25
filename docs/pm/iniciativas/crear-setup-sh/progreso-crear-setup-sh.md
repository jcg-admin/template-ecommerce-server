# Progreso — `crear-setup-sh`

Registro cronologico de eventos siguiendo PROC-GESTION-001 con
las clases definidas en el procedimiento. Cada evento es
atomico y refleja lo que ocurrio en el momento en que se
produjo; los hallazgos se registran al descubrirse, no al
cerrar la tarea.

## Eventos

| Timestamp (UTC) | Clase | Referencia | Detalle |
|-----------------|-------|------------|---------|
| 2026-05-25T19:00:00 | Apertura | iniciativa | **Iniciativa `crear-setup-sh` formalmente abierta.** Se detecta la ausencia de un punto de entrada unificado para aprovisionar el servidor. Los 8 provisioners existen y son idempotentes pero requieren invocacion manual en orden especifico con riesgo de lockout SSH si se ejecutan sin la pausa correcta entre paso 2 (ssh_hardening) y paso 3 (firewall). La iniciativa crea `scripts/setup.sh` como orquestador que resuelve este problema mediante un mecanismo de dos fases con flag `--continue`. |
| 2026-05-25T19:00:01 | Decisiones aprobadas | D-DOS-FASES, D-SKIP-SSH, D-SSL-FLAGS, D-IDEMPOTENTE, D-NO-INSTALA-ENV, D-GUARD-SSH-KEY, D-NO-REEMPLAZA-PROVISIONERS | **7 decisiones aprobadas al abrir la iniciativa.** D-DOS-FASES: setup.sh opera en dos fases separadas por pausa de reconexion SSH (Fase 1: install + ssh_hardening; Fase 2: firewall + fail2ban + ssl + vhost + verify). D-SKIP-SSH: flag `--skip-ssh` omite ssh_hardening y suprime la pausa para WSL2/CI. D-SSL-FLAGS: `--ssl-dev` y `--ssl-staging` se pasan a setup_ssl.sh. D-IDEMPOTENTE: setup.sh hereda idempotencia de los provisioners sin logica adicional. D-NO-INSTALA-ENV: setup.sh valida .env pero no lo crea. D-GUARD-SSH-KEY: verificacion de clave SSH antes de Fase 1, mismo guard que ssh_hardening.sh. D-NO-REEMPLAZA-PROVISIONERS: los provisioners individuales siguen invocables directamente sin cambios. |
| 2026-05-25T19:00:02 | Plan | apertura | **Plan en 4 fases F0..F3 documentado (~2h totales).** Detalle en `plan-crear-setup-sh.md`. Fase F0 (analisis + PM docs) en ejecucion. T-001, T-002, T-003 cubren la apertura completa. |
| 2026-05-25T19:00:03 | Inicio de fase | F0 | **Inicio de Fase F0 (Analisis + PM docs).** Esfuerzo estimado 30 min. Objetivo: entender el contexto tecnico completo, disenar el flujo de dos fases con 4 flags, y producir los 6 documentos PM con 3 diagramas Mermaid. |
| 2026-05-25T19:00:04 | Inicio de tarea | T-001 | Comienzo T-001. Leer `scripts/verify.sh`, todos los provisioners, `utils/core.sh` y `docs/upgrade-server-systemless.md` para entender que helpers existen, como se estructura un script en este repo, y como se maneja el entorno sin systemd. |
| 2026-05-25T19:10:00 | Hallazgo durante la ejecucion | T-001 | **`utils/core.sh` provee exactamente los helpers que setup.sh necesita.** `command_exists()` sirve para el guard de Fase 2 (verificar que nginx esta instalado). `log_header()`, `log_info()`, `log_success()`, `log_error()`, `log_warn()` de `logging.sh` dan output consistente con el resto del proyecto. `is_systemd()` puede usarse para ajustar mensajes segun el entorno. El patron de estructura de todos los scripts del repo es identico: `set -euo pipefail`, calculo de `SCRIPT_DIR` y `PROJECT_ROOT`, source de utils, funciones privadas con prefijo `_`, MAIN al final. `setup.sh` seguira exactamente ese patron. |
| 2026-05-25T19:10:01 | Hallazgo durante la ejecucion | T-001 | **El problema del lockout SSH esta documentado pero no resuelto en codigo.** `docs/operaciones.md` documenta el orden critico y advierte sobre el lockout, y el `README.md` lo menciona con un comentario `>>> reconectar <<<`. Pero no existe ningun mecanismo automatico que fuerce la pausa. Esto confirma que la solucion de dos fases con `--continue` es la correcta y no existe alternativa ya implementada que se pueda reutilizar. |
| 2026-05-25T19:12:00 | Cierre de tarea | T-001 | Cierre T-001. Contexto tecnico entendido completamente. 7 helpers de utils identificados. Patron de estructura de script confirmado. Problema del lockout SSH documentado pero sin solucion en codigo — D-DOS-FASES es la respuesta correcta. |
| 2026-05-25T19:12:01 | Inicio de tarea | T-002 | Comienzo T-002. Disenar el flujo completo: dos fases, 4 flags, guards de prerequisitos, deteccion de combinaciones invalidas de flags, y riesgos con mitigaciones. |
| 2026-05-25T19:17:00 | Cierre de tarea | T-002 | Cierre T-002. Flujo diseñado: 3 diagramas Mermaid (decision, secuencia, estados). 7 decisiones D-* aprobadas. 4 riesgos identificados con mitigaciones. Combinaciones invalidas de flags identificadas: `--skip-ssh` + `--continue` (sin sentido; si se salta SSH no hay pausa que requiera `--continue`). |
| 2026-05-25T19:17:01 | Inicio de tarea | T-003 | Comienzo T-003. Crear los 6 documentos PM de la iniciativa siguiendo la estructura de PROC-GESTION-001 y modelados sobre la iniciativa existente `crear-template-ecomerce-ui-server`. |
| 2026-05-25T19:45:00 | Cierre de tarea | T-003 | Cierre T-003. 6 archivos PM creados en `crear-setup-sh/`: index (metadata + descripcion + documentos + referencias), alcance (resumen + dentro/fuera de scope + decisiones + criterios de aceptacion + riesgos + esfuerzo), analisis (inventario + 3 diagramas Mermaid + validacion de no-colisiones + estrategia + riesgos + conclusion), plan (tabla de fases + DAG + disciplina + estilo de commits + riesgos + que sigue), tareas (lista por fase con salida por tarea), progreso (este documento). |
| 2026-05-25T19:45:01 | Fase cerrada | F0 | **Cierre de Fase F0 (Analisis + PM docs).** 3 tareas cerradas (T-001..T-003). 6 documentos PM producidos. 3 diagramas Mermaid en analisis.md. 7 decisiones D-* ratificadas. 2 hallazgos registrados. Esfuerzo real: ~45 min (vs 30 min estimados; exceso por reestructuracion de documentos para seguir la estructura correcta de PROC-GESTION-001). Siguiente: F1 (Crear scripts/setup.sh, 45 min). Pendiente confirmacion del usuario para iniciar F1. |

## Contadores

| Tipo de evento | Cantidad |
|----------------|----------|
| Apertura | 1 |
| Decisiones aprobadas | 1 |
| Plan | 1 |
| Inicio de fase | 1 |
| Fase cerrada | 1 |
| Inicio de tarea | 3 |
| Cierre de tarea | 3 |
| Hallazgo durante la ejecucion | 2 |
| Total | 13 |
