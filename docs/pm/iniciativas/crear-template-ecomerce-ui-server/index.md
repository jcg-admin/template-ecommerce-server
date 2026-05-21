# Iniciativa: `crear-template-ecomerce-ui-server`

| Campo | Valor |
|-------|-------|
| Slug | `crear-template-ecomerce-ui-server` |
| Estado | En ejecucion |
| Orden de backlog | (no aplica: abierta directamente sin pasar por backlog) |
| Fecha de creacion (directorio) | 2026-05-21 |
| Fecha de apertura formal | 2026-05-21 |
| Autor / responsable | Nestor Monroy |
| Procedimiento de gestion | PROC-GESTION-001 v4.0.0 + arc42 |
| Repositorio | `template-ecomerce-ui-server` (recien creado, commit inicial pendiente) |
| Iniciativa origen / inspiracion | `jcg-admin/e-comerce-server` (clonado en `/tmp/references/e-comerce-server/`) |
| Iniciativa hermana | `mapear-y-corregir-scss-completo` (en `template-e-comerce-ui`, pausada para priorizar esta) |

## Que hace esta iniciativa

Crear desde cero un proyecto de infraestructura inspirado en
`jcg-admin/e-comerce-server` pero **adaptado al contexto del
template UI**: sin asumir tecnologia backend, usando Nginx en
lugar de Apache, modelo de cuentas simplificado a 4 (sin
`svc-dbdata`), clases de almacenamiento simplificadas a A y B
(sin C).

El resultado sera un repositorio de scripts de
aprovisionamiento que, ejecutados en un Ubuntu 24.04 (VPS o
WSL2), dejen el servidor listo para servir el build de
produccion del `template-e-comerce-ui` con SSL, fail2ban,
SSH hardening, UFW, y reverse-proxy configurable hacia una API
externa cuyo binding tecnico no es problema de este repo.

## Documentos de la iniciativa

| Documento | Estado |
|-----------|--------|
| [index.md](index.md) | Este archivo |
| [alcance-crear-template-ecomerce-ui-server.md](alcance-crear-template-ecomerce-ui-server.md) | Pendiente |
| [plan-crear-template-ecomerce-ui-server.md](plan-crear-template-ecomerce-ui-server.md) | Pendiente |
| [tareas-crear-template-ecomerce-ui-server.md](tareas-crear-template-ecomerce-ui-server.md) | Pendiente |
| [progreso-crear-template-ecomerce-ui-server.md](progreso-crear-template-ecomerce-ui-server.md) | Pendiente |

## Referencias externas

- Repo de referencia: `https://github.com/jcg-admin/e-comerce-server`
  (clonado en `/tmp/references/e-comerce-server/`).
- Analisis previo: `template-e-comerce-ui/docs/desarrollo/analisis-servidor-para-template.md`
  (en el repo del UI, commit `7110527`).
- Procedimiento externo de almacenamiento:
  `Procedimiento-Implementacion-Almacenamiento-WSL2-ecomerce-p001 v1.0.0`.
