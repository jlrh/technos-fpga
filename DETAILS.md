# technos-fpga

🇬🇧 English (below) · [🇪🇸 Español](#español)

FPGA recreations of **Technos Japan** arcade boards, built on the **JTFRAME** framework (GPLv3). MiSTer target.

> ℹ️ Independent project — **NOT** an official jotego core. Built on his GPLv3 JTFRAME framework.

## Cores

### Shadow Force (Technos, 1993)
Side-scrolling beat-'em-up (TA-0032 board). Hardware: **MC68000** main CPU (14 MHz) + **Z80** sound CPU +
**YM2151** (FM) + **OKI M6295** (ADPCM) + the Technos video customs **TJ-002 / TJ-004 / TJ-005**, written
from scratch for this core: two 16×16 6bpp scroll layers, an 8×8 4bpp text layer, 512 sprites of 16×16 5bpp
(up to 8 tiles tall), global brightness, and the per-line raster interrupt that the title screen uses for its
wave effect. 320×240, 15.625 kHz / 57.44 Hz.

**Status: runs on MiSTer** — boots through its RAM/ROM check and plays its attract mode on hardware. In
simulation, the video matches MAME pixel-for-pixel in 120 of 120 reference scenes (attract and gameplay); the
sound path (Z80 + YM2151 + OKI) follows MAME's sound commands, with the FM/ADPCM balance measured against MAME.
Not implemented yet: **flip screen**, and the **US version** (`shadfrceu`, 6 buttons).

A prebuilt `.rbf` is in [`releases/`](releases/) — **distributable**: all game ROMs are loaded at **runtime**
from the `.mra`; the bitstream bakes no game data. Or build from source (`cores/shadfrce/`). See
[`BUILD.md`](BUILD.md).

## Build

This repo contains **only the core code** (`cores/<core>/`). The framework and third-party cores (jtframe,
jt51, jt6295) are **not included** — jtframe provides them. Quick version:

1. Clone [jtcores](https://github.com/jotego/jtcores) (brings jtframe + modules).
2. Copy this repo's `cores/<core>/` into your jtcores checkout.
3. Build: `jtcore <core> -mister -c` (e.g. `jtcore shadfrce -mister -c`).

📋 **Step-by-step in [`BUILD.md`](BUILD.md).**

## ROMs

**Not included** (copyrighted material). Bring your own MAME romset (**merged**, MAME 0.288, `shadfrce.zip`).
The `.mra` describes how to assemble it; every ROM is loaded at runtime.

## Credits

- **JTFRAME**, **jt51**, **jt6295** — the GPLv3 frameworks and modules this core is built on
- **MAME** — hardware reference (`technos/shadfrce.cpp` driver by David Haywood, with later work by Pierpaolo
  Prazzoli)

## Acknowledgements

- To **Sorgelig** and the whole **MiSTer FPGA** project and community.
- To the **MAME community**, for the preservation and reverse-engineering work without which this core would
  not be possible.
- And to **Anthropic**, for **Claude**.

## License

**GPLv3** (see [`LICENSE`](LICENSE)) — required by the JTFRAME / jt51 / jt6295 dependencies; their copyright
notices are preserved in the sources.

---

## Español

🇪🇸 Español · [🇬🇧 English ↑](#technos-fpga)

Recreaciones en FPGA de placas arcade de **Technos Japan**, construidas sobre el framework **JTFRAME** (GPLv3).
Objetivo MiSTer.

> ℹ️ Proyecto independiente — **NO** es un core oficial de jotego. Construido sobre su framework JTFRAME (GPLv3).

## Cores

### Shadow Force (Technos, 1993)
Beat-'em-up de scroll lateral (placa TA-0032). Hardware: **MC68000** (14 MHz) + **Z80** de sonido +
**YM2151** (FM) + **OKI M6295** (ADPCM) + los customs de vídeo de Technos **TJ-002 / TJ-004 / TJ-005**,
escritos de cero para este core: dos capas de scroll de 16×16 a 6 bpp, una capa de texto de 8×8 a 4 bpp,
512 sprites de 16×16 a 5 bpp (hasta 8 tiles de alto), brillo global y la interrupción de raster por línea que
usa la pantalla de título para su efecto de ondulación. 320×240, 15,625 kHz / 57,44 Hz.

**Estado: funciona en MiSTer** — arranca pasando su RAM/ROM check y reproduce el modo demo en la placa. En
simulación, el vídeo coincide píxel a píxel con MAME en 120 de 120 escenas de referencia (demo y partida); el
sonido (Z80 + YM2151 + OKI) sigue los comandos de sonido de MAME, con el balance FM/ADPCM medido contra MAME.
Aún sin implementar: **volteo de pantalla** y la **versión US** (`shadfrceu`, 6 botones).

Hay un `.rbf` precompilado en [`releases/`](releases/) — **distribuible**: todas las ROMs del juego se cargan
en **tiempo de ejecución** desde el `.mra`; el bitstream no lleva datos del juego. O compílalo desde las
fuentes (`cores/shadfrce/`). Ver [`BUILD.md`](BUILD.md).

## Compilar

Este repo contiene **solo el código del core** (`cores/<core>/`). El framework y los cores de terceros
(jtframe, jt51, jt6295) **no se incluyen** — los aporta jtframe. Versión rápida:

1. Clona [jtcores](https://github.com/jotego/jtcores) (trae jtframe + módulos).
2. Copia `cores/<core>/` de este repo en tu copia de jtcores.
3. Compila: `jtcore <core> -mister -c` (p. ej. `jtcore shadfrce -mister -c`).

📋 **Paso a paso en [`BUILD.md`](BUILD.md).**

## ROMs

**No se incluyen** (material con copyright). Usa tu propio romset de MAME (**merged**, MAME 0.288,
`shadfrce.zip`). El `.mra` describe cómo montarlo; todas las ROMs se cargan en tiempo de ejecución.

## Créditos

- **JTFRAME**, **jt51**, **jt6295** — los frameworks y módulos GPLv3 sobre los que se construye este core
- **MAME** — referencia del hardware (driver `technos/shadfrce.cpp` de David Haywood, con trabajo posterior de
  Pierpaolo Prazzoli)

## Agradecimientos

- A **Sorgelig** y a todo el proyecto y la comunidad **MiSTer FPGA**.
- A la **comunidad de MAME**, por el trabajo de preservación e ingeniería inversa sin el que este core no sería
  posible.
- Y a **Anthropic**, por **Claude**.

## Licencia

**GPLv3** (ver [`LICENSE`](LICENSE)) — la exigen las dependencias JTFRAME / jt51 / jt6295; sus avisos de
copyright se conservan en las fuentes.

<!-- omf_release:dependencias:ffshadfrce -->
## Dependencias externas de `ffshadfrce`

Este repositorio contiene **solo el código de los cores**. Para compilar `ffshadfrce`
hacen falta estas piezas, que se distribuyen desde su propio origen:

| Qué | De dónde | Dónde va |
|---|---|---|
| jtframe — framework de compilacion y modulos comunes (SDRAM, descarga, CPUs 68000/Z80, RAM) | [https://github.com/jotego/jtframe](https://github.com/jotego/jtframe) | `modules/jtframe` |
| jt51 — YM2151 | [https://github.com/jotego/jt51](https://github.com/jotego/jt51) | `modules/jt51` |
| jt6295 — OKI M6295 | [https://github.com/jotego/jt6295](https://github.com/jotego/jt6295) | `modules/jt6295` |
<!-- /omf_release:dependencias:ffshadfrce -->
