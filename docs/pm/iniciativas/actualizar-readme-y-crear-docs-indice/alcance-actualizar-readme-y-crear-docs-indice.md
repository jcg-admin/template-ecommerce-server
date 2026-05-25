# Alcance: Actualizar README y crear indice de documentacion

## Que cubre esta iniciativa

### 1. Actualizar `README.md`

**Inventario de scripts desactualizado:**

| Campo | Valor actual (incorrecto) | Valor correcto |
|-------|--------------------------|----------------|
| Scripts operativos | `verify.sh` + `renew_ssl.sh` (802 LOC) | 4 scripts: `setup.sh`, `start.sh`, `verify.sh`, `renew_ssl.sh` (1318 LOC) |
| Tests | 72 PASS / 0 FAIL / 1 SKIP | 74 PASS / 0 FAIL / 1 SKIP |
| Utils LOC | 832 | 832 (correcto) |
| Provisioners LOC | 2315 | 2326 |
| Tests LOC | 707 | 907 |

**Tabla de iniciativas:** menciona solo `crear-template-ecomerce-ui-server`.
Actualizar para reflejar las 7 iniciativas (INI-SRV-001..007) cerradas y
esta (INI-SRV-008) en ejecucion.

**Estado del repo:** dice "Iniciativa cerrada (12 fases, 31 tareas, 29 commits)".
Con 7 iniciativas cerradas y 61 commits, ese texto ya no refleja la realidad.

### 2. Crear `docs/README.md`

Indice de cajones arc42 siguiendo el modelo del repo UI. Organiza
los documentos existentes y declara honestamente los que faltan.

**Cajones existentes en el server:**

| Cajon | Archivo(s) | Contenido real |
|-------|-----------|----------------|
| Arquitectura y decisiones | `docs/arquitectura.md` | Diagramas de flujo, componentes, decisiones D-* |
| Operaciones | `docs/operaciones.md` | Walkthrough VPS, recuperacion de fallos, FAQ |
| Seguridad | `docs/seguridad.md` | Modelo de amenazas, controles |
| Glosario | `docs/glosario.md` | Terminos del dominio devops y del proyecto |
| Entornos sin systemd | `docs/upgrade-server-systemless.md` | WSL2, contenedores, CI |
| Desarrollo | `docs/desarrollo/` | Documentos de analisis para decisiones tecnicas |
| PM | `docs/pm/` | Iniciativas INI-SRV-001..008, indice |

**Cajones arc42 ausentes (a declarar explicitamente):**

- Introduccion y objetivos — ausente
- Restricciones de arquitectura — ausente
- Contexto y alcance del sistema — ausente
- Estrategia de solucion — ausente
- Vista de bloques de construccion — ausente
- Vista de despliegue — ausente (parcialmente cubierto por arquitectura.md)
- Conceptos transversales — ausente
- Riesgos y deuda tecnica — ausente

## Criterio de completitud

1. `README.md`: inventario de scripts con 4 entradas y LOC correctos.
2. `README.md`: tests actualizados a 74 PASS.
3. `README.md`: seccion de estado con las 7+1 iniciativas.
4. `docs/README.md` existe y organiza los cajones existentes.
5. `docs/README.md` declara explicitamente los cajones ausentes.
6. `bash tests/run_all.sh`: PASS >= 74, FAIL = 0.
7. Auditoria de links: sin nuevos rotos.

## Fuera de alcance

| Item | Razon |
|------|-------|
| Crear documentos de cajones arc42 faltantes | D-NO-NUEVOS-CAJONES: crear docs vacios viola D-CAJONES-HONESTOS |
| Actualizar el contenido de los docs tecnicos existentes | `arquitectura.md`, `operaciones.md` son correctos; esta iniciativa solo crea el indice |
| Modificar `docs/pm/` | El PM es correcto; solo se actualiza el `indice-de-iniciativas.md` con INI-SRV-008 |

## Estimacion de esfuerzo

| Fase | Descripcion | Esfuerzo |
|------|-------------|----------|
| F0 | Analisis + PM docs | 20 min |
| F1 | Actualizar `README.md` | 20 min |
| F2 | Crear `docs/README.md` | 20 min |
| F3 | Verificacion y cierre | 10 min |
| Total | | ~1 hora 10 min |
