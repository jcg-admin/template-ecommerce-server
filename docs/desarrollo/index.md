# Documentacion de desarrollo — `template-ecomerce-ui-server`

Esta carpeta contiene documentacion **tecnica de desarrollo**:
decisiones de arquitectura, analisis de exploracion, ADRs,
notas de portacion desde el repo de referencia, y cualquier
documento que apoye decisiones tecnicas durante la creacion
del repo.

Distinta de:

- [`docs/operaciones.md`][doc-operaciones]: manual operativo
  (como aprovisionar, como mantener, como recuperar de fallos).
  Para el operador.
- [`docs/pm/iniciativas/`][doc-pm]: gestion del proyecto
  (PROC-GESTION-001): alcance, plan, tareas, progreso de cada
  iniciativa. Para el responsable de proyecto.

## Documentos actuales

| Documento | Estado | Producido en |
|-----------|--------|--------------|
| [arquitectura.md][doc-arquitectura] | Inicial. Arquitectura aprobada al abrir la iniciativa. | F0 (apertura) |
| [seguridad.md][doc-seguridad] | Esqueleto. Decisiones aprobadas, detalles pendientes. | F0 esqueleto / F5,F6,F7 lo llenan |
| [glosario.md][doc-glosario] | Activo. Terminologia de uso comun en este repo. | F0 (apertura) |
| [decision-nginx-vs-apache.md][adr-nginx] | ADR aceptado. Ratificacion formal de D-WS. | F0a |
| [decision-modelo-cuentas.md][adr-cuentas] | ADR aceptado. Justificacion de 4 vs 5 cuentas. | F0a |
| [decision-storage-clases.md][adr-storage] | ADR aceptado. Justificacion de 2 vs 3 clases. | F0a |

## Documentos planificados (que viviran aqui)

Conforme la iniciativa avance, vivirán aquí:

| Documento | Cuando se produce |
|-----------|-------------------|
| `portacion-utils-de-referente.md` | F2: cuando se porten los utils desde [`jcg-admin/e-comerce-server`][ref-ecomerce-server] |
| `notas-adaptacion-fail2ban-nginx.md` | F6: jails `sshd` + `nginx-limit-req` + `nginx-botsearch` |
| `analisis-webpack-output-vs-nginx.md` | F11: validar que `dist/` del UI sirve correctamente |

## Convenciones

- **Naming**: `<tipo>-<asunto>.md`. Tipos: `decision-`, `notas-`,
  `analisis-`, `portacion-`, `ratificacion-`.
- **ADRs**: usar prefijo `decision-` y formato canonico
  (contexto, decision, alternativas, consecuencias).
- **Sin tildes en archivos sueltos**: prosa de doc con tildes
  cuando lo natural lo pida, pero nombres de archivo sin
  tildes.
- **Cross-references**: si un doc aqui referencia algo de
  `docs/pm/iniciativas/`, usar rutas relativas
  `../pm/iniciativas/...`.
- **Diagramas**: usar [Mermaid][mermaid] con tema dark
  (`%%{init: {'theme':'base', ...}}%%` con colores de la
  paleta del repo) para asegurar buen contraste.
- **Referencias**: usar formato de enlace Markdown
  `[texto](url)` o referencias `[texto][id]` con lista de IDs
  al final del documento.

## Referencias externas

- Repo de referencia clonado:
  [`/tmp/references/e-comerce-server/`][ref-ecomerce-server].
- Analisis previo (vive en el repo UI):
  [analisis-servidor-para-template.md][analisis-ui].
- Procedimiento de gestion: PROC-GESTION-001 v4.0.0 + arc42.

<!-- Referencias Markdown -->
[doc-arquitectura]: ../arquitectura.md
[doc-seguridad]: ../seguridad.md
[doc-glosario]: ../glosario.md
[doc-operaciones]: ../operaciones.md
[doc-pm]: ../pm/iniciativas/
[adr-nginx]: decision-nginx-vs-apache.md
[adr-cuentas]: decision-modelo-cuentas.md
[adr-storage]: decision-storage-clases.md
[ref-ecomerce-server]: https://github.com/jcg-admin/e-comerce-server
[analisis-ui]: https://github.com/jcg-admin/template-e-comerce-ui/blob/main/docs/desarrollo/analisis-servidor-para-template.md
[mermaid]: https://mermaid.js.org/
