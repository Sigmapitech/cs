{
  description = "Print EPITECH's coding style compliance report";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ruleset = {
      url = "git+ssh://git@github.com/Epitech/banana-coding-style-checker.git";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, ruleset, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          libclangpy = pkgs.python310Packages.buildPythonPackage rec {
            pname = "libclang";
            version = "16.0.6";
            format = "wheel";

            src = pkgs.python310Packages.fetchPypi {
              inherit pname version format;
              platform = "manylinux2010_x86_64";
              hash = "sha256-nc3HMJOXiLi2n/1tXXX+U2bj7gB/Hjapl5nsCwwAFJI=";
            };
          };

          pyenv = pkgs.python310.withPackages (p: [ libclangpy ]);
          banana-vera = pkgs.stdenv.mkDerivation rec {
            pname = "banana-vera";
            version = "1.3.0-fedora38";

            src = pkgs.fetchFromGitHub {
              owner = "Epitech";
              repo = "banana-vera";
              rev = "refs/tags/v${version}";
              sha256 = "sha256-sSN3trSySJe3KVyrb/hc5HUGRS4M3c4UX9SLlzBM43c";
            };

            nativeBuildInputs = [ pkgs.cmake pkgs.makeWrapper ];
            buildInputs = with pkgs; [
              python310
              python310.pkgs.boost
              tcl
            ];

            postFixup = ''
              wrapProgram $out/bin/vera++ \
                --set PYTHONPATH "${pyenv}/${pyenv.sitePackages}"
            '';

            cmakeFlags = [
              "-DVERA_LUA=OFF"
              "-DVERA_USE_SYSTEM_BOOST=ON"
              "-DPANDOC=OFF"
            ];
          };

        in
        rec {
          packages = flake-utils.lib.flattenTree rec {
            report = (pkgs.writeShellScriptBin "cs" ''
              start_time=$(date +%s)

              if [ -z "$1" ]; then
                  project_dir=$(pwd)
              else
                  project_dir="$1"
              fi

              echo "Running norm in $project_dir"
              count=$(find "$project_dir"     \
                -type f                       \
                -not -path "*/.git/*"         \
                -not -path "*/.idea/*"        \
                -not -path "*/.vscode/*"      \
                -not -path "bonus/*"          \
                -not -path "tests/*"          \
                -not -path "/*build/*"        \
                | ${banana-vera}/bin/vera++ \
                --profile epitech             \
                --root ${ruleset}/vera        \
                --error                       \
                2>&1                          \
                | sed "s|$project_dir/||"     \
                | tee /dev/stderr | wc -l
              )

              echo "Found $count issues"
              end_time=$(date +%s)
              echo "Ran in $((end_time - start_time))s"
              if [ $count -gt 0 ]; then
                  exit 1
              fi
              exit 0
            '');
            default = report;
          };

          apps.report.type = "app";
          apps.report.program = "${packages.report}/bin/cs";
          apps.default = apps.report;
          formatter = pkgs.nixpkgs-fmt;
        });
}
