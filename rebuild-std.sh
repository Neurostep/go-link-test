#!/bin/bash

set -e

## Windows 64bit
CGO_ENABLED=1 GOOS=windows CXX="x86_64-w64-mingw32-g++" CC="x86_64-w64-mingw32-gcc -fno-stack-protector -lssp" go install -v std

## Windows 32bit
CGO_ENABLED=1 GOARCH=386 GOOS=windows CXX="i686-w64-mingw32-g++" CC="i686-w64-mingw32-gcc -fno-stack-protector -lssp" go install -v std

## Windows 64bit static
CGO_ENABLED=1 GOOS=windows CXX="x86_64-w64-mingw32-g++" CC="x86_64-w64-mingw32-gcc -fno-stack-protector -lssp" go install -v -ldflags '-linkmode=external -extldflags "-static -static-libgcc -static-libstdc++"' std
