let
  flakeLock = builtins.fromJSON (builtins.readFile ./flake.lock);
  nixpkgsLock = flakeLock.nodes.nixpkgs.locked;
  xpgLock = flakeLock.nodes.xpg.locked;
in
{
  pkgs ? import (builtins.fetchTarball {
    name = nixpkgsLock.rev;
    url = "https://github.com/${nixpkgsLock.owner}/${nixpkgsLock.repo}/archive/${nixpkgsLock.rev}.tar.gz";
    sha256 = nixpkgsLock.narHash;
  }) { },
  xpgPkgs ? import (
    pkgs.fetchFromGitHub {
      inherit (xpgLock) owner repo rev;
      sha256 = xpgLock.narHash;
    }
  ),
  pgVersion ? null,
  cassert ? true,
}:
let
  pgtap14 = pkgs.callPackage ./nix/pgtap.nix {
    postgresql = xpgPkgs.postgresql_14;
  };
  pgtap15 = pkgs.callPackage ./nix/pgtap.nix {
    postgresql = xpgPkgs.postgresql_15;
  };
  pgtap16 = pkgs.callPackage ./nix/pgtap.nix {
    postgresql = xpgPkgs.postgresql_16;
  };
  pgtap17 = pkgs.callPackage ./nix/pgtap.nix {
    postgresql = xpgPkgs.postgresql_17;
  };
  pgtap18 = pkgs.callPackage ./nix/pgtap.nix {
    postgresql = xpgPkgs.postgresql_18;
  };
  pgtap19 = pkgs.callPackage ./nix/pgtap.nix {
    postgresql = xpgPkgs.postgresql_19;
  };

  pgsodium14 = pkgs.callPackage ./nix/pgsodium.nix {
    postgresql = xpgPkgs.postgresql_14;
  };
  pgsodium15 = pkgs.callPackage ./nix/pgsodium.nix {
    postgresql = xpgPkgs.postgresql_15;
  };
  pgsodium16 = pkgs.callPackage ./nix/pgsodium.nix {
    postgresql = xpgPkgs.postgresql_16;
  };
  pgsodium17 = pkgs.callPackage ./nix/pgsodium.nix {
    postgresql = xpgPkgs.postgresql_17;
  };
  pgsodium18 = pkgs.callPackage ./nix/pgsodium.nix {
    postgresql = xpgPkgs.postgresql_18;
  };
  pgsodium19 = pkgs.callPackage ./nix/pgsodium.nix {
    postgresql = xpgPkgs.postgresql_19;
  };
  style = pkgs.writeShellScriptBin "vault-style" ''
    ${pkgs.clang-tools}/bin/clang-format -i src/*
    ${pkgs.findutils}/bin/find . -name '*.nix' -exec ${pkgs.nixfmt}/bin/nixfmt {} \+
  '';
  styleCheck = pkgs.writeShellScriptBin "vault-style-check" ''
    ${pkgs.clang-tools}/bin/clang-format -i src/*
    ${pkgs.git}/bin/git diff-index --exit-code HEAD -- '*.c'
    ${pkgs.findutils}/bin/find . -name '*.nix' -exec ${pkgs.nixfmt}/bin/nixfmt --check {} \+
  '';
in
pkgs.mkShell {
  buildInputs = [
    (xpgPkgs.xpg.withExtensions {
      extensions = {
        "14" = [
          pgsodium14
          pgtap14
        ];
        "15" = [
          pgsodium15
          pgtap15
        ];
        "16" = [
          pgsodium16
          pgtap16
        ];
        "17" = [
          pgsodium17
          pgtap17
        ];
        "18" = [
          pgsodium18
          pgtap18
        ];
        "19" = [
          pgsodium19
          pgtap19
        ];
      };
    })
    pkgs.libsodium
    style
    styleCheck
  ];
  shellHook = ''
    export HISTFILE=.history
  '';
}
