# ADR — Decision D-CUENTAS: 4 cuentas Linux (sin `svc-dbdata`)

| Campo | Valor |
|-------|-------|
| ID | D-CUENTAS |
| Estado | **Aceptada** |
| Fecha de decision | 2026-05-21 |
| Decididor | Nestor Monroy |
| Fase | F0a — Validaciones iniciales |
| Iniciativa | [crear-template-ecomerce-ui-server][doc-iniciativa] |

## Contexto

El repo de referencia [`jcg-admin/e-comerce-server`][ref-ecomerce-server]
opera bajo el procedimiento externo
`Procedimiento-Implementacion-Almacenamiento-WSL2-ecomerce-p001 v1.0.0`
que define un **modelo de 5 cuentas Linux** con separacion
estricta de privilegios:

| Cuenta | UID | Funcion |
|--------|-----|---------|
| `deploy` | 1000 | Operador admin, sudo |
| `infra` | 1001 | Sudo granular NOPASSWD |
| `develop` | 1002 | Owner del codigo (sin sudo) |
| `svc-backups` | 999 | Backups del proyecto (nologin) |
| `svc-dbdata` | 997 | **Dumps de BD** (nologin) |

Nuestro repo `template-ecommerce-server` se inspira en ese
referente pero **no incluye gestion de base de datos** (la
decision D-BACKEND-AGNOSTIC establece que el server NO asume
tecnologia backend, y por extension tampoco BD).

La pregunta: ¿mantenemos `svc-dbdata` "por si acaso" o la
quitamos?

## Decision

**Modelo de 4 cuentas** (excluir `svc-dbdata`):

| Cuenta | UID | Funcion | Sudo | Login |
|--------|-----|---------|------|-------|
| `deploy` | 1000 | Operador admin, ejecuta provisioners | Si | Si |
| `infra` | 1001 | Sudo granular NOPASSWD por binario | Granular | Si |
| `develop` | 1002 | Owner del codigo del UI | NO | Si |
| `svc-backups` | 999 | Backups del proyecto | NO | nologin |

UIDs preservados identicos al referente (incluyendo el "gap"
entre 999 y 1000 — `svc-dbdata` ocupaba UID 997 y ya no se
crea).

## Alternativas evaluadas

### Alternativa 1: 5 cuentas, igual al referente (descartada)

**Pro**:

- Compatibilidad estructural total con el procedimiento
  externo de almacenamiento.
- Si en el futuro se anade BD, no hay refactor de cuentas.

**Contra**:

- **Cuenta sin uso real**: `svc-dbdata` quedaria creada pero
  sin owner de Clase C (que tampoco se crea). Confunde al
  operador.
- **YAGNI**: crear infraestructura "por si acaso" viola el
  principio de scope.
- **Auditorias futuras**: una cuenta nologin sin owner de
  archivos podria marcarse como anomala.

### Alternativa 2: 4 cuentas (elegida)

**Pro**:

- **Scope explicito**: el server NO gestiona BD, su cuenta
  asociada tampoco existe.
- **Mas simple de auditar**: cada cuenta tiene un proposito
  verificable.
- **Refactor trivial si cambia el scope**: si una futura
  iniciativa anade BD, anadir `svc-dbdata` es 1 comando
  `useradd`.

**Contra**:

- **Desviacion del procedimiento externo**: el procedimiento
  habla de 5 cuentas como modelo canonico. Documentar la
  desviacion explicitamente.

### Alternativa 3: 3 cuentas (fusionar `infra` en `deploy`) (descartada)

**Pro**:

- Aun mas simple.

**Contra**:

- **Pierde la separacion de privilegios**: `deploy` con sudo
  completo deja de ser admin de operacion y se convierte en
  super-root. Auditoria pierde granularidad.
- **No conserva el modelo del referente**: rompe la
  correspondencia conceptual.

## Consecuencias

### Positivas

- **Modelo mas simple**, alineado con el scope real del repo.
- **Documentacion mas clara**: cada cuenta tiene proposito
  verificable.
- **Auditoria facil**: no hay cuentas "fantasma" sin owner.

### Negativas

- **Pequena divergencia con el procedimiento externo**: hay
  que documentar la diferencia en cada lugar relevante
  (`docs/arquitectura.md`, `docs/seguridad.md`,
  `docs/glosario.md`, `.env.example`).
- **Si en el futuro se incluye BD**: hay que anadir
  `svc-dbdata` con UID 997 (preservando el UID canonico para
  compatibilidad con dumps existentes del procedimiento).

### Mitigaciones de las negativas

- Documentacion ya producida (commit `aca6b2e` + `ea54ec5`)
  registra explicitamente la diferencia en multiples docs.
- UID 997 reservado conceptualmente: si se anade `svc-dbdata`,
  preservarlo. Documentar esta reserva en este ADR.

## UIDs canonicos preservados

A pesar de excluir una cuenta, **mantenemos los UIDs canonicos
del procedimiento externo**:

```
1000  deploy        (creada)
1001  infra         (creada)
1002  develop       (creada)
 999  svc-backups   (creada)
 997  svc-dbdata    (RESERVADO; no se crea, futura BD)
```

Razon: si se monta un dump de Clase C generado por un sistema
con `svc-dbdata` UID 997, los permisos deben resolverse al UID
correcto, no a `nobody`. Reservar el UID evita conflictos
futuros.

## Implementacion

- F2: documentar las 4 cuentas en `.env.example` (sin variable
  para `svc-dbdata`).
- F10: documentar el modelo completo en
  [`docs/operaciones.md`][doc-operaciones] (paso a paso de
  creacion de cuentas, segun procedimiento externo).
- Provisioners no crean cuentas: el procedimiento externo lo
  hace. Los scripts del server **asumen** que las cuentas ya
  existen.

## Cumplimiento del procedimiento externo

`Procedimiento-Implementacion-Almacenamiento-WSL2-ecomerce-p001 v1.0.0`
contempla escenarios donde algun servicio no es necesario. La
exclusion de `svc-dbdata` cuando no hay BD es coherente con el
espiritu del procedimiento. **Esta desviacion se registra
formalmente en este ADR**.

## Referencias

- Procedimiento externo: `Procedimiento-Implementacion-Almacenamiento-WSL2-ecomerce-p001 v1.0.0`.
- Referente: [`jcg-admin/e-comerce-server`][ref-ecomerce-server],
  README seccion "Modelo de cuentas y layout de almacenamiento".
- Documentacion del modelo en este repo: [arquitectura,
  Componente 4][doc-arquitectura].
- Decision relacionada: [D-STORAGE][adr-storage] (clases de
  almacenamiento simplificadas a 2).
- Decision relacionada: D-BACKEND-AGNOSTIC (server no asume
  backend, por extension no asume BD).

<!-- Referencias Markdown -->
[doc-iniciativa]: ../pm/iniciativas/crear-template-ecomerce-ui-server/index.md
[doc-arquitectura]: ../arquitectura.md
[doc-operaciones]: ../operaciones.md
[adr-storage]: decision-storage-clases.md
[ref-ecomerce-server]: https://github.com/jcg-admin/e-comerce-server
