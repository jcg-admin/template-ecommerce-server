# Tareas — `corregir-paths-ecom-a-tui-server`

| ID | Descripcion | Estimado | Estado | Entregable |
|----|-------------|----------|--------|------------|
| T-001 | Inventario grep de los 4 patrones | 10 min | CERRADA | 2+3+26+7 lineas en 9 archivos identificados |
| T-002 | Validacion de no-colisiones con referentes externos | 5 min | CERRADA | Referentes externos aislados, sin colision |
| T-003 | Crear 6 documentos PM de la iniciativa | 5 min | CERRADA | 6 archivos en `corregir-paths-ecom-a-tui-server/` |
| T-101 | Corregir P1 en `.env.example` | 2 min | CERRADA | `.env.example` sin `template-ecomerce-ui-server` |
| T-102 | Corregir P2 en `.env.example` | 2 min | CERRADA | `.env.example` sin `template-e-comerce-ui` |
| T-103 | Corregir P3 en `.env.example` | 1 min | CERRADA | `.env.example` con rutas `tui` |
| T-104 | Verificar grep post-sed en `.env.example` | 1 min | CERRADA | 0 resultados P1+P2+P3 |
| T-201 | Corregir P3 en `README.md` | 1 min | CERRADA | `README.md` con rutas `tui` |
| T-202 | Corregir P4 en `README.md` | 2 min | CERRADA | Links apuntando a directorio real |
| T-203 | Verificar grep post-sed en `README.md` | 2 min | CERRADA | 0 resultados P3+P4 |
| T-301 | Corregir P3 en `docs/arquitectura.md` | 1 min | CERRADA | Rutas `tui` en arquitectura |
| T-302 | Corregir P3 en `docs/desarrollo/decision-storage-clases.md` | 1 min | CERRADA | Rutas `tui` en decision storage |
| T-303 | Corregir P3 en `docs/glosario.md` | 1 min | CERRADA | Rutas `tui` en glosario |
| T-304 | Corregir P3 en `docs/operaciones.md` | 1 min | CERRADA | Rutas `tui` en operaciones |
| T-305 | Corregir P3 en `docs/seguridad.md` | 1 min | CERRADA | Rutas `tui` en seguridad |
| T-306 | Verificar grep post-sed en `docs/` | 3 min | CERRADA | 0 resultados P3 en docs/ |
| T-401 | Corregir P4 en `docs/desarrollo/decision-modelo-cuentas.md` | 1 min | CERRADA | Link correcto |
| T-402 | Corregir P4 en `docs/desarrollo/decision-nginx-vs-apache.md` | 1 min | CERRADA | Link correcto |
| T-403 | Verificar grep post-sed en `docs/desarrollo/` | 2 min | CERRADA | 0 resultados P4 |
| T-501 | grep global P1+P2+P3+P4 en archivos operativos | 3 min | CERRADA | 0 resultados en todos los patrones |
| T-502 | grep referentes externos preservados | 2 min | CERRADA | Referentes intactos con conteo |
| T-601 | Actualizar estado de iniciativa a Cerrada | 1 min | CERRADA | index con Estado=Cerrada |
| T-602 | Commit de cierre | 1 min | CERRADA | Commit F6 en main |

## Resumen por fase

| Fase | Tareas | Estado |
|------|--------|--------|
| F0 — Analisis | T-001..T-003 | CERRADA |
| F1 — Fix `.env.example` | T-101..T-104 | CERRADA |
| F2 — Fix `README.md` | T-201..T-203 | CERRADA |
| F3 — Fix `docs/` operativos | T-301..T-306 | CERRADA |
| F4 — Fix `docs/desarrollo/` | T-401..T-403 | CERRADA |
| F5 — Verificacion global | T-501..T-502 | CERRADA |
| F6 — Cierre | T-601..T-602 | CERRADA |
