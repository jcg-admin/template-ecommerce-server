# ADR — Decision D-STORAGE: 2 clases de almacenamiento (sin C)

| Campo | Valor |
|-------|-------|
| ID | D-STORAGE |
| Estado | **Aceptada** |
| Fecha de decision | 2026-05-21 |
| Decididor | Nestor Monroy |
| Fase | F0a — Validaciones iniciales |
| Iniciativa | [crear-template-ecomerce-ui-server][doc-iniciativa] |

## Contexto

El procedimiento externo
`Procedimiento-Implementacion-Almacenamiento-WSL2-ecomerce-p001 v1.0.0`
define un **layout de tres clases de almacenamiento**:

| Clase | Path | Owner / perms | Contenido |
|-------|------|---------------|-----------|
| A | `/srv/repos/ecom/<repo>` | `develop:develop` 755/644 | Codigo de los submodulos |
| B | `/srv/backups/project` | `svc-backups:svc-backups` 755 | Backups del proyecto |
| C | `/srv/backups/database` | `svc-dbdata:svc-dbdata` 755 | Dumps de BD |

Nuestro repo no incluye gestion de BD (decision relacionada
[D-CUENTAS][adr-cuentas] que elimina la cuenta `svc-dbdata` por
no haber BD en scope).

La pregunta: ¿mantenemos la Clase C como reserva o la
eliminamos?

## Decision

**Layout de 2 clases** (excluir la Clase C):

| Clase | Path | Owner / perms | Contenido |
|-------|------|---------------|-----------|
| A | `/srv/repos/ecom/template-e-comerce-ui` | `develop:develop` 755/644 | Codigo del UI |
| B | `/srv/backups/project` | `svc-backups:svc-backups` 755 | Backups del proyecto |

Path canonico para el codigo: `/srv/repos/ecom/template-e-comerce-ui`
(con guion, nombre del [repo UI][repo-ui]).

## Alternativas evaluadas

### Alternativa 1: 3 clases, igual al referente (descartada)

**Pro**:

- Compatibilidad estructural con el procedimiento externo.
- Si en el futuro se anade BD, no hay refactor del layout.

**Contra**:

- **Directorio sin owner**: la Clase C requiere
  `svc-dbdata` que NO existe (D-CUENTAS). Crear el directorio
  con owner `root` rompe el modelo.
- **YAGNI**: directorios "por si acaso" generan confusion al
  operador y son anomalias en auditorias.
- **Riesgo de uso indebido**: un operador podria poner archivos
  en `/srv/backups/database/` pensando que es "el lugar de
  backups", cuando deberian ir a `/srv/backups/project/`.

### Alternativa 2: 2 clases (elegida)

**Pro**:

- **Layout alineado con el scope real**.
- **No genera directorios huerfanos**.
- **Coherente con D-CUENTAS** (la cuenta `svc-dbdata` no
  existe, por tanto su clase tampoco).

**Contra**:

- **Pequena divergencia con el procedimiento externo**.

### Alternativa 3: 1 clase, fusionar A y B (descartada)

**Pro**:

- Maximo de simplicidad.

**Contra**:

- **Pierde separacion** entre codigo (que `develop` edita
  diariamente) y backups (que solo `svc-backups` toca).
- **Riesgo de seguridad**: si `develop` accidentalmente
  borrase un backup, no habria audit trail claro.
- **Backups bajo `develop:develop`**: en caso de compromiso de
  la cuenta `develop`, los backups quedarian expuestos.

## Consecuencias

### Positivas

- **Layout claro**: A para codigo (modificable por `develop`),
  B para backups (solo `svc-backups` puede escribir).
- **Separacion de privilegios preservada**: backups no
  accesibles por la cuenta de desarrollo.
- **Path canonico definido**: `/srv/repos/ecom/template-e-comerce-ui`.

### Negativas

- **Si en el futuro se anade BD**: hay que crear
  `/srv/backups/database` con owner `svc-dbdata:svc-dbdata`
  (UID 997 reservado en [D-CUENTAS][adr-cuentas]).
- **Documentacion debe explicar la divergencia** vs
  procedimiento externo.

### Mitigaciones de las negativas

- UID 997 reservado conceptualmente para el dia que se anada
  BD; sin colision posible si se monta un dump de Clase C
  legacy.
- Documentacion ya producida ([arquitectura][doc-arquitectura]
  Componente 5, [seguridad][doc-seguridad] Storage layout,
  [glosario][doc-glosario]) explicita la diferencia con el
  referente.

## Permisos canonicos

Detalle aplicado en F4/F5/F6 a los componentes que tocan estos
paths:

### Clase A — `/srv/repos/ecom/template-e-comerce-ui`

```
owner: develop:develop
dir:   0755
file:  0644
```

Razon: `develop` tiene control total (edicion de codigo,
ejecucion de `git`, `npm`, etc.). `www-data` (que ejecuta
Nginx workers) lee como "other" gracias al `0755`/`0644`,
**sin** estar en el grupo `develop`.

### Clase B — `/srv/backups/project`

```
owner: svc-backups:svc-backups
dir:   0755
file:  0644
```

Razon: solo `svc-backups` (nologin) puede escribir aqui.
Tareas cron que generan backups corren como `svc-backups`. Los
backups son world-readable para permitir auditoria, pero
solo `svc-backups` los modifica.

### Path SSL — `/etc/ssl/$DOMAIN/`

No es Clase A ni B; **es un path de sistema**, no de
aplicacion. Reglas separadas:

```
$SSL_CERT_DIR/:        owner root:root, mode 0755
cert.pem:              owner root:root, mode 0644
fullchain.pem:         owner root:root, mode 0644
key.pem:               owner root:root, mode 0600
```

Razon: Nginx master corre como `root`, lee `key.pem` antes
de drop-privileges a `www-data`. Los workers `www-data` nunca
ven la key.

## Path canonico para el UI

El path canonico es `/srv/repos/ecom/template-e-comerce-ui`
(notese el **guion** entre `e` y `comerce`, siguiendo el naming
del [repo UI][repo-ui]).

Diferencias intencionales con el referente:

- Referente usa `/srv/repos/ecom/<repo>` con `<repo>` variable
  (multiples submodulos).
- Nuestro repo solo tiene **un consumer**: el repo UI. El path
  es fijo.

Si en el futuro se sirven multiples UIs, hay que generalizar
(no contemplado en este ADR).

## Implementacion

- F2: `.env.example` define `UI_DIST` con path canonico de
  Clase A.
- F4: `setup_vhost.sh` valida que `$UI_DIST` existe y es
  legible por `www-data`.
- F5: `setup_ssl.sh` crea `$SSL_CERT_DIR` con permisos
  canonicos.
- F8: `verify.sh` chequea permisos canonicos de A, B y SSL.
- F10: documentar el layout completo en [operaciones][doc-operaciones].

## Cumplimiento del procedimiento externo

`Procedimiento-Implementacion-Almacenamiento-WSL2-ecomerce-p001 v1.0.0`
es **descriptivo no prescriptivo**: define las clases que existen
cuando aplican. Excluir Clase C cuando no hay BD es coherente
con el procedimiento, no una violacion.

## Referencias

- Procedimiento externo: `Procedimiento-Implementacion-Almacenamiento-WSL2-ecomerce-p001 v1.0.0`.
- Referente: [`jcg-admin/e-comerce-server`][ref-ecomerce-server],
  README seccion "Modelo de cuentas y layout de almacenamiento".
- Documentacion en este repo: [arquitectura, Componente 5][doc-arquitectura],
  [seguridad, Storage layout][doc-seguridad],
  [glosario][doc-glosario].
- Decision relacionada: [D-CUENTAS][adr-cuentas].

<!-- Referencias Markdown -->
[doc-iniciativa]: ../pm/iniciativas/crear-template-ecomerce-ui-server/index.md
[doc-arquitectura]: ../arquitectura.md
[doc-seguridad]: ../seguridad.md
[doc-glosario]: ../glosario.md
[doc-operaciones]: ../operaciones.md
[adr-cuentas]: decision-modelo-cuentas.md
[repo-ui]: https://github.com/jcg-admin/template-e-comerce-ui
[ref-ecomerce-server]: https://github.com/jcg-admin/e-comerce-server
