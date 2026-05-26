# Decisiones: Agregar logging a archivo en scripts y provisioners

| Campo | Valor |
|-------|-------|
| Iniciativa | INI-SRV-009 agregar-logging-a-archivo |
| Tipo de documento | Decisiones, hallazgos y verificacion post-ejecucion |
| Obligatoriedad | Obligatorio al cierre segun PROC-GESTION-001 v4.0.0 |
| Fecha de creacion | 2026-05-26 |

> **Por que existe este documento.** Las tareas dicen *que* se hizo.
> El progreso dice *cuanto*. Este documento registra el *por que*,
> los *hallazgos* y la *verificacion final*.

---

## Seccion 1 — Decisiones de diseno

### dec-un-solo-archivo-acumulativo

| Campo | Valor |
|-------|-------|
| Decision | Un solo archivo acumulativo `logs/operations.log` para todos los scripts y provisioners. |
| Alternativas | (a) Un solo archivo acumulativo (elegida). (b) Un archivo por script: `verify.log`, `setup.log`, etc. (c) Un archivo por dia con fecha en el nombre. |
| Razon | La alternativa (a) permite correlacion temporal entre operaciones. Un `tail -f logs/operations.log` muestra todo lo que ocurre sin importar que script se ejecuta. La alternativa (b) fragmenta el historial: para diagnosticar un problema que involucra setup.sh + provisioners hay que consultar varios archivos. La alternativa (c) complica la implementacion sin beneficio real para este volumen de operaciones. |
| Trade-off aceptado | Un solo archivo acumulativo puede volverse difuso si muchos scripts se ejecutan en paralelo (las entradas se intercalan). Para el uso normal de este repo (operaciones secuenciales, no paralelas), esto no es un problema. |

### dec-init-log-sin-modificar-logging-sh

| Campo | Valor |
|-------|-------|
| Decision | Usar `init_log` de `utils/logging.sh` sin modificar ese archivo. Solo agregar la llamada en cada script. |
| Alternativas | (a) Llamar `init_log` en cada script sin modificar logging.sh (elegida). (b) Modificar logging.sh para que `init_log` se llame automaticamente al hacer source. (c) Usar `exec > >(tee -a logfile) 2>&1` en cada script. |
| Razon | La alternativa (b) cambia el comportamiento de logging.sh para todos los consumidores actuales y futuros; es un cambio de contrato no solicitado. La alternativa (c) captura stdout/stderr de todo el proceso incluyendo salida de subcomandos que ya redirigen a /dev/null; puede producir duplicados. La alternativa (a) es la menos invasiva y la que respeta el diseno original de logging.sh. |
| Trade-off aceptado | Requiere agregar una linea en cada script nuevo que se cree. Es una disciplina a mantener, no una garantia automatica. |

### dec-gitkeep-para-permisos-correctos

| Campo | Valor |
|-------|-------|
| Decision | Versionar `logs/.gitkeep` para que el directorio `logs/` exista con propietario `develop` desde el clon inicial. |
| Alternativas | (a) `.gitkeep` versionado (elegida). (b) Crear `logs/` en `install.sh` con `chown develop:develop`. (c) Modificar `init_log` para hacer `chmod 777 "$log_dir"` al crear el directorio. |
| Razon | La alternativa (b) acopla la creacion del directorio de logs al provisioner de Nginx, que no tiene relacion logica con el logging. La alternativa (c) modifica logging.sh (violando D-INIT-LOG-EXISTENTE) y establece permisos permisivos en el directorio. La alternativa (a) es la mas simple: el directorio existe desde el clon con el propietario correcto, sin codigo adicional. |
| Trade-off aceptado | Si alguien borra manualmente el directorio `logs/` y el proximo script en ejecutarse es un provisioner como root, `logs/` quedara con propietario root y develop no podra escribir. Es un edge case que se documenta en el analisis. |

### dec-gitignore-logs-log-no-directorio

| Campo | Valor |
|-------|-------|
| Decision | Usar `logs/*.log` + `!logs/.gitkeep` en `.gitignore` en lugar de `logs/`. |
| Alternativas | (a) `logs/*.log` + `!logs/.gitkeep` (elegida). (b) `logs/` que ignora todo el directorio. |
| Razon | El `.gitignore` existente ya tenia `logs/` que ignoraba incluso `logs/.gitkeep`. Con `logs/` ignorado, `git add logs/.gitkeep` falla silenciosamente. La alternativa (a) permite que `.gitkeep` sea rastreado por git mientras que los archivos `.log` siguen siendo ignorados. |
| Trade-off aceptado | Un desarrollador que cree un archivo con otro nombre dentro de `logs/` (ej: `logs/notas.txt`) lo vera como no-ignorado por git. Se acepta: el directorio `logs/` es para logs y solo deberia contener `.log` files y `.gitkeep`. |

### dec-sin-rotacion-automatica

| Campo | Valor |
|-------|-------|
| Decision | No implementar rotacion automatica de logs en esta iniciativa. |
| Alternativas | (a) Sin rotacion (elegida). (b) Agregar un cron que rota el log semanalmente. (c) Usar `logrotate` con una configuracion custom para `operations.log`. |
| Razon | La alternativa (b) requiere modificar el crontab del sistema y decidir la frecuencia y la politica de retencion, decisiones que merecen su propio analisis. La alternativa (c) es mas robusta pero igualmente requiere analisis de configuracion. El volumen de escrituras en `operations.log` es bajo (texto plano, operaciones ocasionales); el archivo tardara meses en crecer de forma significativa. |
| Trade-off aceptado | El archivo crece indefinidamente. El operador debe rotar manualmente cuando lo considere necesario. Instrucciones documentadas en `docs/operaciones.md`. |

---

## Seccion 2 — Hallazgos durante la ejecucion

### hallazgo-gitignore-ignoraba-gitkeep

El `.gitignore` existente tenia la entrada `logs/` que ignoraba
todo el directorio incluyendo `logs/.gitkeep`. Esto impedia que
`.gitkeep` fuera rastreado por git, lo que hubiera dejado el
directorio `logs/` sin crear al clonar.

Corregido en T-101: entrada cambiada a `logs/*.log` +
`!logs/.gitkeep`.

### hallazgo-subprocesos-no-heredan-log-file

`_LOG_FILE` es una variable del proceso bash actual. Cuando
`setup.sh` llama `bash provisioners/nginx/install.sh`, ese es
un subproceso nuevo con su propio entorno. `_LOG_FILE` no se
hereda entre procesos bash a menos que se exporte.

Por eso cada script necesita su propia llamada a `init_log`.
Como todos usan el mismo nombre `"operations"`, todos appendean
al mismo archivo `logs/operations.log`. El resultado es un log
acumulativo con bloques de distintos scripts intercalados
cronologicamente.

Esto es el comportamiento correcto y deseado.

### hallazgo-verificacion-funcional-exitosa

La verificacion funcional en T-301 confirmo:

1. `init_log "operations"` crea `logs/operations.log` si no existe.
2. Dos llamadas consecutivas generan dos bloques `=== Inicio ===`
   acumulados en el mismo archivo.
3. Las entradas del log no tienen codigos ANSI (logging.sh omite
   colores cuando stdout no es terminal; `_write_log` escribe
   directamente al archivo sin pasar por stdout).
4. `git ls-files logs/` muestra solo `logs/.gitkeep`.
   `logs/operations.log` no aparece en git (correctamente ignorado).

---

## Seccion 3 — Verificacion post-ejecucion

| Criterio del alcance | Resultado | Evidencia |
|---------------------|-----------|-----------|
| `logs/.gitkeep` existe en el repo | PASA | `git ls-files logs/` muestra `logs/.gitkeep` |
| `logs/` en `.gitignore` con `logs/*.log` | PASA | `.gitignore` tiene `logs/*.log` + `!logs/.gitkeep` |
| `git ls-files logs/` muestra solo `.gitkeep` | PASA | Verificado en T-301 |
| Los 10 scripts tienen `init_log "operations"` | PASA | `grep -l "init_log" scripts/*.sh provisioners/**/*.sh` = 10 archivos |
| `init_log` crea `logs/operations.log` al ejecutar | PASA | Verificacion funcional en T-301 |
| Dos ejecuciones acumulan en el mismo archivo | PASA | Dos bloques `=== Inicio ===` en el log de prueba |
| `bash tests/run_all.sh`: PASS >= 74, FAIL = 0 | PASA | 74 PASS / 0 FAIL / 1 SKIP |
| Auditoria de links: sin nuevos rotos | PASA | 148 OK, 3 falsos positivos conocidos |

## Cierre

Esta iniciativa esta **cerrada**. Los 8 criterios de completitud
se cumplen. Los 3 hallazgos estan documentados. Las 5 decisiones
de diseno tienen alternativas y trade-offs registrados.
