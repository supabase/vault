{
  description = "Development shell for pg_net";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    xpg = {
      url = "github:supabase/xpg/v2.7.1";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      xpg,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          xpgPkgs = xpg.packages.${system};
        in
        {
          default = import ./shell.nix {
            inherit pkgs xpgPkgs;
          };
        }
      );
    };
}
