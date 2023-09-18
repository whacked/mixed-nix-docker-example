# build this directly using: `nix-build default.nix`
{ pkgs ? import <nixpkgs> {} }:

let
  pname = "example";
  version = "unstable-2023-09-18"; # Adjust as necessary
in

pkgs.stdenv.mkDerivation {
  inherit pname version;

  src = pkgs.fetchFromGitHub {
    owner = "goreleaser";
    repo = pname;
    rev = "59bf452bec66265fc4353b4d6aa43ed170d31282"; # This is the commit as of my last check
    hash = "sha256-INC8SAt3KyA3mu0XCjO/R9YNU7rgaiel0rN+ViZMEeo="; # This is the hash for this commit
  };

  buildInputs = [
    pkgs.go
    # pkgs.git
    # pkgs.openssl
    # pkgs.curl
  ];

  buildPhase = ''
    export GOPATH=$TMPDIR/go
    # workaround for read-only directory at build time (/homeless-shelter)
    export GOCACHE=$TMPDIR/go-cache
    export GO111MODULE=on
    go mod tidy
    go mod vendor
    go build -o $pname
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp $pname $out/bin/
  '';

  meta = with pkgs.lib; {
    description = "exmaple Go module";
  };
}

