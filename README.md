# CS: Coding-Style script on nix

## Example usage

```sh
nix run github:Sigmapitech/cs -- . --include-tests --ignore-rules=C-G1,C-O3
```

## Options

- `path`: Specifies the location where the coding style will be checked, defaulting to `.`
- `--ignore-rules`: Specifies a list of rules to be ignored, separated by commas
- `--ignore-folders`: Specifies a list of folders to be ignored within the search path, separated by commas
- `--include-tests`: Specifies whether to include the test folder for checking, disabled by default
- `-h`, `--help`: Display an help message

## Integrate within your `flake.nix`

To have access to a custom `cs` script with you own flags in your flake project,
you can add it you from flake inputs and export a wrapped version.

Here is a minimal example.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";

    cs-flake.url = "github:Sigmapitech/cs";
  };

  outputs = { self, nixpkgs, cs-flake, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShell = let
          cs = pkgs.writeShellScriptBin "cs" ''
            ${cs-flake.packages.${system}.report}/bin/cs -- \
              --ignore-folders=docs,assets
        '';
        in pkgs.mkShell {
          packages = [ cs ];
        };
      });
```
