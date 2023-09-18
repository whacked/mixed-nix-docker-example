docker-image:
ifeq ($(shell uname -m),arm64)  # apple silicon
	DOCKER_BUILDKIT=1 docker buildx build \
					--platform=linux/amd64 \
					--ssh=default \
					-t test . --progress=plain
else
	DOCKER_BUILDKIT=1 docker build \
					--ssh=default \
					-t test . --progress=plain
endif


result:
	nix \
		--option filter-syscalls false \
		build .#packages.x86_64-linux.mainApplication \
		--no-sandbox --print-build-logs --impure

