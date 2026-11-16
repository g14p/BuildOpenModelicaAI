# openmodelica-core.nix
# Builds OpenModelica v1.27.2 from source with the upstream CMake build system.
{
  lib,
  stdenv,
  fetchFromGitHub,
  autoPatchelfHook,
  # build tools
  cmake,
  pkg-config,
  autoconf,
  automake,
  libtool,
  gnumake,
  git,
  python3,
  flex,
  bison,
  jdk,
  gfortran,
  # libraries
  boost,
  curl,
  expat,
  hdf5,
  libuuid,
  libxml2,
  ncurses,
  readline,
  blas,
  lapack,
  zlib,
  icu,
  gettext,
  libffi,
  # GUI
  qt6,
  openscenegraph,
  libGL,
  libGLU,
  # feature switches (override with .override { enableFortran = false; } etc.)
  enableGui ? true,
  enableFortran ? true, # needed for MOO + Ipopt (dynamic optimization)
  enableCppRuntime ? true,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "openmodelica-core";
  version = "1.27.2";

  src = fetchFromGitHub {
    owner = "OpenModelica";
    repo = "OpenModelica";
    rev = "v${finalAttrs.version}";
    # Includes the submodules OMCompiler/3rdParty, OMSimulator, OMSens_Qt,
    # OMOptim and OMCompiler/Compiler/boot/bomc (OMBootstrapping).
    fetchSubmodules = true;
    # On the first build Nix prints the real hash -> paste it here.
    hash = "sha256-8P4d2W3FctQKmbKEmBIcLqISFYi54yIgXzbat5HKnYE=";
  };

  postPatch = ''
    # Without .git the version would show up as "unknown".
    # cmake/omc_git_revision.cmake reads OMVERSION.txt first.
    echo "v${finalAttrs.version}" > OMVERSION.txt

    # Fix /bin/bash, /usr/bin/env ... in helper scripts
    patchShebangs --build .
  '';

  nativeBuildInputs =
    [
      cmake
      pkg-config
      autoconf
      automake
      libtool
      gnumake
      git
      python3
      flex
      bison
      jdk
      autoPatchelfHook
    ]
    ++ lib.optional enableFortran gfortran
    ++ lib.optional enableGui qt6.wrapQtAppsHook;

  buildInputs =
    [
      boost
      curl
      expat
      hdf5
      libuuid
      libxml2
      ncurses
      readline
      blas
      lapack
      zlib
      icu
      gettext
      libffi
    ]
    ++ lib.optional enableFortran gfortran.cc.lib
    ++ lib.optionals enableGui [
      qt6.qtbase
      qt6.qtsvg
      qt6.qttools # LinguistTools (translations)
      qt6.qt5compat # Core5Compat, required by OMEdit with Qt6
      qt6.qtwebengine # replaces the insecure qtwebkit
      qt6.qthttpserver # optional for OMEdit (Qt >= 6.4)
      qt6.qtwayland # claude said this is needed when on wayland
      openscenegraph
      libGL
      libGLU
    ];
  cmakeFlags =
    [
      "-Wno-dev"
      "-DCMAKE_BUILD_TYPE=Release"

      # nixpkgs passes absolute install dirs; OpenModelica appends "omc" to them and
      # uses them for $ORIGIN-relative RPATHs -> force relative dirs.
      "-DCMAKE_INSTALL_BINDIR=bin"
      "-DCMAKE_INSTALL_LIBDIR=lib"
      "-DCMAKE_INSTALL_INCLUDEDIR=include"

      # The bootstrap compiler (bomc) and omc are *run from the build tree*
      # during the build. The nixpkgs cmake hook sets SKIP_BUILD_RPATH=ON,
      # which would stop them from finding their shared libs.
      "-DCMAKE_SKIP_BUILD_RPATH=OFF"

      # ccache is mandatory by default (FATAL_ERROR) -> no use in the sandbox
      "-DOM_USE_CCACHE=OFF"

      "-DOM_QT_MAJOR_VERSION=6"
      (lib.cmakeBool "OM_ENABLE_GUI_CLIENTS" enableGui)
      (lib.cmakeBool "OM_OMC_ENABLE_FORTRAN" enableFortran)
      (lib.cmakeBool "OM_OMC_ENABLE_MOO" enableFortran)
      (lib.cmakeBool "OM_OMC_ENABLE_OPTIMIZATION" enableFortran)
      (lib.cmakeBool "OM_OMC_ENABLE_CPP_RUNTIME" enableCppRuntime)
    ]
    ++ lib.optional enableFortran "-DCMAKE_Fortran_COMPILER=${gfortran}/bin/gfortran";

  enableParallelBuilding = true;
  doCheck = false; # upstream: "no ctest support yet"

  preFixup = ''
    # Workaround from the 1.25 build (broken paths in cminpack.pc), only if needed
    for pc in $(find $out/lib -name cminpack.pc 2>/dev/null); do
      sed -i -e "s|$out/||g" -e 's|//omc|/omc|g' -e 's|omc//|omc/|g' "$pc"
    done
  '';

  meta = {
    description = "Open-source Modelica-based modeling and simulation environment (compiler + GUI clients)";
    homepage = "https://openmodelica.org/";
    license = with lib.licenses; [gpl3Only]; # OSMC-PL / GPL dual licensed
    platforms = lib.platforms.linux;
    mainProgram = "OMEdit";
  };
})
