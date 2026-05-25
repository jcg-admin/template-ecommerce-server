# Analisis: Actualizar README y crear indice de documentacion

## Inventario de gaps en README.md

### Gap 1 — Tabla de inventario: scripts operativos incompleta

El README actual lista solo 2 scripts operativos:

```
| Scripts operativos | scripts/verify.sh + renew_ssl.sh | 802 |
```

Los scripts existentes son 4:

| Script | LOC | Iniciativa que lo produjo |
|--------|-----|--------------------------|
| `scripts/setup.sh` | 344 | INI-SRV-005 |
| `scripts/start.sh` | 150 | INI-SRV-006 |
| `scripts/verify.sh` | 633 | INI-SRV-001 |
| `scripts/renew_ssl.sh` | 191 | INI-SRV-001 |
| **Total** | **1318** | |

### Gap 2 — Tabla de inventario: LOC de tests desactualizado

```
| Tests bash | tests/ (6 scripts) | 707 |   ← incorrecto
```

LOC real de tests: **907** (medido con `wc -l tests/*.sh`).

### Gap 3 — Tabla de inventario: LOC de provisioners

```
| Provisioners | provisioners/ (6 archivos) | 2315 |   ← incorrecto
```

LOC real de provisioners: **2326**.

### Gap 4 — Tests: PASS count desactualizado

```
Tests agregados: 5 suites OK, 72 PASS / 0 FAIL / 1 SKIP   ← incorrecto
```

Estado actual: **74 PASS / 0 FAIL / 1 SKIP**
(+1 por `setup.sh` en INI-SRV-005, +1 por `start.sh` en INI-SRV-006).

### Gap 5 — Estado del repo: solo menciona INI-SRV-001

```
Iniciativa crear-template-ecomerce-ui-server cerrada:
12 fases, 31 tareas, 29 commits.
```

El repo tiene 7 iniciativas cerradas y 1 en ejecucion (INI-SRV-008).
Total de commits: 61.

## Estructura de docs/ existente vs modelo UI

### Estructura actual del server

```
docs/
  arquitectura.md              # Diagramas, flujos, decisiones D-*
  operaciones.md               # Walkthrough, recuperacion, FAQ
  seguridad.md                 # Modelo de amenazas, controles
  glosario.md                  # Terminos del dominio
  upgrade-server-systemless.md # WSL2, contenedores, CI
  desarrollo/
    analisis-gaps-server.md    # Analisis de gaps INI-SRV-007
  pm/
    como-gestionar-iniciativas.md  # (no existe; esta en el UI)
    indice-de-iniciativas.md
    iniciativas/
      INI-SRV-001..008/
```

No existe `docs/README.md`.

### Modelo del UI (referencia)

```
docs/
  README.md                    ← punto de entrada con indice de cajones
  como-adaptar-este-template.md
  introduccion-y-objetivos/
  restricciones-de-arquitectura/
  contexto-y-alcance-del-sistema/
  estrategia-de-solucion/
  vista-de-bloques-de-construccion/
  vista-de-despliegue/
  conceptos-transversales/
  decisiones-de-arquitectura/
  riesgos-y-deuda-tecnica/
  glosario/
  pm/
```

### Mapa de cajones arc42 para el server

| Cajon arc42 | Estado en server | Mapeo |
|-------------|-----------------|-------|
| Introduccion y objetivos | Ausente | Parcialmente en README.md |
| Restricciones de arquitectura | Ausente | — |
| Contexto y alcance | Ausente | Parcialmente en arquitectura.md |
| Estrategia de solucion | Ausente | Parcialmente en arquitectura.md |
| Vista de bloques de construccion | Ausente | — |
| Vista de despliegue | Ausente | Parcialmente en arquitectura.md flujos |
| Conceptos transversales | Ausente | — |
| Decisiones de arquitectura | Parcial | Decisiones D-* en arquitectura.md |
| Riesgos y deuda tecnica | Ausente | — |
| Glosario | Existe | `glosario.md` |
| Operaciones | Existe (extra-arc42) | `operaciones.md` |
| Seguridad | Existe (extra-arc42) | `seguridad.md` |
| Entornos sin systemd | Existe (extra-arc42) | `upgrade-server-systemless.md` |
| Desarrollo | Existe | `desarrollo/` |
| PM | Existe | `pm/` |

Los 3 cajones "extra-arc42" (operaciones, seguridad, entornos
sin systemd) son propios del dominio devops y no tienen equivalente
directo en arc42. Se documentan como cajones propios del proyecto.
