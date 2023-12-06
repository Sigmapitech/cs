{
  description = "Print EPITECH's coding style compliance report";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    ruleset = {
      url = "git+ssh://git@github.com/Epitech/banana-coding-style-checker.git";
      flake = false;
    };
  };

  outputs = { nixpkgs, ruleset, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    rec {
      formatter = pkgs.nixpkgs-fmt;

      packages = rec {
        report = import ./report.nix ruleset { inherit system pkgs; };
        default = report;
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
