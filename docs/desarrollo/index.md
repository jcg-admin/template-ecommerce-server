# Documentacion de desarrollo — `template-ecomerce-ui-server`

Esta carpeta contiene documentacion **tecnica de desarrollo**:
decisiones de arquitectura, analisis de exploracion, ADRs,
notas de portacion desde el repo de referencia, y cualquier
documento que apoye decisiones tecnicas durante la creacion
del repo.

Distinta de:
- `docs/operaciones.md`: manual operativo (como aprovisionar,
  como mantener, como recuperar de fallos). Para el operador.
- `docs/pm/iniciativas/`: gestion del proyecto (PROC-GESTION-001):
  alcance, plan, tareas, progreso de cada iniciativa. Para el
  responsable de proyecto.

## Documentos actuales

| Documento | Estado | Producido en |
|-----------|--------|--------------|
| [arquitectura.md](../arquitectura.md) | Inicial. Arquitectura aprobada al abrir la iniciativa. | F0 (apertura) |
| [seguridad.md](../seguridad.md) | Esqueleto. Decisiones aprobadas, detalles pendientes. | F0 esqueleto / F5,F6,F7 lo llenan |
| [glosario.md](../glosario.md) | Activo. Terminologia de uso comun en este repo. | F0 (apertura) |

## Documentos planificados (que viviran aqui)

Conforme la iniciativa avance, vivirán aquí:

| Documento | Cuando se produce |
|-----------|-------------------|
| `portacion-utils-de-referente.md` | F2: cuando se porten los utils desde `jcg-admin/e-comerce-server` |
| `decision-nginx-vs-apache.md` (ADR) | F0a: ratificacion formal de D-WS |
| `decision-modelo-cuentas.md` (ADR) | F0a: justificacion de 4 vs 5 cuentas |
| `decision-storage-clases.md` (ADR) | F0a: justificacion de 2 vs 3 clases |
| `notas-adaptacion-fail2ban-nginx.md` | F6: jails sshd + nginx-limit-req + nginx-botsearch |
| `analisis-webpack-output-vs-nginx.md` | F11: validar que `dist/` del UI sirve correctamente |

## Convenciones

- **Naming**: `<tipo>-<asunto>.md`. Tipos: `decision-`, `notas-`,
  `analisis-`, `portacion-`, `ratificacion-`.
- **ADRs**: usar prefijo `decision-` y formato canonico (contexto,
  decision, alternativas, consecuencias).
- **Sin tildes en archivos sueltos**: prosa de doc con tildes
  cuando lo natural lo pida, pero nombres de archivo sin tildes.
- **Cross-references**: si un doc aqui referencia algo de
  `docs/pm/iniciativas/`, usar rutas relativas
  `../pm/iniciativas/...`.

## Referencias externas

- Repo de referencia clonado:
  `/tmp/references/e-comerce-server/`
- Analisis previo (vive en el repo UI):
  `template-e-comerce-ui/docs/desarrollo/analisis-servidor-para-template.md`
- Procedimiento de gestion: PROC-GESTION-001 v4.0.0 + arc42
