# Decisiones: Corregir links de navegacion rotos en iniciativa historica

| Campo | Valor |
|-------|-------|
| Iniciativa | INI-SRV-004 corregir-links-navegacion-historica |
| Tipo de documento | Decisiones, hallazgos y verificacion post-ejecucion |
| Obligatoriedad | Obligatorio al cierre segun PROC-GESTION-001 v4.0.0 |
| Fecha de creacion | 2026-05-25 |

> **Por que existe este documento.** Las tareas dicen *que* se hizo.
> El progreso dice *cuanto*. Este documento registra el *por que*,
> los *hallazgos* y la *verificacion final*.

---

## Seccion 1 — Decisiones de diseno

### dec-bypass-pm-historico-para-links-rotos

| Campo | Valor |
|-------|-------|
| Decision | Override de D-PM-HISTORICO para corregir links de navegacion rotos en docs PM de la iniciativa historica. |
| Alternativas | (a) Corregir los links (elegida). (b) Respetar D-PM-HISTORICO y dejar los links rotos. (c) Crear symlinks que resuelvan los paths incorrectos. |
| Razon | D-PM-HISTORICO protege el contenido historico, no los bugs funcionales. Un link que apunta a un archivo que no existe impide la navegacion entre documentos de la iniciativa. La alternativa (b) perpetua un bug. La alternativa (c) es fragil y no es el mecanismo correcto para markdown. |
| Trade-off aceptado | Se modifica texto en docs de una iniciativa cerrada, lo que podria considerarse reescritura historica. La distincion clave: se corrigen los punteros (links), no el contenido semantico (decisiones, eventos, analisis). |

### dec-patron-con-sufijo-md

| Campo | Valor |
|-------|-------|
| Decision | Usar `crear-template-ecommerce-server\.md` (con `.md`) como patron sed en lugar del nombre sin extension. |
| Alternativas | (a) Con sufijo `.md` (elegida). (b) Sin sufijo, reemplazando todas las ocurrencias del nombre. |
| Razon | Sin el sufijo `.md`, el sed tambien modificaria titulos (`# Plan — \`crear-template-ecommerce-server\``), slugs en tablas de metadata, y texto libre que menciona el nombre de la iniciativa. Esos textos son contenido historico que debe permanecer intacto. |
| Trade-off aceptado | El patron es mas especifico y requiere verificacion adicional de que no queden refs sin el sufijo que deban cambiar. |

---

## Seccion 2 — Hallazgos durante la ejecucion

### hallazgo-script-python-detecta-falso-positivo

El script de auditoria Python reporto `[inline] [texto] -> url`
en `docs/desarrollo/index.md` linea 55. Esta linea es texto
explicativo de sintaxis Markdown (`\[texto\](url)` como ejemplo),
no un link real.

El script de auditoria trata cualquier `[texto](path)` como link
potencial sin verificar si esta dentro de un bloque de codigo o
es texto de documentacion. Limitacion conocida del script;
no afecta la validez de la auditoria para links reales.

### hallazgo-tres-archivos-en-scope-no-cuatro

El inventario inicial identifico 3 archivos con links rotos
en `crear-template-ecomerce-ui-server/`. La ejecucion confirmo
exactamente esos 3 archivos (index.md, alcance-*.md, plan-*.md).
`tareas-*.md` y `progreso-*.md` no tenian links rotos, tal como
el analisis predijo.

---

## Seccion 3 — Verificacion post-ejecucion

| Criterio del alcance | Resultado | Evidencia |
|---------------------|-----------|-----------|
| Script Python: 0 links rotos en `crear-template-ecomerce-ui-server/` | PASA | 84 OK, 1 falso positivo conocido en `docs/desarrollo/index.md:55` |
| Texto visible de titulos y slugs sin modificar | PASA | `grep "crear-template-ecommerce-server[^.]"` retorna titulos y slugs intactos |
| `progreso-crear-template-ecomerce-ui-server.md` sin modificaciones | PASA | `git diff` muestra 0 cambios en ese archivo |
| 3 archivos corregidos (index.md, alcance-*.md, plan-*.md) | PASA | `git diff --name-only` muestra exactamente esos 3 archivos |

## Cierre

Esta iniciativa esta **cerrada**. Los 4 criterios de completitud
se cumplen. Los 2 hallazgos estan documentados. Las 2 decisiones
de diseno tienen alternativas y trade-offs registrados.
