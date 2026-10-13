{ lib, stdenv, fetchFromGitHub, libsodium, postgresql }:

stdenv.mkDerivation rec {
  pname = "pgsodium";
  version = "3.1.8";

  buildInputs = [ libsodium postgresql ];
  nativebuildInputs = [ libsodium postgresql ];

  src = fetchFromGitHub {
    owner = "michelp";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-j5F1PPdwfQRbV8XJ8Mloi8FvZF0MTl4eyIJcBYQy1E4=";
  };

  installPhase = ''
    mkdir -p $out/{lib,share/postgresql/extension}

    install -D -t $out/ *${postgresql.dlSuffix}
    install -D -t $out/ sql/*.sql
    install -D -t $out/ *.control
  '';

  meta = with lib; {
    description = "Modern cryptography for PostgreSQL";
    homepage = "https://github.com/michelp/${pname}";
    maintainers = with maintainers; [ samrose ];
    platforms = postgresql.meta.platforms;
    license = licenses.postgresql;
  };
}
