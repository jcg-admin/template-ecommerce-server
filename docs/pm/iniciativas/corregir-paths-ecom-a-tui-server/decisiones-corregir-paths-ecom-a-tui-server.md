# Decisiones: Corregir rutas ecom a tui y nomenclatura en docs

| Campo | Valor |
|-------|-------|
| Iniciativa | INI-SRV-003 corregir-paths-ecom-a-tui-server |
| Tipo de documento | Decisiones, hallazgos y verificacion post-ejecucion |
| Obligatoriedad | Obligatorio al cierre segun PROC-GESTION-001 v4.0.0 |
| Fecha de creacion | 2026-05-25 |

> **Por que existe este documento.** Las tareas dicen *que* se hizo.
> El progreso dice *cuanto*. Este documento registra el *por que*,
> los *hallazgos* y la *verificacion final*.

---

## Seccion 1 — Decisiones de diseno

### dec-sed-batch-vs-edicion-manual

| Campo | Valor |
|-------|-------|
| Decision | Usar sed batches por fase en lugar de edicion manual archivo por archivo. |
| Alternativas | (a) sed batches (elegida). (b) Edicion manual con editor. |
| Razon | 9 archivos afectados con 38 lineas distribuidas. La edicion manual es propensa a omisiones. sed con verificacion grep pre y post garantiza cobertura completa. |
| Trade-off aceptado | Un sed incorrecto puede hacer cambios masivos inadvertidos. Mitigacion: definir el patron exacto en F0 y verificar con grep antes de ejecutar. |

### dec-tui-como-punto-de-montaje-canonico

| Campo | Valor |
|-------|-------|
| Decision | Reemplazar `/srv/repos/ecom/` por `/srv/repos/tui/` como ruta canonica. |
| Alternativas | (a) `/srv/repos/tui/` (elegida). (b) Mantener `/srv/repos/ecom/` como ejemplo generico. |
| Razon | El punto de montaje real del WSL2 es `tui`, definido en el procedimiento de almacenamiento v1.1.0. Mantener `ecom` en los docs produce confusion cuando el operador sigue las instrucciones y no encuentra la ruta en su sistema. |
| Trade-off aceptado | Si en el futuro se crea otra instancia WSL2 con punto de montaje diferente, los docs necesitaran otra actualizacion. La documentacion refleja el entorno real actual. |

### dec-excluir-pm-historico

| Campo | Valor |
|-------|-------|
| Decision | No modificar los docs PM de `crear-template-ecomerce-ui-server/`. |
| Alternativas | (a) Excluir PM historico (elegida). (b) Actualizar todos los docs incluyendo los PM de la iniciativa cerrada. |
| Razon | Los docs PM de una iniciativa cerrada son registro inmutable de lo que paso en su momento. Modificarlos retroactivamente falsificaria la bitacora. El procedimiento es claro: progreso-*.md es historia; los demas docs PM de iniciativas cerradas tambien. |
| Trade-off aceptado | Los docs PM historicos tienen referencias `ecom` que ya no corresponden al entorno real. Se acepta esta inconsistencia como costo del principio de inmutabilidad historica. |

---

## Seccion 2 — Hallazgos durante la ejecucion

### hallazgo-links-rotos-en-mas-archivos-que-los-identificados

En F4 se identificaron 3 archivos con links rotos
(`crear-template-ecommerce-server`). Al verificar globalmente
en F5, aparecieron 4 archivos adicionales que tambien tenian
links rotos y no estaban en el inventario inicial: `docs/arquitectura.md`,
`docs/seguridad.md`, `docs/operaciones.md` y
`docs/desarrollo/decision-storage-clases.md`.

Causa: el inventario de F0 identifico los archivos por patron
de grep pero no verifico todos los archivos que usaban
`[doc-iniciativa]` como ref-def. La F4 inicial solo corrigio
los identificados en F0.

Leccion: en iniciativas con patrones de links, verificar el
resultado final con el script de auditoria Python antes de
declarar una fase cerrada, no solo con grep del patron original.

### hallazgo-24-refs-externas-preservadas

Al verificar globalmente post-ejecucion, `jcg-admin/e-comerce-server`
contaba con 24 referencias intactas. `ecomerce-p001` con 17.
Confirmacion de que los patrones sed con prefijos especificos
no tocaron los referentes externos.

---

## Seccion 3 — Verificacion post-ejecucion

| Criterio del alcance | Resultado | Evidencia |
|---------------------|-----------|-----------|
| `grep -r "template-ecomerce-ui-server"` en archivos operativos: 0 resultados | PASA | Solo en historico preservado |
| `grep -r "template-e-comerce-ui"` en archivos operativos: 0 resultados | PASA | 0 resultados en archivos no-historicos |
| `grep -r "/srv/repos/ecom/"` en archivos operativos: 0 resultados | PASA | 0 resultados |
| `grep -r "crear-template-ecommerce-server"` en archivos no-historicos: 0 resultados | PASA | 0 resultados fuera de PM historico |
| `jcg-admin/e-comerce-server` intacto | PASA | 24 referencias preservadas |
| `ecomerce-p001` intacto | PASA | 17 referencias preservadas |
| Working tree limpio antes de cada commit de fase | PASA | `git status -s` == 0 antes de cada commit |

## Cierre

Esta iniciativa esta **cerrada**. Los 7 criterios de completitud
se cumplen. Los 2 hallazgos estan documentados con leccion
aprendida. Las 3 decisiones de diseno tienen alternativas y
trade-offs registrados.
