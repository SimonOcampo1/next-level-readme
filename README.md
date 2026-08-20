<p align="center">
  <img src="docs/banner.png" alt="next-level-readme" width="100%">
</p>

<p align="center">
  <img alt="Claude Code" src="https://img.shields.io/badge/Claude_Code-D97757?style=flat-square&logo=anthropic&logoColor=white">
  <img alt="PowerShell" src="https://img.shields.io/badge/PowerShell-5391FE?style=flat-square&logo=powershell&logoColor=white">
  <img alt="HTML5" src="https://img.shields.io/badge/HTML5-E34F26?style=flat-square&logo=html5&logoColor=white">
  <img alt="Sin dependencias" src="https://img.shields.io/badge/dependencias-0-1F2122?style=flat-square">
</p>

<p align="center">
  <a href="#qué-hace"><b>Qué hace</b></a> &nbsp;•&nbsp;
  <a href="#el-estándar">El estándar</a> &nbsp;•&nbsp;
  <a href="#el-generador-de-banners">Banners</a> &nbsp;•&nbsp;
  <a href="#instalación">Instalación</a> &nbsp;•&nbsp;
  <a href="#decisiones">Decisiones</a>
</p>

Una skill de Claude Code que escribe el README de un repo propio con un estándar fijo, y le genera el banner desde la paleta y las tipografías del proyecto real. Parte de una premisa incómoda: quien abre el repo de tu portfolio no lo va a mantener ni forkear — lo mira treinta segundos y decide si el proyecto vale algo. Todo el estándar sale de ahí.

## Qué hace

- **Escribe el README leyendo el código, no el README viejo.** Los detalles que ningún README genérico tiene son los que convencen: que el buscador necesita servidor porque hace `fetch` del índice, que el pipeline corre sin GPU en modo solo-retrieval.
- **Genera el banner desde la identidad real del proyecto** — paleta y fuentes copiadas del `:root` del sitio, no inventadas.
- **Saca los dos tamaños que hacen falta:** `banner.png` 1600×533 para el header y `social.png` 1280×640 para el *social preview* del repo, que es la imagen que aparece al compartir el link.
- **Tiene una lista explícita de lo que no va** y por qué: Contributing, Roadmap, tabla de contenidos, badges de `build passing`, el título repetido bajo el banner.
- **Prohíbe el vocabulario que dispara los detectores de slop** — *seamless, production-ready, robust, cutting-edge*. Un adjetivo que no se puede verificar mirando el repo, sobra.

## El estándar

```
BANNER 3:1                    el título vive adentro — no se repite abajo
badges                        pegados al banner, solo stack
nav row                       Demo • Características • Stack • Estructura • Instalación
───────────────────────────
intro                         2-3 frases: qué es, para quién, por qué existe
## Características            4-6 bullets, cada uno con el detalle técnico real
## Stack                      tabla: capa → tecnología → por qué esa
## Estructura                 árbol comentado, solo lo que importa
## Puesta en marcha           bash copiable + la nota del gotcha real
## Decisiones                 opcional, 2-3 líneas de lo no obvio
```

Techo de lectura: 90 segundos. Si no entra, la que sobra es Decisiones, no Características.

El molde es [Markdownify](https://github.com/amitmerchant1990/electron-markdownify) —una app presentándose a alguien que la va a mirar, no a mantenerla—, con el banner-que-contiene-el-título de [SDVersion](https://github.com/sebyddd/SDVersion). De [Best-README-Template](https://github.com/othneildrew/Best-README-Template) se toma el header centrado y se descarta el resto: Roadmap y Contributing son relleno en un repo que nadie va a forkear.

## El generador de banners

`banner.html` es el diseño, `make-banner.ps1` lo renderiza. Sin dependencias nuevas: usa el Chromium que ya está instalado.

```powershell
# 1. copiar la plantilla al repo
Copy-Item ~\.claude\skills\next-level-readme\banner.html docs\banner.html

# 2. editar SOLO el bloque CONFIG de arriba: paleta, fuentes, título, tagline

# 3. renderizar
pwsh -File ~\.claude\skills\next-level-readme\make-banner.ps1 -Src docs\banner.html
```

`docs/banner.html` queda versionado en el repo: es la fuente, el PNG es la salida. El banner de este mismo repo salió de ahí.

> [!IMPORTANT]
> Brave queda fuera de la lista de navegadores: en headless se cuelga sin escribir nada ni salir. El script usa Chrome o Edge, y Edge viene con Windows.

## Instalación

```bash
git clone https://github.com/SimonOcampo1/next-level-readme.git ~/.claude/skills/next-level-readme
```

En Windows, la ruta es `C:\Users\<vos>\.claude\skills\next-level-readme`. Después, dentro de Claude Code:

```
/next-level-readme
```

También se dispara sola cuando el pedido es del tipo "hacé el readme", "pulí el readme" o "generá el banner".

## Decisiones

**3:1 y no 16:9.** Un banner 16:9 al ancho del README mide ~506 px de alto: se come el primer scroll entero y empuja las Características abajo del fold. El social preview sí es 2:1, pero ahí la imagen *es* toda la tarjeta.

**Un `<p align="center">` por bloque, sin líneas en blanco adentro.** Envolver todo en un `<div align="center">` también funciona en GitHub, pero una línea en blanco cierra el bloque HTML en CommonMark estricto: los previewers locales escupen las etiquetas crudas. Y el preview local no es el renderer de destino — se verifica contra el real sin pushear nada:

```bash
gh api -X POST markdown -f mode=gfm -f text="$(cat README.md)" | head -40
```

**Dos trampas de Chromium headless en Windows**, las dos resueltas dentro del script: los espacios en la ruta rompen `--screenshot` en silencio (parte el argumento, no escribe nada, exit code 0), y un GUI app no bloquea la shell, así que hace falta `Start-Process -Wait`. Por eso el script es PowerShell y no bash.

**GIF descartado.** Necesita ffmpeg y captura de frames. Un PNG que convenza vale más que un GIF que no.
