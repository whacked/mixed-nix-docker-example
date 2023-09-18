# example project with a nix-managed "mixed stack" app with a docker image builder


Inspired by the @mitchellh blog post, [Using Nix with Dockerfiles](https://mitchellh.com/writing/nix-with-dockerfiles), this repository contains a sample project with these dev requirements:

1. if you have [Nix](https://nixos.org/) installed, and are on linux/mac, this will Just Work

If you're a nix purist, you may want to turn back now.

More detailed requirements that most devs don't need to care about (but increase difficulty of nixification):

- dev environment is managed by nix using a [nix flake](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html)
- dependencies inside docker are also managed by the nix flake
- all development happens within a devShell
- environment inside docker _mostly_ matches outside docker (you can use devShell inside the container should you choose to)
- builds a _reasonably_ small container

In my experience, at this moment [poetry2nix](https://github.com/nix-community/poetry2nix) is amazing when it works, but is far from a drop-in solution for only a handful of projects with (probably meticulously) curated dependencies, and we haven't even started considering other parts of an application stack like yarn2nix, gomod2nix...  Here, we opt for an impure approach to try to have our cake and eat at least half of it.

We only wrap the dev/build environment and dirtily build the app in `mkDerivation`, then in the Dockerfile, use the nix store closure export method from Mitchell's [example](https://github.com/mitchellh/flask-nix-example) to reduce the final container size.


```sh
$ docker images
REPOSITORY       TAG             IMAGE ID       CREATED          SIZE
nixos/nix        latest          2dd959bb92f3   53 years ago     549MB   <-- build image
<none>           <none>          fb2fb897034a   45 seconds ago   2.19GB  <-- interim image
debian           bullseye-slim   316628d91172   10 days ago      80.5MB  <-- final base image
test             latest          8f43aebe1dca   32 seconds ago   574MB   <-- final completed image
# ...
mitchellh-test   latest          e4ae1e7b918f   7 minutes ago    140MB   <-- mitchellh's example
$ docker run --rm test du -sh /nix
479M	/nix
```

While this example bundles more things (as of now: caddy, fastapi, uvicorn) than Mitchell's example (flask), we're probably pulling in a lot more unneccessary bytes from circumventing a pure build setup. But in terms of the reduction from straight pulling everything from a devShell into the docker image, the reduction is significant. I think this may be an acceptable middle ground to achieve dev/container environment reproducibility.

# usage

in the cloned repo:

quick note on docker: this assumes you have docker server running; if not, we have it bundled in the dev env! But you'll need to activate the server, which can be done ad-hoc using `nix develop; sudo $(which dockerd)`. If you do it this way, you'll either need to make sure your `$USER` is in the `docker` group (e.g. `sudo usermod -aG docker $USER`), or you'd have to run all `docker ...` commands using something like `sudo $(which docker) ...`

```sh
$ nix develop
$ make docker-image
$ docker run --name test-run --rm -it -p 18000:19999 test
2023/09/17 17:01:05.364	INFO	using provided configuration	{"config_file": "/app/src/Caddyfile", "config_adapter": ""}
2023/09/17 17:01:05.365	WARN	Caddyfile input is not formatted; run the 'caddy fmt' command to fix inconsistencies	{"adapter": "caddyfile", "file": "/app/src/Caddyfile", "line": 2}
... caddy stuff ...
2023/09/17 17:01:05.366	INFO	autosaved config (load with --resume flag)	{"file": "/root/.config/caddy/autosave.json"}
2023/09/17 17:01:05.366	INFO	serving initial configuration
INFO:     Started server process [30]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:18000 (Press CTRL+C to quit)
```


in another terminal

```sh
$ curl http://localhost:18000
{"Hello":"World"}
$ docker rm -f test-run
test-run
```

without using docker:

```sh
$ nix develop
$ start-server
INFO:     Started server process [2411525]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:18000 (Press CTRL+C to quit)
```

# TODO

- [ ] add a go dependency to this project
- [ ] add a typescript dependency to this project
- [X] add a package with a private git dependency
  to try this, fork https://github.com/whacked/sample-private-pyproject-repo (or any pyproject repo) to your own github, and run `poetry add git+ssh://git@github.com:youraccount/sample-private-pyproject-repo`.
  we allow this install in `mkDerivation` by using `--no-sandbox`

