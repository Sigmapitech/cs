arch: with arch;
let
  py = pkgs.python310.withPackages (p: [
    (import ./libclangpy.nix arch p)
  ]);
in
pkgs.banana-vera.overrideAttrs (prev: {
  nativeBuildInputs = prev.nativeBuildInputs ++ [ pkgs.makeWrapper ];

  postFixup = ''
    wrapProgram $out/bin/vera++ --set PYTHONPATH "${py}/${py.sitePackages}"
  '';
})