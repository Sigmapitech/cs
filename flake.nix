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
          (system: function {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          });

      libclangpy = arch: p:
        let
          distrib = {
            "x86_64-linux" = {
              platform = "manylinux2010_x86_64";
              hash = "sha256-nc3HMJOXiLi2n/1tXXX+U2bj7gB/Hjapl5nsCwwAFJI=";
            };

            "x86_64-darwin" = {
              platform = "macosx_10_9_x86_64";
              hash = "sha256-2p5H68PwptkPsWnvJfn7zSm0pO+XqLDj46F4AK8UI/Q=";
            };

            "aarch64-darwin" = {
              platform = "macosx_11_0_arm64";
              hash = "sha256-4aWtHoleVEPiBVaMhcBLRgjk6XPa5C9N/Zy0bIHRSGs=";
            };

            "aarch64-linux" = {
              platform = "manylinux2014_aarch64";
              hash = "sha256-gTBIISBQBHagJxcfjzyN/CU2tZFxbupx/F2iLK4TExs=";
            };
          };
        in
        with arch; p.buildPythonPackage rec {
          pname = "libclang";
          version = "16.0.6";
          format = "wheel";

          src = pkgs.python310Packages.fetchPypi {
            inherit pname version format;
            platform = distrib.${system}.platform;
            hash = distrib.${system}.hash;
          };
        };

      banana-vera = arch:
        let
          pyenv = arch.pkgs.python310.withPackages (p: [ libclangpy p arch ]);
        in
        with arch;
        pkgs.stdenv.mkDerivation rec {
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

      report-script = arch:
        (arch.pkgs.writeShellScriptBin "cs" ''
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
            | ${banana-vera arch}/bin/vera++   \
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

    in
    rec {
      packages = forAllSystems (arch: rec {
        report = report-script arch;
        default = report;
      });

      apps = forAllSystems ({ system, ... }: rec {
        report.type = "app";
        report.program = "${packages.${system}.report}/bin/cs";
        default = report;
      });

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixpkgs-fmt);
    };
}
