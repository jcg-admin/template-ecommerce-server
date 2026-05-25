# Plan — `corregir-paths-ecom-a-tui-server`

## DAG de fases

```mermaid
%%{init: {'theme':'base', 'themeVariables': {
  'background': '#0f172a',
  'primaryColor': '#1e293b',
  'primaryTextColor': '#f1f5f9',
  'primaryBorderColor': '#94a3b8',
  'lineColor': '#cbd5e1',
  'fontSize': '13px'
}}}%%
flowchart TD
    f0["F0\nAnalisis + PM docs"]
    f1["F1\nFix .env.example\n(P1 + P2 + P3)"]
    f2["F2\nFix README.md\n(P3 + P4)"]
    f3["F3\nFix docs/ operativos\n(P3)"]
    f4["F4\nFix docs/desarrollo/\n(P4 links rotos)"]
    f5["F5\nVerificacion"]
    f6["F6\nCierre"]

    f0 --> f1
    f1 --> f2
    f2 --> f3
    f3 --> f4
    f4 --> f5
    f5 --> f6

    classDef done fill:#14532d,stroke:#4ade80,stroke-width:2px,color:#f0fdf4
    classDef active fill:#1e3a8a,stroke:#60a5fa,stroke-width:2px,color:#f1f5f9
    classDef pending fill:#1e293b,stroke:#94a3b8,stroke-width:1px,color:#f1f5f9

    class f0 done
    class f1,f2,f3,f4,f5,f6 done
    
```

## Fases y tareas

### F0 — Analisis + PM docs

| ID | Tarea | Estimado |
|----|-------|----------|
| T-001 | Inventario grep de los 4 patrones | 10 min |
| T-002 | Validacion de no-colisiones con referentes externos | 5 min |
| T-003 | Crear 6 documentos PM de la iniciativa | 5 min |

### F1 — Fix `.env.example`

| ID | Tarea | Estimado |
|----|-------|----------|
| T-101 | Corregir P1: `template-ecomerce-ui-server` → `template-ecommerce-server` | 2 min |
| T-102 | Corregir P2: `template-e-comerce-ui` → `template-ecommerce-ui` | 2 min |
| T-103 | Corregir P3: `/srv/repos/ecom/` → `/srv/repos/tui/` | 1 min |
| T-104 | Verificar grep post-sed: 0 resultados de P1+P2+P3 | 1 min |

### F2 — Fix `README.md`

| ID | Tarea | Estimado |
|----|-------|----------|
| T-201 | Corregir P3: `/srv/repos/ecom/` → `/srv/repos/tui/` | 1 min |
| T-202 | Corregir P4: links `crear-template-ecommerce-server` | 2 min |
| T-203 | Verificar grep post-sed: 0 resultados de P3+P4 | 2 min |

### F3 — Fix `docs/` operativos

| ID | Tarea | Estimado |
|----|-------|----------|
| T-301 | Corregir P3 en `docs/arquitectura.md` | 1 min |
| T-302 | Corregir P3 en `docs/desarrollo/decision-storage-clases.md` | 1 min |
| T-303 | Corregir P3 en `docs/glosario.md` | 1 min |
| T-304 | Corregir P3 en `docs/operaciones.md` | 1 min |
| T-305 | Corregir P3 en `docs/seguridad.md` | 1 min |
| T-306 | Verificar grep post-sed: 0 resultados de P3 en docs/ | 3 min |

### F4 — Fix `docs/desarrollo/` links rotos

| ID | Tarea | Estimado |
|----|-------|----------|
| T-401 | Corregir P4 en `docs/desarrollo/decision-modelo-cuentas.md` | 1 min |
| T-402 | Corregir P4 en `docs/desarrollo/decision-nginx-vs-apache.md` | 1 min |
| T-403 | Verificar grep post-sed: 0 resultados de P4 en docs/desarrollo/ | 2 min |

### F5 — Verificacion global

| ID | Tarea | Estimado |
|----|-------|----------|
| T-501 | grep global P1+P2+P3+P4: 0 resultados en archivos operativos | 3 min |
| T-502 | grep referentes externos preservados | 2 min |

### F6 — Cierre

| ID | Tarea | Estimado |
|----|-------|----------|
| T-601 | Actualizar estado de iniciativa a Cerrada | 1 min |
| T-602 | Commit de cierre | 1 min |

## Totales

| Fase | Estimado |
|------|----------|
| F0 | 20 min |
| F1 | 6 min |
| F2 | 5 min |
| F3 | 8 min |
| F4 | 4 min |
| F5 | 5 min |
| F6 | 2 min |
| Total | 50 min |
