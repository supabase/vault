with import (builtins.fetchTarball {
    name = "24.05"; # May 31 2024
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/24.05.tar.gz";
    sha256 = "sha256:1lr1h35prqkd1mkmzriwlpvxcb34kmhc9dnr48gkm8hh089hifmx";
}) {};
mkShell {
  buildInputs =
    let
      ourPg = callPackage ./nix/postgresql {
        inherit lib;
        inherit stdenv;
        inherit fetchurl;
        inherit makeWrapper;
        inherit callPackage;
      };
      supportedPgVersions = [
        postgresql_13
        postgresql_14
        postgresql_15
        postgresql_16
        ourPg.postgresql_17
      ];
      pgWithExt = { pg }: pg.withPackages (p: [
        (callPackage ./nix/pgsodium.nix { postgresql = pg; })
        (callPackage ./nix/supabase_vault.nix { postgresql = pg; })
      ]);
      extAll = map (x: callPackage ./nix/pgScript.nix { postgresql = pgWithExt { pg = x; }; }) supportedPgVersions;
    in
    [
      extAll
    ];
  shellHook = ''
    export HISTFILE=.history
  '';
}
