# Analisis — `corregir-links-navegacion-historica`

## Origen del problema

Durante la iniciativa `corregir-paths-ecom-a-tui-server`
se aplico un sed que reemplazo `crear-template-ecommerce-server`
por `crear-template-ecomerce-ui-server` en varios archivos.
Sin embargo, los docs PM de la iniciativa historica
`crear-template-ecomerce-ui-server/` habian sido declarados
fuera de scope por D-PM-HISTORICO y no fueron tocados.

El resultado es que los links internos de navegacion dentro
de esa iniciativa apuntan a archivos con el nombre incorrecto
(`crear-template-ecommerce-server.md`) que nunca existieron.
Los archivos reales siempre tuvieron el nombre completo
(`crear-template-ecomerce-ui-server.md`).

## Inventario exacto de links rotos

### `index.md` — 8 ocurrencias

| Linea | Contenido incorrecto | Correccion |
|-------|----------------------|------------|
| 38 | `alcance-crear-template-ecommerce-server.md` | `alcance-crear-template-ecomerce-ui-server.md` |
| 39 | `plan-crear-template-ecommerce-server.md` | `plan-crear-template-ecomerce-ui-server.md` |
| 40 | `tareas-crear-template-ecommerce-server.md` | `tareas-crear-template-ecomerce-ui-server.md` |
| 41 | `progreso-crear-template-ecommerce-server.md` | `progreso-crear-template-ecomerce-ui-server.md` |
| 58 | `[doc-alcance]: alcance-crear-template-ecommerce-server.md` | `alcance-crear-template-ecomerce-ui-server.md` |
| 59 | `[doc-plan]: plan-crear-template-ecommerce-server.md` | `plan-crear-template-ecomerce-ui-server.md` |
| 60 | `[doc-tareas]: tareas-crear-template-ecommerce-server.md` | `tareas-crear-template-ecomerce-ui-server.md` |
| 61 | `[doc-progreso]: progreso-crear-template-ecommerce-server.md` | `progreso-crear-template-ecomerce-ui-server.md` |

### `alcance-crear-template-ecomerce-ui-server.md` — 1 ocurrencia

| Linea | Contenido incorrecto | Correccion |
|-------|----------------------|------------|
| 156 | `[doc-plan]: plan-crear-template-ecommerce-server.md` | `plan-crear-template-ecomerce-ui-server.md` |

### `plan-crear-template-ecomerce-ui-server.md` — 1 ocurrencia

| Linea | Contenido incorrecto | Correccion |
|-------|----------------------|------------|
| 98 | `[doc-progreso]: progreso-crear-template-ecommerce-server.md` | `progreso-crear-template-ecomerce-ui-server.md` |

## Patron sed

```bash
s/crear-template-ecommerce-server\.md/crear-template-ecomerce-ui-server.md/g
```

El `.md` como sufijo obligatorio garantiza que el patron
NO toca:

- Titulos: `# Iniciativa: \`crear-template-ecommerce-server\``
- Slugs: `| Slug | \`crear-template-ecommerce-server\` |`
- Texto libre que menciona el nombre sin extension

## Verificacion de no-colision

Archivos que NO deben cambiar tras el sed:

| Archivo | Razon |
|---------|-------|
| `progreso-crear-template-ecomerce-ui-server.md` | Sin links rotos; sin patron a reemplazar |
| `tareas-crear-template-ecomerce-ui-server.md` | Sin links rotos; patron no aparece |
| Cualquier archivo fuera de `crear-template-ecomerce-ui-server/` | El sed se aplica solo a los 3 archivos en scope |

## Riesgos

| ID | Riesgo | Mitigacion |
|----|--------|------------|
| R-1 | El sed modifica texto visible de titulos | Patron incluye `.md` obligatorio; titulos no terminan en `.md` |
| R-2 | El sed toca `progreso-*.md` | El sed se aplica explicitamente a 3 archivos; `progreso-*.md` no esta en la lista |
