# Alcance — `crear-setup-sh`

## Que cubre

1. **Script `scripts/setup.sh`** con las siguientes
   capacidades:
   - Fase 1: instalar Nginx + endurecer SSH, luego pausa
     con instrucciones de reconexion.
   - Fase 2 (`--continue`): firewall + fail2ban + SSL +
     vhost + verify.
   - Flag `--skip-ssh`: omite ssh_hardening y elimina la
     pausa. Uso: WSL2, CI, entornos sin sshd.
   - Flag `--ssl-dev`: pasa `--dev` a `setup_ssl.sh`.
   - Flag `--ssl-staging`: pasa `--staging` a `setup_ssl.sh`.
   - Guard anti-lockout: verifica clave SSH en
     `~/.ssh/authorized_keys` antes de Fase 1.
   - Guard de prerequisitos: valida `.env` y variables
     requeridas antes de arrancar.
   - Idempotente: seguro de ejecutar multiples veces.

2. **Actualizacion de `README.md`**: quick start con
   `setup.sh` reemplazando la lista de 8 comandos manuales.

3. **Actualizacion de `docs/operaciones.md`**: seccion de
   aprovisionamiento con `setup.sh` como punto de entrada
   primario.

4. **Actualizacion de `docs/arquitectura.md`**: flujo 1
   (aprovisionar desde cero) con `setup.sh`.

5. **Cobertura de tests**: `test_provisioner_syntax.sh`
   cubre automaticamente `setup.sh` sin modificar los tests
   existentes.

## Criterio de completitud

1. `scripts/setup.sh` existe y pasa `bash -n`.
2. `test_provisioner_syntax.sh` incluye `setup.sh` con PASS.
3. `setup.sh --help` imprime usage completo con 4 flags.
4. Fase 1 ejecuta `install.sh` y `ssh_hardening.sh` en orden
   y pausa con mensaje claro de reconexion.
5. `setup.sh --continue` ejecuta firewall, fail2ban, ssl,
   vhost y verify en orden.
6. `setup.sh --skip-ssh` omite ssh_hardening y continua
   directo a Fase 2 sin pausa.
7. `--ssl-dev` y `--ssl-staging` pasan el flag a
   `setup_ssl.sh`.
8. `README.md`, `docs/operaciones.md` y
   `docs/arquitectura.md` actualizados.
9. `bash tests/run_all.sh` retorna PASS >= 72, FAIL = 0.

## Fuera de alcance

| Item | Razon |
|------|-------|
| `scripts/start.sh` | Iniciativa separada; problema distinto: arranque de daemons en WSL2 sin systemd |
| Modificar provisioners | Los provisioners existentes no cambian; `setup.sh` los invoca tal cual |
| CI/CD pipeline | `setup.sh` puede usarse desde CI pero no incluye definicion de workflow |
| Deploy del UI | El aprovisionamiento del server y el deploy del UI son operaciones independientes |
| Rollback de orquestacion | Los provisioners tienen rollback individual; `setup.sh` no agrega logica de rollback entre fases |
| Crear `.env` | El operador lo crea con `cp .env.example .env`; `setup.sh` valida que existe pero no lo genera |

## Estimacion de esfuerzo por fase

| Fase | Descripcion | Estimado |
|------|-------------|----------|
| F0 | Analisis + PM docs | 30 min |
| F1 | Crear `scripts/setup.sh` | 45 min |
| F2 | Actualizar `README.md`, `docs/operaciones.md`, `docs/arquitectura.md` | 20 min |
| F3 | Verificacion y cierre | 15 min |
| Total | | ~2 horas |

<!-- Referencias Markdown -->
[doc-plan]: plan-crear-setup-sh.md
[repo-server]: https://github.com/jcg-admin/template-ecommerce-server
