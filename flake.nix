{
  description = "OpenModelica 1.27.2 built from source for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    om = import ./default.nix {inherit pkgs;};
  in {
    packages.${system} = {
      inherit (om) openmodelica openmodelica-core openmodelica-nofortran;
      default = om.openmodelica;
    };

    apps.${system}.default = {
      type = "app";
      program = "${om.openmodelica}/bin/OMEdit";
    };

    # For hacking on the build by hand: `nix develop`, then cmake -S . -B build_cmake ...
    devShells.${system}.default = pkgs.mkShell {
      inputsFrom = [om.openmodelica-core];
      packages = [pkgs.ccache pkgs.gdb];
    };
  };
}
