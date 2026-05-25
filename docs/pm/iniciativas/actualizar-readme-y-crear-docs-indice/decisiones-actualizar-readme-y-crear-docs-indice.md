# Decisiones: Actualizar README y crear indice de documentacion

| Campo | Valor |
|-------|-------|
| Iniciativa | INI-SRV-008 actualizar-readme-y-crear-docs-indice |
| Tipo de documento | Decisiones, hallazgos y verificacion post-ejecucion |
| Obligatoriedad | Obligatorio al cierre segun PROC-GESTION-001 v4.0.0 |
| Fecha de creacion | 2026-05-26 |

> **Por que existe este documento.** Las tareas dicen *que* se hizo.
> El progreso dice *cuanto*. Este documento registra el *por que*,
> los *hallazgos* y la *verificacion final*.

---

## Seccion 1 — Decisiones de diseno

### dec-arc42-adaptado-como-modelo

| Campo | Valor |
|-------|-------|
| Decision | Seguir la misma adaptacion arc42 del UI para `docs/README.md`: cajones en castellano, sin numeros, con el README como punto de entrada. |
| Alternativas | (a) arc42 adaptado del UI (elegida). (b) Estructura propia sin referencia a arc42. (c) README tecnico plano sin estructura de cajones. |
| Razon | Los dos repos son hermanos y comparten el mismo procedimiento de gestion. Un operador o desarrollador que trabaje en ambos repos no debe aprender dos estructuras de documentacion distintas. La consistencia reduce la carga cognitiva. |
| Trade-off aceptado | Los cajones arc42 del UI estan orientados a software (bloques de construccion, conceptos transversales). El server tiene un dominio distinto (devops, provisioners). Algunos cajones del UI no aplican directamente y se descartaron con justificacion. |

### dec-cajones-honestos

| Campo | Valor |
|-------|-------|
| Decision | Declarar explicitamente los cajones arc42 ausentes con su justificacion en lugar de crear documentos vacios o aspiracionales. |
| Alternativas | (a) Declarar ausentes con justificacion (elegida). (b) Crear documentos esqueleto vacios para "completar" la estructura. (c) No mencionar los cajones ausentes. |
| Razon | Un `docs/README.md` que apunta a archivos vacios engana al lector sobre el estado real de la documentacion. Un indice que declara honestamente lo que falta y por que es mas util que uno que finge que todo existe. La alternativa (c) oculta deuda de documentacion. |
| Trade-off aceptado | El `docs/README.md` tiene una tabla de 9 cajones ausentes que puede parecer larga. Se acepta: refleja la deuda real de documentacion del repo, que es genuina para un repo de infraestructura que priorizo el codigo operativo sobre la documentacion formal de arquitectura. |

### dec-no-nuevos-cajones-en-esta-iniciativa

| Campo | Valor |
|-------|-------|
| Decision | No crear los documentos de los cajones arc42 faltantes en esta iniciativa; solo el indice que los lista. |
| Alternativas | (a) Solo el indice (elegida). (b) Crear todos los cajones con contenido minimo en la misma iniciativa. (c) Crear los cajones de mayor prioridad (introduccion y objetivos, restricciones). |
| Razon | Crear documentos de arquitectura de calidad requiere analisis dedicado por cajon. Crear borradores vacios o con contenido minimo viola D-CAJONES-HONESTOS. La alternativa (c) tiene el mismo problema: "minimo" inevitablemente se convierte en aspiracional. Cada cajon que se documente merece su propia iniciativa con analisis previo. |
| Trade-off aceptado | El repo quedara con cajones declarados pero no documentados hasta que cada uno tenga su iniciativa. Esta es la deuda correcta a cargar: deuda declarada y consciente, no deuda oculta. |

### dec-readme-como-inventario-real

| Campo | Valor |
|-------|-------|
| Decision | El inventario del README refleja LOC reales medidos con `wc -l` y todos los scripts existentes, no solo los producidos por INI-SRV-001. |
| Alternativas | (a) LOC reales, todos los scripts (elegida). (b) Mantener el inventario de INI-SRV-001 y agregar una nota de "actualizado en INI-SRV-00X". (c) Eliminar la tabla de inventario por ser propenso a desactualizarse. |
| Razon | El README es el primer punto de contacto del repo. Un inventario incorrecto genera desconfianza en el resto de la documentacion. La alternativa (b) produce un README con dos fuentes de verdad. La alternativa (c) elimina informacion util. La alternativa (a) requiere actualizacion cada vez que se agrega un script, lo que es una disciplina razonable para un repo de infraestructura. |
| Trade-off aceptado | El inventario de LOC se desactualizara con el tiempo. Se acepta: un LOC aproximadamente correcto es mejor que un LOC claramente incorrecto. La politica es actualizar en la misma iniciativa que produce el script nuevo. |

---

## Seccion 2 — Hallazgos durante la ejecucion

### hallazgo-6-errores-de-estructura-en-primera-version-pm

La primera version de los 6 documentos PM de esta iniciativa
tenia 6 errores de estructura respecto al procedimiento real
del repo UI:

1. `Estado` sin negrita: `En ejecucion` vs `**En ejecucion**`.
2. `Procedimiento de gestion` sin arc42: `PROC-GESTION-001 v4.0.0`
   vs `PROC-GESTION-001 v4.0.0 + arc42`.
3. IDs de decisiones sin negrita: `D-ARC42-ADAPTADO` vs
   `**D-ARC42-ADAPTADO**`.
4. Indice de documentos incluia el propio index. El real del UI
   no se auto-referencia.
5. Eventos del progreso demasiado escuetos. El real del UI
   incluye contexto completo con numeros y validaciones.
6. `Fecha de creacion` ponia `2026-05-25` (UTC) vs `2026-05-26`
   (fecha local correcta).

Todos corregidos antes de proceder a F1. El hallazgo se registro
en el progreso en T-003 para trazabilidad.

### hallazgo-doc-docs-link-roto-en-f1-resuelto-en-f2

Al agregar la ref-def `[doc-docs]: docs/README.md` en el README
durante F1 (T-104), la auditoria de links reporto ese link como
roto porque `docs/README.md` no existia todavia. Era un link
anticipado al entregable de F2. Se documento como "roto esperado"
en el cierre de T-105 y quedo resuelto automaticamente al crear
`docs/README.md` en F2 (T-201). La auditoria final de F3 confirma
141 OK sin ese roto.

### hallazgo-cajones-propios-del-dominio-devops

El mapeo de cajones arc42 al server revelo que el repo tiene
3 documentos que no tienen equivalente directo en arc42:

- `operaciones.md` (walkthrough de aprovisionamiento y operacion)
- `seguridad.md` (modelo de amenazas y controles)
- `upgrade-server-systemless.md` (entornos sin systemd)

Estos son propios del dominio devops. arc42 esta orientado a
software; un repo de infraestructura tiene preocupaciones
distintas. Se documentan en `docs/README.md` como cajones
propios del proyecto, no como desviaciones de arc42.

---

## Seccion 3 — Verificacion post-ejecucion

| Criterio del alcance | Resultado | Evidencia |
|---------------------|-----------|-----------|
| `README.md`: inventario con 4 scripts y LOC correctos | PASA | setup.sh 344, start.sh 150, verify.sh 633, renew_ssl.sh 191 = 1318 total |
| `README.md`: tests actualizados a 74 PASS | PASA | `bash tests/run_all.sh`: 74 PASS / 0 FAIL / 1 SKIP |
| `README.md`: tabla de 8 iniciativas (INI-SRV-001..008) | PASA | Tabla presente con links a cada index |
| `docs/README.md` existe | PASA | Archivo creado en F2 |
| `docs/README.md`: cajones existentes organizados | PASA | 3 secciones: operadores, arquitectura, PM |
| `docs/README.md`: cajones ausentes declarados | PASA | 9 cajones arc42 con justificacion individual |
| `bash tests/run_all.sh`: PASS >= 74, FAIL = 0 | PASA | 74 PASS / 0 FAIL / 1 SKIP |
| Auditoria de links: sin nuevos rotos | PASA | 141 OK, 3 falsos positivos conocidos preexistentes |

## Cierre

Esta iniciativa esta **cerrada**. Los 7 criterios de completitud
se cumplen. Los 3 hallazgos estan documentados. Las 4 decisiones
de diseno tienen alternativas y trade-offs registrados.
