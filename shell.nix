# shell.nix  ->  just run `nix-shell`
{pkgs ? import <nixpkgs> {}}: let
  om = import ./default.nix {inherit pkgs;};
in
  pkgs.mkShell {
    packages = [om.openmodelica];
    shellHook = ''
      echo "OpenModelica ${om.openmodelica-core.version}: run OMEdit, omc, OMShell-terminal, OMNotebook ..."
    '';
  }
