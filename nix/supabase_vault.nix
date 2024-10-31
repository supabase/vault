{ stdenv, libsodium, postgresql }:

stdenv.mkDerivation rec {
  name = "supabase_vault";

  buildInputs = [ libsodium postgresql ];

  src = ../.;

  installPhase = ''
    mkdir -p $out/{lib,share/postgresql/extension}

    install -D *${postgresql.dlSuffix} $out/lib
    install -D -t $out/share/postgresql/extension sql/*.sql
    install -D -t $out/share/postgresql/extension *.control
  '';
}
