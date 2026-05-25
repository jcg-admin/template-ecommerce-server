# Decisiones: Crear script de aprovisionamiento unificado

| Campo | Valor |
|-------|-------|
| Iniciativa | INI-SRV-005 crear-setup-sh |
| Tipo de documento | Decisiones, hallazgos y verificacion post-ejecucion |
| Obligatoriedad | Obligatorio al cierre segun PROC-GESTION-001 v4.0.0 |
| Fecha de creacion | 2026-05-25 |

> **Por que existe este documento.** Las tareas dicen *que* se hizo.
> El progreso dice *cuanto*. Este documento registra el *por que*,
> los *hallazgos* y la *verificacion final*.

---

## Seccion 1 — Decisiones de diseno

### dec-dos-fases-con-continue

| Campo | Valor |
|-------|-------|
| Decision | `setup.sh` opera en dos fases separadas por una pausa explicita de reconexion SSH. |
| Alternativas | (a) Dos fases con `--continue` (elegida). (b) Un solo script con advertencia en pantalla sin pausa. (c) Un script interactivo que espera confirmacion del operador. |
| Razon | La alternativa (b) es insegura: el operador podria no leer la advertencia y seguir ejecutando, perdiendo la sesion SSH cuando UFW activa el nuevo puerto. La alternativa (c) es interactiva y no automatizable en CI. La alternativa (a) hace imposible continuar sin la accion explicita del operador. |
| Trade-off aceptado | El operador debe ejecutar dos comandos separados. El flujo es menos fluido que un solo comando pero la seguridad lo justifica. |

### dec-skip-ssh-para-entornos-sin-sshd

| Campo | Valor |
|-------|-------|
| Decision | Flag `--skip-ssh` para omitir ssh_hardening y la pausa de reconexion. |
| Alternativas | (a) `--skip-ssh` (elegida). (b) Deteccion automatica de si el entorno tiene sshd. (c) No soportar entornos sin sshd (documentar solo el flujo de produccion). |
| Razon | La alternativa (b) es fragil: la deteccion de sshd puede dar falsos positivos en entornos hibridos. La alternativa (c) excluye WSL2 que es el entorno de desarrollo principal. La alternativa (a) es explicita y controlada por el operador. |
| Trade-off aceptado | El operador debe saber que flag usar segun su entorno. Se documenta claramente en `--help` y en README. |

### dec-orquestador-sin-logica-propia

| Campo | Valor |
|-------|-------|
| Decision | `setup.sh` invoca provisioners como subprocesos sin reimplementar su logica interna. |
| Alternativas | (a) Orquestador delgado (elegida). (b) Orquestador que replica y extiende la logica de los provisioners. |
| Razon | La alternativa (b) duplica logica y crea dos fuentes de verdad. Si un provisioner cambia, hay que actualizar en dos lugares. La alternativa (a) hace a `setup.sh` un coordinador puro: su unico valor es el orden y los guards previos. |
| Trade-off aceptado | Si un provisioner falla, `setup.sh` falla con el mismo codigo de salida del provisioner sin dar contexto adicional. El operador debe consultar el output del provisioner fallido. |

---

## Seccion 2 — Hallazgos durante la ejecucion

### hallazgo-bash-interpreta-exclamacion-en-dobles-comillas

Al hacer el commit inicial con `git commit -m "..."` y el cuerpo
contenia `!backups/.gitkeep`, bash interpreto `!` como expansion
de historial y lo elimino del mensaje. El commit quedo con el
cuerpo incompleto.

Resolucion: `git commit --amend` para corregir el mensaje.

Leccion generalizable: siempre usar `git commit` sin `-m` para
abrir el editor cuando el mensaje del cuerpo contiene caracteres
especiales (`!`, `$`, backticks). El editor no aplica expansion
de shell.

### hallazgo-test-provisioner-syntax-cubre-setup-sh-automaticamente

`test_provisioner_syntax.sh` usa `find ... -name "*.sh"` sobre
todo el repo. Al crear `scripts/setup.sh`, quedo cubierto
automaticamente sin modificar el test. El PASS count paso de
17 a 18.

---

## Seccion 3 — Verificacion post-ejecucion

| Criterio del alcance | Resultado | Evidencia |
|---------------------|-----------|-----------|
| `scripts/setup.sh` existe y pasa `bash -n` | PASA | `bash -n scripts/setup.sh` retorna 0 |
| `test_provisioner_syntax.sh` cubre `setup.sh` con PASS | PASA | 18 PASS / 0 FAIL (era 17) |
| `setup.sh --help` imprime usage con 4 flags | PASA | Output incluye `--continue`, `--skip-ssh`, `--ssl-dev`, `--ssl-staging` |
| Fase 1 ejecuta `install.sh` + `ssh_hardening.sh` + pausa | PASA | Revision manual del codigo de `_run_fase1` |
| `--continue` ejecuta Fase 2 en orden correcto | PASA | Revision manual del codigo de `_run_fase2` |
| `--skip-ssh` omite ssh_hardening y continua directamente | PASA | Revision manual del flujo en `_run_fase1` |
| `README.md` con 3 flujos de `setup.sh` | PASA | Quick start actualizado |
| `docs/operaciones.md` con `setup.sh` como punto primario | PASA | Seccion 4 actualizada |
| `docs/arquitectura.md` con diagrama de dos fases | PASA | Flujo 1 actualizado |
| `bash tests/run_all.sh`: PASS >= 73, FAIL = 0 | PASA | 73 PASS / 0 FAIL / 1 SKIP |

## Cierre

Esta iniciativa esta **cerrada**. Los 10 criterios de completitud
se cumplen. Los 2 hallazgos estan documentados (uno con leccion
generalizable). Las 3 decisiones de diseno tienen alternativas y
trade-offs registrados.
