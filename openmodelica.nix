# openmodelica.nix
# Wraps the binaries so that omc can compile simulations / export FMUs at runtime:
# C compiler, make, cmake and zip on PATH; omc libs + BLAS/LAPACK/gfortran on the library path.
{
  lib,
  stdenv,
  symlinkJoin,
  makeWrapper,
  openmodelica-core,
  clang,
  gnumake,
  cmake,
  zip,
  unzip,
  which,
  coreutils,
  gdb,
  xterm,
  blas,
  lapack,
  gfortran,
  expat,
  zlib,
  curl,
  boost,
  libuuid,
}: let
  runtimeLibs = [
    blas
    lapack
    gfortran.cc.lib
    expat
    zlib
    curl
    boost
    libuuid
  ];
  runtimeBins = [
    stdenv.cc # gcc/cc with the correct glibc headers
    clang
    gnumake
    cmake # FMU export
    zip
    unzip # FMU export / import
    which
    coreutils
    gdb
  ];
in
  symlinkJoin {
    name = "openmodelica-${openmodelica-core.version}";
    paths = [openmodelica-core];
    nativeBuildInputs = [makeWrapper];

    postBuild = ''
      # Find the omc lib dir (normally lib/omc; possibly lib/<arch>/omc)
      omcLib=$(dirname "$(find -L ${openmodelica-core}/lib -name 'libOpenModelicaRuntimeC.so' | head -n1)")
      echo "omc lib dir: $omcLib"
      libPath="$omcLib:${lib.makeLibraryPath runtimeLibs}"

      rm -rf $out/bin
      mkdir -p $out/bin

      # bin/* does not match the hidden .xyz-wrapped files from wrapQtAppsHook
      for exe in ${openmodelica-core}/bin/*; do
        [ -x "$exe" ] || continue
        name=$(basename "$exe")
        makeWrapper "$exe" "$out/bin/$name" \
          --prefix PATH : "${lib.makeBinPath runtimeBins}" \
          --prefix LD_LIBRARY_PATH : "$libPath" \
          --prefix LIBRARY_PATH : "$libPath"
      done

      # OMEdit: Tools -> Open Terminal
      ln -s ${xterm}/bin/xterm $out/bin/x-terminal-emulator
    '';

    inherit (openmodelica-core) meta;
  }
