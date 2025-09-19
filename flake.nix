{
  description = "Print EPITECH's coding style compliance report";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    vera-clang.url = "github:Sigmapitech/vera-clang";
    ruleset = {
      url = "git+ssh://git@github.com/Epitech/banana-coding-style-checker.git";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ruleset, vera-clang }: let
    supportedSystems = [
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-linux"
      "x86_64-darwin"
    ];

    forAllSystems = f: nixpkgs.lib.genAttrs
      supportedSystems (system: f nixpkgs.legacyPackages.${system});
  in {
    packages = forAllSystems (pkgs: {
      default = self.packages.${pkgs.system}.report;
    
      report = pkgs.callPackage ./report.nix {
        banana-vera = vera-clang.packages.${pkgs.system}.banana-vera;

        inherit ruleset;
      };
    });
  };
}
