{
  description = "Print EPITECH's coding style compliance report";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    vera-clang.url = "github:Sigmapitech/vera-clang/test";
    ruleset = {
      url = "git+ssh://git@github.com/Epitech/banana-coding-style-checker.git";
      flake = false;
    };
  };

  outputs = { nixpkgs, ruleset, flake-utils, vera-clang, ... }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      vera = vera-clang.packages.${system}.vera;
    in
    rec {
      devShell = pkgs.mkShell {
        buildInputs = [ vera ];
      };

      formatter = pkgs.nixpkgs-fmt;

      packages = rec {
        report = (import ./report.nix pkgs ruleset vera);
        default = report;
        inherit vera;
      };

      apps = rec {
        report = {
          type = "app";
          program = "${packages.report}/bin/cs";
        };

        default = report;
      };
    });
}
