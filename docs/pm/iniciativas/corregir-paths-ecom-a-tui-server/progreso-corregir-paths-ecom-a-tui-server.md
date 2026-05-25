# Progreso: Corregir rutas ecom a tui y nomenclatura en docs

## Eventos atomizados

| Timestamp | Clase | Referencia | Detalle |
|-----------|-------|------------|---------|
| 2026-05-25 12:00 | Apertura | — | Iniciativa abierta. Se detectan rutas `/srv/repos/ecom/` desactualizadas y nomenclatura vieja en archivos operativos del repo. |
| 2026-05-25 12:00 | Decisiones aprobadas | D-PATHS-TUI | `/srv/repos/ecom/` → `/srv/repos/tui/` en todos los archivos operativos. El punto de montaje canonico del WSL2 es `tui`. |
| 2026-05-25 12:00 | Decisiones aprobadas | D-REFERENTES-PRESERVADOS | No modificar `jcg-admin/e-comerce-server` ni `Procedimiento-Implementacion-Almacenamiento-WSL2-ecomerce-p001 v1.0.0`. Son nombres externos reales. |
| 2026-05-25 12:00 | Decisiones aprobadas | D-PM-HISTORICO | No modificar PM docs de `crear-template-ecomerce-ui-server/`. Son historico inmutable per D-COMMITS-HISTORIA. |
| 2026-05-25 12:00 | Decisiones aprobadas | D-LINKS-INICIATIVA | Links rotos `crear-template-ecommerce-server` corregidos a `crear-template-ecomerce-ui-server` en README y docs/desarrollo/. |
| 2026-05-25 12:00 | Inicio de fase | F0 | Inicio de analisis e inventario. |
| 2026-05-25 12:01 | Inicio de tarea | T-001 | Inventario grep de los 4 patrones. |
| 2026-05-25 12:10 | Cierre de tarea | T-001 | P1: 2 lineas en 1 archivo. P2: 3 lineas en 1 archivo. P3: 26 lineas en 7 archivos. P4: 7 lineas en 3 archivos. Total: 38 lineas en 9 archivos. |
| 2026-05-25 12:10 | Inicio de tarea | T-002 | Validacion de no-colisiones con referentes externos. |
| 2026-05-25 12:15 | Cierre de tarea | T-002 | Referentes externos aislados. Ningun patron colisiona con `jcg-admin/e-comerce-server` ni `ecomerce-p001`. |
| 2026-05-25 12:15 | Inicio de tarea | T-003 | Crear 6 documentos PM de la iniciativa. |
| 2026-05-25 12:20 | Cierre de tarea | T-003 | 6 archivos creados en `corregir-paths-ecom-a-tui-server/`. |
| 2026-05-25 12:20 | Fase cerrada | F0 | Analisis completo. 4 patrones, 38 lineas, 9 archivos. Decisiones D-* aprobadas. PM docs creados. |

## Contadores

| Tipo de evento | Cantidad |
|----------------|----------|
| Apertura | 1 |
| Decisiones aprobadas | 4 |
| Inicio de fase | 1 |
| Fase cerrada | 1 |
| Inicio de tarea | 3 |
| Cierre de tarea | 3 |
| Total | 13 |
| 2026-05-25 12:21 | Inicio de fase | F1 | Fix `.env.example`: P1+P2+P3. |
| 2026-05-25 12:22 | Cierre de tarea | T-101..T-104 | `.env.example` corregido. 0 resultados P1+P2+P3. Commit b41be10. |
| 2026-05-25 12:22 | Fase cerrada | F1 | `.env.example` limpio. 5 lineas corregidas. |
| 2026-05-25 12:23 | Inicio de fase | F2 | Fix `README.md`: P3+P4. |
| 2026-05-25 12:24 | Cierre de tarea | T-201..T-203 | `README.md` corregido. 0 resultados P3+P4. Commit 5cb0f69. |
| 2026-05-25 12:24 | Fase cerrada | F2 | `README.md` limpio. 5 lineas corregidas. |
| 2026-05-25 12:25 | Inicio de fase | F3 | Fix `docs/` operativos: P3 en 5 archivos. |
| 2026-05-25 12:26 | Cierre de tarea | T-301..T-306 | 5 archivos corregidos. 22 lineas. 0 resultados P3. Commit 9914e81. |
| 2026-05-25 12:26 | Fase cerrada | F3 | docs/ operativos limpios de rutas ecom. |
| 2026-05-25 12:27 | Inicio de fase | F4 | Fix `docs/desarrollo/` links rotos: P4 en 2 archivos. |
| 2026-05-25 12:28 | Cierre de tarea | T-401..T-403 | 2 archivos corregidos. 0 resultados P4. Commit 4b6f4d6. |
| 2026-05-25 12:28 | Hallazgo durante la ejecucion | H-1 | F4 solo corrigio docs/desarrollo/ pero docs/arquitectura.md, docs/seguridad.md, docs/operaciones.md y docs/desarrollo/decision-storage-clases.md tambien tenian links rotos [doc-iniciativa] y [doc-alcance] apuntando a crear-template-ecommerce-server. Corregidos en F4b. Commit 49db1f3. |
| 2026-05-25 12:29 | Fase cerrada | F4 | Todos los links rotos corregidos (F4 + F4b). |
| 2026-05-25 12:30 | Inicio de fase | F5 | Verificacion global. |
| 2026-05-25 12:31 | Cierre de tarea | T-501 | P1: 0 resultados operativos. P2: 0. P3: 0. P4: 0 en archivos no-historicos. |
| 2026-05-25 12:31 | Cierre de tarea | T-502 | Referentes preservados: 24 refs jcg-admin/e-comerce-server + 17 refs ecomerce-p001. |
| 2026-05-25 12:31 | Fase cerrada | F5 | Verificacion completa. 0 regresiones. Referentes intactos. |
| 2026-05-25 12:32 | Cierre de iniciativa | — | Iniciativa cerrada. 4 patrones corregidos. 38 lineas en 9 archivos operativos. 6 commits (F0..F6). 0 conflictos. 24+17 refs externas preservadas. |
