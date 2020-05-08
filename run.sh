#!/bin/bash

set -e

BUILDER_IMAGE=${BUILDER_IMAGE:-neurostep/go-linker-test:go114}

WORK_DIR_BASE="/srv/src/github.com/Neurostep"

WORK_DIR="${WORK_DIR_BASE}/go-link-test"

set -x

exec docker run --rm --user=root \
		-v "$PWD":"$WORK_DIR" \
		--entrypoint=/bin/sh "$BUILDER_IMAGE" -c \
		'export GOPATH=/srv && cd '\''/srv/src/github.com/Neurostep/go-link-test'\'' && GOARCH=amd64 GOOS=windows CXX="x86_64-w64-mingw32-g++" CC="x86_64-w64-mingw32-gcc -fno-stack-protector -lssp" CGO_ENABLED=1 go install -ldflags "-v -linkmode=external -extldflags '\'' -static -static-libgcc -static-libstdc++'\''  " ./cmd/test '
