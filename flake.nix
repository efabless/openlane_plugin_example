{
  nixConfig = {
    extra-substituters = [
      "https://openlane.cachix.org"
    ];
    extra-trusted-public-keys = [
      "openlane.cachix.org-1:qqdwh+QMNGmZAuyeQJTH9ErW57OWSvdtuwfBKdS254E="
    ];
  };

  inputs = {
    openlane2.url = github:efabless/openlane2;
  };

  outputs = {
    self,
    openlane2,
    ...
  }: let
    nix-eda = openlane2.inputs.nix-eda;
    devshell = openlane2.inputs.devshell;
    nixpkgs = nix-eda.inputs.nixpkgs;
    lib = nixpkgs.lib;
  in {
    overlays = {
      default = lib.composeManyExtensions [
        (nix-eda.composePythonOverlay (pkgs': pkgs: pypkgs': pypkgs: let
          callPythonPackage = lib.callPackageWith (pkgs' // pkgs'.python3.pkgs);
        in {
          openlane-plugin-example = callPythonPackage ./default.nix {};
        }))
      ];
    };
    # Outputs
    legacyPackages = nix-eda.forAllSystems (
      system:
        import nixpkgs {
          inherit system;
          overlays = [nix-eda.overlays.default devshell.overlays.default openlane2.overlays.default self.overlays.default];
        }
    );
    packages = nix-eda.forAllSystems (system: {
      inherit (self.legacyPackages.${system}.python3.pkgs) openlane-plugin-example;
      default = self.packages.${system}.openlane-plugin-example;
    });
    
    devShells = nix-eda.forAllSystems (system: let
      pkgs = (self.legacyPackages.${system});
    in {
      default = lib.callPackageWith pkgs (openlane2.createOpenLaneShell {
        openlane-plugins = with pkgs.python3.pkgs; [
          openlane-plugin-example
        ];
      }) {};
    });
  };
}
