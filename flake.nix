{
  description = "example mixed stack application targeting docker";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/23.11-pre";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mainAppDependencies = [
          pkgs.poetry
          pkgs.caddy
          pkgs.glibcLocales  # for potential poetry potholes
          # for the launcher
          pkgs.bash
      ];
    in {
      devShell.${system} = pkgs.mkShell {
        buildInputs = mainAppDependencies ++ [
          pkgs.docker
          pkgs.gnumake
        ];
        shellHook = ''
          source ./scripts/start.sh
        '';
      };

      packages.${system} = {
        mainApplication = pkgs.stdenv.mkDerivation {
          name = "main application";

          src = ./.;

          nativeBuildInputs = [
            pkgs.which
            pkgs.rsync
            pkgs.curl
          ];

          buildInputs = mainAppDependencies ++ [
            # TODO: link up realpath, dirname, pushd, popd so scratch works
            pkgs.coreutils
          ];

          buildPhase = ''
            mkdir -p $out
            rsync -av $src/ $out/src
            chmod -R u+rw $out/src
            cd $out/src/webserver
            export POETRY_VIRTUALENVS_IN_PROJECT=true
            export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
            # poetry shenanigans? https://github.com/python-poetry/poetry/issues/3412
            export LC_ALL=en_US.UTF-8
            export LANG=en_US.UTF-8
            export LANGUAGE=en_US.UTF-8
            # this *probably* helps bypass nix's build-time dir at /homeless-shelter where nothing is writable by poetry (it seems? fails silently after announcing install plan)
            export HOME=$PWD
            # or it's just poetry shenanigans: --no-ansi https://github.com/python-poetry/poetry/issues/7148#issuecomment-1363018085
            # this step does seem critical
            poetry install -vvv --no-ansi --only main
          '';

          installPhase = ''
            mkdir -p $out/bin
            cd webserver
            ln -s ${pkgs.caddy}/bin/caddy $out/bin/
            ln -s ${pkgs.poetry}/bin/poetry $out/bin/
            ln -s $out/src/scripts/start.sh $out/bin/start
            chmod +x $out/bin/start
            cd -
          '';
        };
      };

    };
}

