# Documentacion de template-ecommerce-server

Este directorio contiene la documentacion de arquitectura y gestion
del servidor web **template-ecommerce-server** (Nginx + SSL + fail2ban
+ UFW + SSH hardening sobre Ubuntu 24.04), construida sobre una
adaptacion pragmatica de arc42 mas un modulo de project management
(`pm/`) que sigue el procedimiento interno **PROC-GESTION-001** para
iniciativas.

> No se usan numeros en los nombres de carpetas. Cada archivo lleva
> el nombre del cajon que contiene, en castellano, autodescriptivo.

## Indice

### Punto de entrada para operadores

| Documento | Que contiene |
|-----------|--------------|
| [`../README.md`](../README.md) | Arquitectura 3-tier, quick start, inventario de scripts, modelo de cuentas, diferencias con el referente. **Leer primero al clonar el repo.** |
| [`operaciones.md`](operaciones.md) | Walkthrough de aprovisionamiento VPS Ubuntu desde cero (8 secciones), recuperacion de fallos, FAQ, apendices. Referencia operativa completa. |
| [`upgrade-server-systemless.md`](upgrade-server-systemless.md) | Entornos sin systemd: WSL2, contenedores, CI. Como arrancar daemons con `start.sh`, limitaciones y workarounds. |

### Documentacion de arquitectura

| Archivo | Que contiene |
|---------|--------------|
| [`arquitectura.md`](arquitectura.md) | Diagramas de flujo (aprovisionamiento, peticion HTTP, renovacion SSL), componentes del sistema, decisiones de diseno D-* con justificacion y alternativas descartadas. Equivale a los cajones de contexto, estrategia de solucion, vista de despliegue y decisiones de arquitectura de arc42. |
| [`seguridad.md`](seguridad.md) | Modelo de amenazas, controles implementados (UFW, fail2ban, SSH hardening, SSL/TLS), perfiles de riesgo y verificacion. |
| [`glosario.md`](glosario.md) | Definiciones de terminos del dominio devops y del proyecto: provisioner, daemon, vhost, jail, Clase A/B, svc-backups, etc. |
| [`desarrollo/`](desarrollo/) | Documentos de analisis para decisiones tecnicas especificas: eleccion de Nginx vs Apache, gaps entre el analisis y la implementacion. |

### Gestion del proyecto

| Carpeta | Que contiene |
|---------|--------------|
| [`pm/`](pm/) | Project management. Iniciativas INI-SRV-001..008 con alcance, analisis, plan, tareas, progreso y decisiones segun PROC-GESTION-001. Ver [`pm/indice-de-iniciativas.md`](pm/indice-de-iniciativas.md). |

## Cajones arc42 que este proyecto no documenta (y por que)

| Cajon arc42 | Razon de ausencia |
|-------------|-------------------|
| Introduccion y objetivos | Cubierto parcialmente en el `README.md` raiz (tabla de metadata, arquitectura 3-tier, diferencias con el referente). No se duplica en un cajon separado hasta que el contenido justifique la separacion. |
| Restricciones de arquitectura | Las restricciones de Ubuntu 24.04, bash, Nginx 1.24+ y el modelo de cuentas estan embebidas en `arquitectura.md` y `operaciones.md`. No hay suficiente masa critica para un cajon propio todavia. |
| Contexto y alcance del sistema | El sistema tiene un contexto muy acotado: sirve un bundle React via Nginx y proxea `/api/*` a un backend externo. El diagrama 3-tier del `README.md` lo captura completo. |
| Estrategia de solucion | La eleccion de Nginx vs Apache esta documentada en `docs/desarrollo/` (analisis del repo UI) y en `arquitectura.md`. No se crea cajon separado por la misma razon que el anterior. |
| Vista de bloques de construccion | El "codigo" de este repo son scripts bash, no modulos de software. La estructura de directorios es autodescriptiva y se documenta en el `README.md`. Un diagrama de bloques no aportaria claridad adicional. |
| Vista de despliegue | Parcialmente cubierta en `arquitectura.md` (flujos) y en `operaciones.md` (walkthrough). El despliegue es tan simple (un solo servidor Ubuntu) que no justifica un cajon propio. |
| Conceptos transversales | Los patrones que cruzan scripts (idempotencia, guards, logging via utils/, deteccion de systemd) estan en los propios scripts y en `arquitectura.md`. No hay suficiente masa critica para un cajon separado. |
| Riesgos y deuda tecnica | Deuda conocida: falta de upstream.conf (D-UPSTREAM-CONF-NO-APLICA), cajones arc42 ausentes (esta tabla). Se documentaran en cajon propio cuando la deuda acumulada justifique la separacion. |
| Requisitos de calidad (NFRs) | Este repo no tiene ANS/SLO declarados ni metricas de calidad medibles. Cuando existan se anadira como cajon propio. Misma razon que el UI. |

## Convenciones de esta documentacion

- **Sin emojis, sin iconos.** Texto plano y tablas markdown.
- **Sin numeros en nombres de archivos.** Nombre autodescriptivo.
- **Diagramas en mermaid embebido.** GitHub los renderiza nativamente.
- **Slug autoexplicativo.** Cada archivo se entiende fuera de su carpeta.
- **Estado real, no aspiracional.** Si algo no esta documentado, se
  declara explicitamente como ausente. No se crean documentos vacios.
- **Iniciativas en lugar de branches.** Los cambios se registran en
  iniciativas PM (INI-SRV-*) siguiendo PROC-GESTION-001 v4.0.0 + arc42.
