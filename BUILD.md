# Building the cores (reproducible)

🇬🇧 English (below) · [🇪🇸 Español](#compilar-los-cores-reproducible)

Steps to rebuild any `.rbf` in this repo from scratch. **No patch is required**: every game ROM is loaded at
**runtime** from the `.mra`, so each bitstream is distributable as-is. Tested for MiSTer.

## Requirements (all cores)
- A [**jtcores**](https://github.com/jotego/jtcores) checkout (brings jtframe + jt51 + jt6295 as modules) and
  its toolchain (`setprj.sh`, `jtcore`).
- **Quartus** (the version your MiSTer board needs).
- Your own ROMs for the game (not included) — see [`README.md`](README.md).

## Shadow Force

1. **Place the core** inside jtcores:
   ```
   cp -r cores/shadfrce  <jtcores>/cores/shadfrce
   ```
2. **Build** (generate + compile):
   ```
   cd <jtcores> && source setprj.sh
   jtcore shadfrce -mister -c
   ```
   This generates `<jtcores>/cores/shadfrce/mister/` (Quartus project + the memgen GAMETOP
   `jtshadfrce_game_sdram.v`) and compiles it. The result is the `.rbf` under `mister/output_files/`.

**ROM layout.** The tile ROMs are re-ordered **during the download** (`jtshadfrce_dwnld.v`, `post_addr`), and the
sprite ROMs are packed four planes per 32-bit word by the `.mra` itself (`<interleave output="32">`). Use the
`.mra` from `cores/shadfrce/mra/`: it is the one the bitstream expects.

---

# Compilar los cores (reproducible)

🇪🇸 Español · [🇬🇧 English ↑](#building-the-cores-reproducible)

Pasos para recompilar desde cero cualquier `.rbf` de este repo. **No hace falta ningún parche**: todas las ROMs
del juego se cargan en **tiempo de ejecución** desde el `.mra`, así que cada bitstream es distribuible tal cual.
Probado para MiSTer.

## Requisitos (todos los cores)
- Una copia de [**jtcores**](https://github.com/jotego/jtcores) (trae jtframe + jt51 + jt6295 como módulos) y
  sus herramientas (`setprj.sh`, `jtcore`).
- **Quartus** (la versión que pida tu placa MiSTer).
- Tus propias ROMs del juego (no incluidas) — ver [`README.md`](README.md).

## Shadow Force

1. **Coloca el core** dentro de jtcores:
   ```
   cp -r cores/shadfrce  <jtcores>/cores/shadfrce
   ```
2. **Compila** (genera + compila):
   ```
   cd <jtcores> && source setprj.sh
   jtcore shadfrce -mister -c
   ```
   Esto genera `<jtcores>/cores/shadfrce/mister/` (proyecto de Quartus + el GAMETOP de memgen
   `jtshadfrce_game_sdram.v`) y lo compila. El `.rbf` queda en `mister/output_files/`.

**Organización de las ROMs.** Las ROMs de tiles se reordenan **durante la descarga** (`jtshadfrce_dwnld.v`,
`post_addr`) y las de sprites las empaqueta la propia `.mra` en palabras de 32 bits con cuatro planos
(`<interleave output="32">`). Usa la `.mra` de `cores/shadfrce/mra/`: es la que espera el bitstream.
