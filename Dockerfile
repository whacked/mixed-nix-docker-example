# syntax = docker/dockerfile:1.2

# Nix builder
FROM nixos/nix AS builder
ENV NIX_CONFIG="experimental-features = nix-command flakes"

# Copy our source and setup our working dir.
COPY . /tmp/build
WORKDIR /tmp/build

# Build the environment using Nix
RUN nix \
    --option filter-syscalls false \
    build .#packages.x86_64-linux.mainApplication


RUN mkdir /tmp/nix-store-closure
RUN cp -R $(nix-store -qR /tmp/build/result) /tmp/nix-store-closure


# Final image is based on scratch. We copy a bunch of Nix dependencies
# but they're fully self-contained so we don't need Nix anymore.
# FROM scratch
# NOTE: as of now, scratch is too bare to run this app; needs at least:
# - realpath
# - dirname
# - pushd
# - popd
# (based on what we run in the start script)
# can probably make this usable by linking necessary paths from coreutils
FROM debian:bullseye-slim

WORKDIR /app

# Copy /nix/store
COPY --from=builder /tmp/nix-store-closure /nix/store
COPY --from=builder /tmp/build/result /app
CMD ["/app/bin/start"]

