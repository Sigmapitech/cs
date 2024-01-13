pkgs: ruleset: banana-vera: let
  report = (pkgs.writers.writePython3Bin "report" {}
    (builtins.readFile ./report.py));
in (pkgs.writeShellScriptBin "cs" ''
${report}/bin/report ${banana-vera}/bin/vera++ ${ruleset}/vera $*
'')
