# Progreso — `crear-template-ecomerce-ui-server`

Registro cronologico de eventos siguiendo PROC-GESTION-001 con
las clases definidas en el procedimiento.

## Eventos

| Timestamp (UTC) | Clase | Referencia | Detalle |
|-----------------|-------|------------|---------|
| 2026-05-21T20:55:00 | Apertura | iniciativa | **Iniciativa `crear-template-ecomerce-ui-server` formalmente abierta**. Solicitud del usuario: "vamos a empezar a crearla con el nombre de [template-ecomerce-ui-server]" tras aprobar el analisis previo en `template-e-comerce-ui/docs/desarrollo/analisis-servidor-para-template.md` (commit `7110527` del repo UI). Repo nuevo creado en `/tmp/project/template-ecomerce-ui-server/`, branch `main`, autor heredado de `template-e-comerce-ui` (`Nestor Monroy <46802445+NestorMonroy@users.noreply.github.com>`). Iniciativa hermana `mapear-y-corregir-scss-completo` pausada formalmente en el otro repo. |
| 2026-05-21T20:55:01 | Decisiones aprobadas | D-WS, D-CUENTAS, D-STORAGE, D-NOMBRE, D-BACKEND-AGNOSTIC, D-PROVISIONER-PATTERN | **6 decisiones aprobadas al abrir la iniciativa**: D-WS Nginx en lugar de Apache (justificacion en analisis previo: catch-all SPA en 1 linea, reverse proxy nativo, footprint menor, agnostic a tecnologia backend). D-CUENTAS 4 cuentas Linux sin `svc-dbdata` (no hay BD en scope). D-STORAGE 2 clases A y B sin C (idem). D-NOMBRE `template-ecomerce-ui-server` sin guion entre `e` y `comerce` por instruccion explicita del usuario (asimetria intencional vs `template-e-comerce-ui` que tiene guion). D-BACKEND-AGNOSTIC el server NO asume tecnologia backend, `$API_UPSTREAM` es variable de entorno vacia por defecto. D-PROVISIONER-PATTERN heredar patron shell idempotente con placeholders `%%VAR%%` del referente. |
| 2026-05-21T20:55:02 | Plan | apertura | **Plan en 12 fases F0..F11 documentado** (~14h totales). Detalle en `plan-crear-template-ecomerce-ui-server.md`. Fase F0 (apertura formal) en ejecucion ahora mismo. Tareas T-001 y T-002 cubren la apertura completa. |
| 2026-05-21T20:55:03 | Inicio de tarea | T-001 | Comienzo T-001 (Fase F0). Crear los 5 documentos formales de iniciativa segun PROC-GESTION-001: index, alcance, plan, tareas, progreso. Esfuerzo estimado 30 min. |
| 2026-05-21T20:55:04 | Cierre de tarea | T-001 | Cierre T-001. Los 5 documentos creados: `index.md`, `alcance-*.md`, `plan-*.md`, `tareas-*.md`, `progreso-*.md` (este). Total ~1400 lineas combinadas. Documenta el alcance completo de la iniciativa (lo que esta dentro y fuera de scope), 6 decisiones aprobadas, 12 fases con esfuerzo estimado por fase, 31 tareas con esfuerzo estimado por tarea, riesgos con mitigaciones. Siguiente tarea: T-002 (commit inicial del repo). |

| 2026-05-21T21:05:29 | Hallazgo durante la ejecucion | T-002 | **Estructura de documentacion tecnica creada en F0 (no en F10 como originalmente planificado)**. Solicitud del usuario: 'En el server, crea tambien docs/desarrollo/ y docs/operaciones.md y otros docs ademas de los de PM'. **Decision tomada sin pausar**: producir el ANDAMIO de documentacion ahora (en F0) en lugar de esperar a F10. La estructura se establece desde el inicio; el contenido sustantivo se llena segun avanzan las fases. **5 archivos producidos** (859 lineas totales): (1) `docs/desarrollo/index.md` (55 lineas) -- enumera documentos planificados que viviran en esta carpeta (ADRs, notas de portacion, analisis especificos). (2) `docs/arquitectura.md` (217 lineas) -- **CONTENIDO REAL Y COMPLETO**: vista 3-tier, 5 componentes detallados (web server Nginx, SSL acme.sh, hardening de seguridad, modelo de cuentas, clases de almacenamiento), 6 decisiones aprobadas referenciadas, 3 flujos importantes (aprovisionar, request de usuario, renovacion SSL), tabla de diferencias vs referente. (3) `docs/operaciones.md` (321 lineas) -- **ESQUELETO**: indice de 8 secciones, marcadores explicitos `[Pendiente F<n>]` por seccion, contenido provisional en Prerequisitos y Configuracion inicial. Listo para que F10 lo cierre. (4) `docs/seguridad.md` (199 lineas) -- **ESQUELETO CON DECISIONES**: resumen de postura (6 capas de defensa), decisiones aprobadas con detalle (cuentas, storage, SSL/TLS, SSH hardening, fail2ban, UFW, headers HTTP), modelo de amenazas informal, listas de responsabilidades NO mitigadas. Detalles concretos pendientes F5/F6/F7. (5) `docs/glosario.md` (67 lineas) -- **CONTENIDO REAL**: ~30 terminos alfabeticos (ACME, acme.sh, deploy, fail2ban, HSTS, SPA, SPA catch-all, vhost, WSGI, www-data, X-Forwarded-Proto, Yoruba como nota historica, etc) + comparaciones rapidas de cuentas y storage. **Beneficio de esta decision**: cualquier persona que llegue al repo ahora tiene contexto tecnico completo (arquitectura + glosario + esqueleto de operaciones + decisiones de seguridad) sin tener que consultar el repo UI. F10 se vuelve menos costoso porque solo llena huecos en lugar de escribir desde cero. **Lo que no cambia**: T-1001 y T-1002 de F10 siguen siendo necesarias para completar `docs/operaciones.md` (paso a paso real) y producir `docs/upgrade-server-systemless.md`. **Validacion**: no aplica tests (sin codigo aun); working tree consistente. |
| 2026-05-21T21:05:30 | Cierre de tarea | T-002 | **Adelanto parcial de F10 ejecutado y registrado**. F0 cierra a continuacion con T-001 (los 5 documentos de PM, ya commiteados en root commit `32f2b9e`) + T-002 (este commit que anade los 5 documentos tecnicos). Siguiente fase F0a (Validaciones iniciales, ~30 min): ratificar decision Nginx vs Apache, confirmar acceso a la referencia clonada, enumerar archivos del referente a portar. |
## Contadores

| Clase | Conteo |
|-------|--------|
| Apertura | 1 |
| Reconsideracion | 0 |
| Decisiones aprobadas | 6 |
| Plan | 1 |
| Cambio de estado | 0 |
| Replan | 0 |
| Hallazgo durante la ejecucion | 1 |
| Inicio de tarea | 1 |
| Cierre de tarea | 2 |
| Fase cerrada | 0 |
| Bloqueo | 0 |
| Desbloqueo | 0 |
| Cambio de alcance | 0 |
| Cierre de iniciativa | 0 |
| Analisis | 0 |
