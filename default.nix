# default.nix
{pkgs ? import <nixpkgs> {}}: rec {
  openmodelica-core = pkgs.callPackage ./openmodelica-core.nix {};
  openmodelica = pkgs.callPackage ./openmodelica.nix {inherit openmodelica-core;};

  # Variant without Fortran (if gfortran causes link errors like it did for 1.25)
  openmodelica-core-nofortran = openmodelica-core.override {enableFortran = false;};
  openmodelica-nofortran = pkgs.callPackage ./openmodelica.nix {
    openmodelica-core = openmodelica-core-nofortran;
  };
}
