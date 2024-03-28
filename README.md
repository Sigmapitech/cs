# CS: Coding-Style script on nix

## Example usage

```sh
nix run github:Sigmapitech/cs . --include-tests --ignore-rules=C-G1,C-O3
```

## Options

- `path`: Specifies the location where the coding style will be checked, defaulting to `.`
- `--ignore-rules`: Specifies a list of rules to be ignored, separated by commas
- `--ignore-folders`: Specifies a list of folders to be ignored within the search path, separated by commas
- `--include-tests`: Specifies whether to include the test folder for checking, disabled by default
- `-h`, `--help`: Display an help message
