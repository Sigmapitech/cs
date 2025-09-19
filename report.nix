{
  lib,
  ruleset,
  banana-vera,
  writeShellScriptBin,
  writers,
  python3Packages,
}:
let
  report = (writers.writePython3Bin "report" {
    libraries = [ python3Packages.tomli ];
  } (builtins.readFile ./report.py));
in writeShellScriptBin "cs" ''
  ${lib.getExe report} ${banana-vera}/bin/vera++ ${ruleset}/vera $*
''
