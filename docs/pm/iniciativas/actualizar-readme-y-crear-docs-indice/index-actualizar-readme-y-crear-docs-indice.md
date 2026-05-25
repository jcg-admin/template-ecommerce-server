# Iniciativa: Actualizar README y crear indice de documentacion

| Campo | Valor |
|-------|-------|
| Artefacto | INI-SRV-008 |
| Tipo | Mantenimiento de documentacion |
| Submodulo | server (template-ecommerce-server) |
| Estado | **Cerrada** |
| Version | 1.0.0 |
| Fecha de creacion | 2026-05-26 |
| Fecha de cierre | 2026-05-26 |
| Autor | NestorMonroy |
| Clasificacion | Interno |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 + arc42 |

## Filosofia rectora

La documentacion refleja el estado real del repo, no el estado
aspiracional. Si un script existe, aparece en el inventario. Si
un cajon de arc42 no esta documentado, se declara explicitamente
como ausente en lugar de inventarlo.

El modelo de documentacion del repo hermano
`template-ecommerce-ui/docs/` es la referencia: cajones arc42
nombrados en castellano, sin numeros, con un `docs/README.md`
como punto de entrada.

Excepciones explicitas:

- Los cajones arc42 que el UI descarto (requisitos de calidad,
  vista de tiempo de ejecucion) pueden estar ausentes en el
  server por las mismas razones o por razones propias del dominio
  devops. Se documentan como ausentes con su justificacion.
- El inventario de LOC en el README no persigue exactitud de
  linea; refleja el orden de magnitud correcto.

## Que produce esta iniciativa

| Entregable | Estado al cierre |
|------------|------------------|
| `README.md` actualizado | Producido — inventario, scripts (4), LOC, 8 iniciativas y 74 PASS corregidos |
| `docs/README.md` creado | Producido — indice arc42 con 3 secciones y 9 cajones ausentes declarados |

## Indice de documentos

| Documento | Proposito |
|-----------|-----------|
| [alcance-actualizar-readme-y-crear-docs-indice.md](alcance-actualizar-readme-y-crear-docs-indice.md) | Que cubre, criterio de completitud, fuera de alcance, estimacion. |
| [analisis-actualizar-readme-y-crear-docs-indice.md](analisis-actualizar-readme-y-crear-docs-indice.md) | Inventario de gaps en README y mapa de cajones docs/ existentes. |
| [plan-actualizar-readme-y-crear-docs-indice.md](plan-actualizar-readme-y-crear-docs-indice.md) | DAG de fases, tareas por fase con esfuerzo. |
| [tareas-actualizar-readme-y-crear-docs-indice.md](tareas-actualizar-readme-y-crear-docs-indice.md) | Lista plana de tareas con estado y entregable. |
| [progreso-actualizar-readme-y-crear-docs-indice.md](progreso-actualizar-readme-y-crear-docs-indice.md) | Bitacora cronologica de eventos atomizados. |
| [decisiones-actualizar-readme-y-crear-docs-indice.md](decisiones-actualizar-readme-y-crear-docs-indice.md) | Decisiones de diseno, hallazgos y verificacion post-ejecucion. |

## Decisiones aprobadas

| ID | Decision | Contenido |
|----|----------|-----------|
| **D-ARC42-ADAPTADO** | Seguir la misma adaptacion arc42 del UI. | Cajones en castellano, sin numeros en nombres, con `docs/README.md` como punto de entrada. Los dos repos son hermanos; consistencia en la estructura de docs reduce la carga cognitiva para quien trabaje en ambos. |
| **D-CAJONES-HONESTOS** | Declarar explicitamente los cajones arc42 ausentes en lugar de crear documentos vacios. | Un `docs/README.md` que apunta a archivos vacios o aspiracionales es peor que uno que dice honestamente "este cajon no existe todavia". El estado real es siempre preferible al aspiracional. |
| **D-README-INVENTARIO** | Actualizar el inventario del README con LOC reales y todos los scripts existentes. | El README es el primer punto de contacto del repo. Un inventario incorrecto genera desconfianza en el resto de la documentacion. |
| **D-NO-NUEVOS-CAJONES** | No crear los documentos de los cajones arc42 faltantes en esta iniciativa; solo el indice que los lista. | Crear documentos de arquitectura de calidad requiere analisis propio por cajon. Crear documentos vacios solo para completar la estructura va directamente en contra de D-CAJONES-HONESTOS. |

## Alcance cruzado con otros repos

No aplica. Todos los cambios son en `template-ecommerce-server`.
El modelo de referencia viene del UI pero no se modifica ese repo.

## Iniciativas relacionadas

- INI-SRV-001 `crear-template-ecomerce-ui-server` (cerrada):
  produjo los docs tecnicos que esta iniciativa organiza y el
  inventario que corregimos en el README.
- INI-SRV-002..007 (cerradas): produjeron los scripts y cambios
  que esta iniciativa refleja en el inventario actualizado.
