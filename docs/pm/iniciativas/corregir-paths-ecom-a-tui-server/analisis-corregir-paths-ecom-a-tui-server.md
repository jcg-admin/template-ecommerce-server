# Analisis — `corregir-paths-ecom-a-tui-server`

## Inventario de patrones

### P1 — `template-ecomerce-ui-server` (nombre viejo del server)

| Archivo | Lineas |
|---------|--------|
| `.env.example` | 2 (header comentario + PROJECT_ROOT comentado) |

Total: 2 lineas en 1 archivo.

### P2 — `template-e-comerce-ui` (nombre viejo del UI)

| Archivo | Lineas |
|---------|--------|
| `.env.example` | 3 (comentario Clase A, comentario UI_DIST, valor UI_DIST) |

Total: 3 lineas en 1 archivo.

### P3 — `/srv/repos/ecom/` (ruta vieja)

| Archivo | Lineas |
|---------|--------|
| `README.md` | 1 |
| `.env.example` | 3 |
| `docs/arquitectura.md` | 3 |
| `docs/desarrollo/decision-storage-clases.md` | 7 |
| `docs/glosario.md` | 3 |
| `docs/operaciones.md` | 8 |
| `docs/seguridad.md` | 1 |

Total: 26 lineas en 7 archivos.

### P4 — Links rotos `crear-template-ecommerce-server`

El directorio real es `crear-template-ecomerce-ui-server`.
El link incorrecto usa `crear-template-ecommerce-server` (sin `ui-`).

| Archivo | Lineas |
|---------|--------|
| `README.md` | 4 |
| `docs/desarrollo/decision-modelo-cuentas.md` | 1 |
| `docs/desarrollo/decision-nginx-vs-apache.md` | 2 |

Total: 7 lineas en 3 archivos.

## Validacion de no-colisiones

Referentes externos a preservar verificados:

```
grep -r "e-comerce-server" --include="*.md" | grep -v "template"
# Resultado esperado: solo jcg-admin/e-comerce-server (referente externo)

grep -r "ecomerce-p001" --include="*.md"
# Resultado esperado: menciones al procedimiento externo
```

Estos patrones NO seran tocados por los sed batches porque:
- P1 busca `template-ecomerce-ui-server` (con `template-` como prefijo)
- P2 busca `template-e-comerce-ui` (con `template-` como prefijo)
- P3 busca `/srv/repos/ecom/` (con ruta completa)

Ningun patron colisiona con `jcg-admin/e-comerce-server` ni con
`ecomerce-p001`.

## Estrategia de ejecucion

Sed batches en orden (mas largo primero para evitar solapamientos):

```bash
# P1+P2+P3 en .env.example (unico archivo con los 3 patrones)
# P3 en docs/ con find + xargs
# P4 con sed directo por archivo (links Markdown especificos)
```

Un commit por fase. Verificacion grep post-sed antes de cada commit.

## Riesgos

| ID | Riesgo | Mitigacion |
|----|--------|------------|
| R-1 | Sed toca referentes externos por colision de patron | Patrones disenados con prefijos distintos; validado en analisis de no-colisiones. |
| R-2 | Link roto en `decision-nginx-vs-apache.md` apunta a plan inexistente | El archivo referencia `plan-crear-template-ecommerce-server.md` que no existe. Se corrige al nombre real del plan. |
