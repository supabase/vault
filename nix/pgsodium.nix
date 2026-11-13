{ lib, stdenv, fetchFromGitHub, libsodium, postgresql }:

stdenv.mkDerivation rec {
  pname = "pgsodium";
  version = "3.1.11";

  buildInputs = [ libsodium postgresql ];

  src = fetchFromGitHub {
    owner = "michelp";
    repo = pname;
    # rev = "refs/tags/v${version}";
    rev = "a8b8a2739bab1f7a07445b1c911e2bd1abf67784";
    hash = "sha256-2Hv4rc7Q0jdd112KRm7SsdfAzFDSC8LYIDAObuA7yUg=";
  };

  installPhase = ''

    install -D -t $out *${postgresql.dlSuffix}
    install -D -t $out sql/*.sql
    install -D -t $out extension/*.sql
    install -D -t $out *.control
  '';

  meta = with lib; {
    description = "Modern cryptography for PostgreSQL";
    homepage = "https://github.com/michelp/${pname}";
    maintainers = with maintainers; [ samrose ];
    platforms = postgresql.meta.platforms;
    license = licenses.postgresql;
  };
}
