{
  lib,
  stdenv,
  fetchFromGitHub,
  postgresql,
  perl,
  perlPackages,
  which,
}:

stdenv.mkDerivation rec {
  pname = "pgtap";
  version = "1.3.4";

  src = fetchFromGitHub {
    owner = "theory";
    repo = "pgtap";
    rev = "v${version}";
    hash = "sha256-SKac6JJmH/z7G1GmQYATMNfywsDIHjNdskzn2MT3kBg=";
  };

  nativeBuildInputs = [
    postgresql
    perl
    perlPackages.TAPParserSourceHandlerpgTAP
    which
  ];

  installPhase = ''
    install -D {sql/pgtap--${version}.sql,pgtap.control} -t $out
  '';

  meta = with lib; {
    description = "A unit testing framework for PostgreSQL";
    longDescription = ''
      pgTAP is a unit testing framework for PostgreSQL written in PL/pgSQL and PL/SQL.
      It includes a comprehensive collection of TAP-emitting assertion functions,
      as well as the ability to integrate with other TAP-emitting test frameworks.
      It can also be used in the xUnit testing style.
    '';
    maintainers = with maintainers; [ samrose ];
    homepage = "https://pgtap.org";
    inherit (postgresql.meta) platforms;
    license = licenses.mit;
  };
}
