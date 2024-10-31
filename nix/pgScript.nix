{ postgresql, writeShellScriptBin } :

let
  ver = builtins.head (builtins.splitVersion postgresql.version);
  src = builtins.readFile ./withTmpDb.sh.in;
in
(writeShellScriptBin "vault-with-pg-${ver}" src).overrideAttrs(old: {
  buildCommand = ''
    ${old.buildCommand}
    substituteInPlace $out/bin/${old.name} --subst-var-by 'POSTGRESQL_PATH' '${postgresql}'
  '';
})
