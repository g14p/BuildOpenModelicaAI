# OpenModelica 1.27.2 from source on NixOS

nixpkgs removed `openmodelica` (unmaintained, depended on insecure qtwebkit).
OpenModelica 1.27.2 uses Qt6 + QtWebEngine, so it can be built again. Based on
https://github.com/MBanucu/NixOS2505BuildOpenModelicaFromSource (v1.25).

## 1. Set the source hash (once)

Either build once and copy the `got: sha256-...` hash into
`openmodelica-core.nix`, or compute it in advance:

    nix-shell -p nix-prefetch-git --run \
      "nix-prefetch-git --url https://github.com/OpenModelica/OpenModelica --rev v1.27.2 --fetch-submodules"

## 2. Build / run

    nix-build -A openmodelica          # -> ./result/bin/OMEdit
    nix-shell                          # shell with OMEdit, omc, ...
    nix-shell -p '(import ./default.nix {}).openmodelica'   # like Banucu
    # or with flakes:
    nix run .                          # starts OMEdit
    nix build .#openmodelica

The build takes about 1 h or more and needs a lot of RAM. If memory runs out:
`nix-build --cores 4 ...`

## 3. Modelica Standard Library

The CMake build does not install libraries. In OMEdit use File -> Manage
Libraries -> Install Library -> "Modelica" (stored in
~/.openmodelica/libraries).

## Troubleshooting

- **gfortran / Ipopt / MOO link errors** ->
  `nix-build -A openmodelica-nofortran` (no dynamic optimization; normal
  simulation works).
- **"cannot open shared object" during the build (bomc/omc)** -> check
  `-DCMAKE_SKIP_BUILD_RPATH=OFF` in cmakeFlags.
- **Header errors with `#include_next <stdlib.h>`** -> Banucu's old workaround,
  add to `preConfigure`:
  `export NIX_CFLAGS_COMPILE=$(echo "$NIX_CFLAGS_COMPILE" | sed 's/-isystem /-I/g')`
- **A download fails during the build (sandbox)** -> fetch that file with
  `fetchurl` and copy it into place in `postPatch`.
- **Simulation: `-llapack`/`-lblas`/`-lgfortran` not found** -> add the library
  to `runtimeLibs` in `openmodelica.nix`. Only the wrapper is rebuilt, which
  takes seconds.
- Iterating by hand: `nix develop` (or `nix-shell -A openmodelica-core`), then
  `cmake -S . -B build_cmake -DOM_USE_CCACHE=ON ...` inside the source tree.
