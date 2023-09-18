{
  description = "Print EPITECH's coding style compliance report";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ruleset = {
      url = "git+ssh://git@github.com/Epitech/banana-coding-style-checker.git";
      flake = false;
    };
  };

  outputs = { nixpkgs, ruleset, ... }:
    let
      forAllSystems = function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ]
          (system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
            in
            function { inherit system pkgs; });
    in
    rec {
      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixpkgs-fmt);

      packages = forAllSystems (arch: rec {
        report = import ./report.nix ruleset arch;
        default = report;
      });

      apps = forAllSystems ({ system, ... }: rec {
        report = {
          type = "app";
          program = "${packages.${system}.report}/bin/cs";
        };

        default = report;
      });
    };
}
