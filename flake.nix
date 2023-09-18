{
  description = "example mixed stack application targeting docker";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.11-pre";
    flake-utils.url = "github:numtide/flake-utils";
  };


  outputs = { self, nixpkgs, flake-utils, ... }:
  flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
    mainAppDependencies = [
      pkgs.poetry
      pkgs.caddy
      pkgs.glibcLocales  # for potential poetry potholes
      # for the launcher
      pkgs.bash
    ];
    goComponent = import ./gocomponent/default.nix { inherit pkgs; };

    pathsSourceScript = pkgs.writeScript "paths.sh" ''
      #!/usr/bin/env bash
      export GOCOMPONENT_BINARY_PATH=${goComponent}/bin/example
    '';
  in {
    devShell = pkgs.mkShell {
      buildInputs = mainAppDependencies ++ [
        pkgs.docker
        pkgs.gnumake
      ];
      shellHook = ''
        # TODO: move this
        WORKDIR=$PWD
        # ensure we have a working poetry venv
        export POETRY_VIRTUALENVS_IN_PROJECT=true
        export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
        pushd $WORKDIR/webserver > /dev/null
        if [[ -z $(poetry env info -p) ]]; then
            echo "initializing poetry venv for the first time..."
            poetry install
        fi
        popd > /dev/null
        source ${pathsSourceScript}
        source ./scripts/start.sh
      '';
    };

    packages = {
      mainApplication = pkgs.stdenv.mkDerivation {
        name = "main application";

        src = ./.;

        nativeBuildInputs = [
          pkgs.which
          pkgs.rsync
          pkgs.curl
          pkgs.openssh
        ];

        buildInputs = mainAppDependencies ++ [
          # TODO: link up realpath, dirname, pushd, popd so scratch works
          pkgs.coreutils
        ];

        buildPhase = ''
          # this *probably* helps bypass nix's build-time dir at /homeless-shelter where nothing is writable by poetry (it seems? fails silently after announcing install plan)
          export HOME=$PWD
          # override git+ssh parameters
          # for a deploy key, add "-i /path/to/deploy.key"
          export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/tmp/ssh_known_hosts"
          ssh-keyscan github.com >> /tmp/ssh_known_hosts

          # force the buildkit socket
          export SSH_AUTH_SOCK=/run/buildkit/ssh_agent.0
          ssh-add -L

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
          # or it's just poetry shenanigans: --no-ansi https://github.com/python-poetry/poetry/issues/7148#issuecomment-1363018085
          # --no-ansi does seem critical
          poetry install -vvv --no-ansi --only main
        '';

        installPhase = ''
          mkdir -p $out/bin
          ln -s ${pkgs.caddy}/bin/caddy $out/bin/
          ln -s ${pkgs.poetry}/bin/poetry $out/bin/
          ln -s $out/src/scripts/start.sh $out/bin/start
          install -Dm755 ${pathsSourceScript} $out/bin/paths.sh
          chmod +x $out/bin/start
        '';
      };
    };
  });
}

