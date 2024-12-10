pkgs: ruleset: banana-vera: let
  report = (pkgs.writers.writePython3Bin "report" {}
    (builtins.readFile ./report.py));

  patched-ruleset = pkgs.stdenv.mkDerivation {
    name = "patched-ruleset";

    src = ruleset;
    dontBuild = true;
    patches = [ ./declare_transcient_macro.patch ];

    installPhase = "cp -r . $out";
  };

in (pkgs.writeShellScriptBin "cs" ''
${report}/bin/report ${banana-vera}/bin/vera++ ${patched-ruleset}/vera $*
'')
