docker-image:
ifeq ($(shell uname -m),arm64)  # apple silicon
	docker buildx build --platform=linux/amd64 -t test .
else
	docker build -t test .
endif


result:
	nix \
		--option filter-syscalls false \
		build .#packages.x86_64-linux.mainApplication \
		--no-sandbox -L

