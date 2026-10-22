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
          pgtap14
        ];
        "15" = [
          pgtap15
        ];
        "16" = [
          pgtap16
        ];
        "17" = [
          pgtap17
        ];
        "18" = [
          pgtap18
        ];
        "19" = [
          pgtap19
        ];
      };
    })
    pkgs.libsodium
    pkgs.python313Packages.pglast
    style
    styleCheck
  ];
}
