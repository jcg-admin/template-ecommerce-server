# Analisis — `integrar-commits-backup-20260522`

## Inventario del backup

| Campo | Valor |
|-------|-------|
| Archivo | `template-ecommerce-server-FULL-20260522-050927-source.tar.gz` |
| Tamano comprimido | 1.1M |
| MD5 | `1683e93eeae20e9e0447b493f29b2de2` |
| HEAD del backup | `fd5fda856663e2a51400322413fae236b1f653d9` |
| Branch | `main` |
| Commits en backup | 31 |
| Working tree al momento del backup | Limpio |

Verificacion MD5:

```
md5sum = 1683e93eeae20e9e0447b493f29b2de2  (calculado)
md5sum = 1683e93eeae20e9e0447b493f29b2de2  (archivo .md5)
Resultado: OK
```

## Comparacion de historiales

Estado del repo activo antes de la integracion:

| Campo | Valor |
|-------|-------|
| HEAD | `03d6bba65bf28f8ff61a9867447d105f27b41a4a` |
| Commits | 30 |

Commits presentes en el backup y ausentes en el repo activo:

| Hash | Subject | Archivos afectados |
|------|---------|-------------------|
| `10abbf9` | Update README to reflect closed initiative | 1 (README.md) |
| `fd5fda8` | Rename to template-ecommerce-server (F2) | 28 archivos |

Punto de divergencia: `2eea509` (presente en ambos historiales).

## Impacto de los commits faltantes

El commit `fd5fda8` es el de mayor impacto. Reemplaza
`template-ecomerce-ui-server` por `template-ecommerce-server`
en 28 archivos (91 lineas). Su ausencia dejaba nomenclatura
desincronizada en:

- `utils/` (4 archivos)
- `provisioners/` (6 archivos)
- `scripts/` (2 archivos)
- `tests/` (1 archivo)
- `docs/` (15 archivos)

Verificacion pre-integracion:

```bash
grep -r "template-ecomerce-ui-server" \
    --include="*.sh" --include="*.md" --include="*.conf" -l
# 28 archivos con nomenclatura vieja
```

## Estrategia de integracion

Cherry-pick en orden cronologico usando el repo del tarball
como remoto local. Esto preserva autor, fecha y mensaje
original de cada commit.

Orden de aplicacion:

1. `10abbf9` primero (solo README, sin conflictos esperados)
2. `fd5fda8` segundo (renombre masivo sobre base limpia)

## Riesgos identificados

| ID | Riesgo | Mitigacion |
|----|--------|------------|
| R-1 | Conflictos en cherry-pick de `fd5fda8` por cambios posteriores | Los unicos commits post-divergencia en el repo activo son `03d6bba` (`.gitignore` y `backups/.gitkeep`), sin solapamiento con los 28 archivos del renombre. Riesgo nulo. |
| R-2 | `dubious ownership` al acceder a Clase B desde `develop` | Esperado. Se resuelve con `git config --global --add safe.directory`. Documentado como D-SAFE-DIRECTORY. |

## Conclusion

Integracion de bajo riesgo. Dos commits cherry-pickeables sin
conflictos. El resultado esperado es un repo con 32 commits,
nomenclatura correcta en todos los archivos operativos, e
historial original preservado.
