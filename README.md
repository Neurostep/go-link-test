## Go link test

This repository aims to show the case which I have found during my development circle. This repo
contains only the minimum which reproduces the issue (or perhaps a *behavior*) with go linker. 

### The problem

In my project I am using CGO and cross builder feature in order to provide binaries for different
platforms (Linux, Mac, Windows). This project has a long story and the approach has been there
since go version 1.11.

All of sudden, after go version 1.13 the windows build started throwing at me the error with
linking some libraries. After digging a bit deeper in to the problem and setting `-v` flag to
go linker I found out that after 1.13 version Go linker stopped including `-lws2_32` & `-lwinmm`
flags to the GCC compiler. It seems that the behavior of [linking PE imported libraries](https://github.com/golang/go/blob/0f47c12a29e6277c8139e8d4f5a45272e437fe6e/src/cmd/link/internal/ld/lib.go#L1660) has been
changed.

### Usage

There are two docker images to demonstrate the issue:

 - `neurostep/go-linker-test:go114` contains go lang version 1.14 and all auxiliary libs and bins;
 - `neurostep/go-linker-test:go112` contains go lang version 1.12 and all auxiliary libs and bins
 
 By running `BUILDER_IMAGE=neurostep/go-linker-test:go112 ./run.sh` command, you will get
 the output similar to the following
 
 ```
 $ BUILDER_IMAGE=neurostep/go-linker-test:go112 ./run.sh 
 + exec docker run --rm --user=root -v /Users/maksim-terekhin/my-projects/go-link-test:/srv/src/github.com/Neurostep/go-link-test --entrypoint=/bin/sh neurostep/go-linker-test:go112 -c 'export GOPATH=/srv && cd '\''/srv/src/github.com/Neurostep/go-link-test'\'' && GOARCH=amd64 GOOS=windows CXX="x86_64-w64-mingw32-g++" CC="x86_64-w64-mingw32-gcc -fno-stack-protector -lssp" CGO_ENABLED=1 go install -ldflags "-v -linkmode=external -extldflags '\'' -static -static-libgcc -static-libstdc++'\''  " ./cmd/test '
 # github.com/Neurostep/go-link-test/cmd/test
 HEADER = -H11 -T0xffffffffffffffff -D0xffffffffffffffff -R0xffffffff
  0.00 deadcode
  0.01 symsize = 0
  0.01 pclntab=272767 bytes, funcdata total 58698 bytes
  0.01 dodata
  0.01 dwarf
  0.02 reloc
  0.03 asmb
  0.03 codeblk
  0.03 rodatblk
  0.03 datblk
  0.03 sym
  0.03 dwarf
  0.03 headr
  0.03 symsize = 0
  0.09 host link: "x86_64-w64-mingw32-gcc" "-m64" "-mconsole" "-o" "/tmp/go-build955574584/b001/exe/a.out.exe" "/tmp/go-link-708938480/go.o" "/tmp/go-link-708938480/000000.o" "/tmp/go-link-708938480/000001.o" "/tmp/go-link-708938480/000002.o" "/tmp/go-link-708938480/000003.o" "/tmp/go-link-708938480/000004.o" "/tmp/go-link-708938480/000005.o" "/tmp/go-link-708938480/000006.o" "/tmp/go-link-708938480/000007.o" "/tmp/go-link-708938480/000008.o" "-g" "-O2" "-L/opt/mingw64/lib" "-lcrypto" "-g" "-O2" "-no-pie" "-static" "-static-libgcc" "-static-libstdc++" "-Wl,-T,/tmp/go-link-708938480/fix_debug_gdb_scripts.ld" "-Wl,--start-group" "-lmingwex" "-lmingw32" "-Wl,--end-group" "-lwinmm" "-lws2_32" "-lkernel32"
  0.27 cpu time
 25386 symbols
 35076 liveness data

 ```

As you might notice, there are flags `"-lwinmm" "-lws2_32"` printed in the debug info

By running `BUILDER_IMAGE=neurostep/go-linker-test:go114 ./run.sh` command, you will get
the output similar to the following

```
$ BUILDER_IMAGE=neurostep/go-linker-test:go114 ./run.sh
+ exec docker run --rm --user=root -v /Users/maksim-terekhin/my-projects/go-link-test:/srv/src/github.com/Neurostep/go-link-test --entrypoint=/bin/sh neurostep/go-linker-test:go114 -c 'export GOPATH=/srv && cd '\''/srv/src/github.com/Neurostep/go-link-test'\'' && GOARCH=amd64 GOOS=windows CXX="x86_64-w64-mingw32-g++" CC="x86_64-w64-mingw32-gcc -fno-stack-protector -lssp" CGO_ENABLED=1 go install -ldflags "-v -linkmode=external -extldflags '\'' -static -static-libgcc -static-libstdc++'\''  " ./cmd/test '
# github.com/Neurostep/go-link-test/cmd/test
HEADER = -H10 -T0xffffffffffffffff -R0xffffffff
deadcode
symsize = 0
pclntab=305413 bytes, funcdata total 68666 bytes
symsize = 0
host link: "x86_64-w64-mingw32-gcc" "-m64" "-mconsole" "-Wl,--tsaware" "-Wl,--nxcompat" "-Wl,--major-os-version=6" "-Wl,--minor-os-version=1" "-Wl,--major-subsystem-version=6" "-Wl,--minor-subsystem-version=1" "-o" "/tmp/go-build711421856/b001/exe/a.out.exe" "/tmp/go-link-132502817/go.o" "/tmp/go-link-132502817/000000.o" "/tmp/go-link-132502817/000001.o" "/tmp/go-link-132502817/000002.o" "/tmp/go-link-132502817/000003.o" "/tmp/go-link-132502817/000004.o" "/tmp/go-link-132502817/000005.o" "/tmp/go-link-132502817/000006.o" "/tmp/go-link-132502817/000007.o" "/tmp/go-link-132502817/000008.o" "-g" "-O2" "-L/opt/mingw64/lib" "-lcrypto" "-g" "-O2" "-no-pie" "-static" "-static-libgcc" "-static-libstdc++" "-Wl,-T,/tmp/go-link-132502817/fix_debug_gdb_scripts.ld" "-Wl,--start-group" "-lmingwex" "-lmingw32" "-Wl,--end-group" "-lkernel32"
/usr/local/go/pkg/tool/linux_amd64/link: running x86_64-w64-mingw32-gcc failed: exit status 1
/opt/mingw64/lib/libcrypto.a(b_addr.o):b_addr.c:(.text+0xa1): undefined reference to `__imp_getnameinfo'
/opt/mingw64/lib/libcrypto.a(b_addr.o):b_addr.c:(.text+0xd2): undefined reference to `__imp_ntohs'
/opt/mingw64/lib/libcrypto.a(b_addr.o):b_addr.c:(.text+0x1b9): undefined reference to `gai_strerrorW'
/opt/mingw64/lib/libcrypto.a(b_addr.o):b_addr.c:(.text+0x758): undefined reference to `__imp_freeaddrinfo'
/opt/mingw64/lib/libcrypto.a(b_addr.o):b_addr.c:(.text+0xb58): undefined reference to `__imp_getaddrinfo'
/opt/mingw64/lib/libcrypto.a(b_addr.o):b_addr.c:(.text+0xb95): undefined reference to `gai_strerrorW'
/opt/mingw64/lib/libcrypto.a(b_addr.o):b_addr.c:(.text+0xc93): undefined reference to `__imp_getaddrinfo'
/opt/mingw64/lib/libcrypto.a(b_addr.o):b_addr.c:(.text+0xcd0): undefined reference to `gai_strerrorW'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0xc5): undefined reference to `__imp_WSAStartup'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0xd3): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x266): undefined reference to `__imp_WSAStartup'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x274): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x32d): undefined reference to `__imp_ntohs'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x373): undefined reference to `__imp_getsockopt'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x392): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x3a3): undefined reference to `__imp_gethostbyname'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x3f5): undefined reference to `__imp_WSAStartup'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x3ff): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x47d): undefined reference to `__imp_WSACleanup'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x49a): undefined reference to `__imp_ioctlsocket'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x4b2): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x5ca): undefined reference to `__imp_WSAStartup'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x5d8): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x84d): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x8d5): undefined reference to `__imp_setsockopt'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x908): undefined reference to `__imp_ioctlsocket'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x922): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0x988): undefined reference to `__imp_getsockname'
/opt/mingw64/lib/libcrypto.a(b_sock.o):b_sock.c:(.text+0xa02): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x27): undefined reference to `__imp_socket'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x3f): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0xf1): undefined reference to `__imp_setsockopt'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x11a): undefined reference to `__imp_connect'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x19d): undefined reference to `__imp_setsockopt'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x1ab): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x202): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x254): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x2e2): undefined reference to `__imp_bind'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x302): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x3db): undefined reference to `__imp_getsockopt'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x3f0): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x4c3): undefined reference to `__imp_setsockopt'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x4cd): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x54e): undefined reference to `__imp_bind'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x569): undefined reference to `__imp_listen'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x582): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x5f8): undefined reference to `__imp_setsockopt'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x606): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x67d): undefined reference to `__imp_setsockopt'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x68b): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x6dd): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x765): undefined reference to `__imp_accept'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x79d): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x7fa): undefined reference to `__imp_closesocket'
/opt/mingw64/lib/libcrypto.a(b_sock2.o):b_sock2.c:(.text+0x809): undefined reference to `__imp_closesocket'
/opt/mingw64/lib/libcrypto.a(bss_sock.o):bss_sock.c:(.text+0x1df): undefined reference to `__imp_WSASetLastError'
/opt/mingw64/lib/libcrypto.a(bss_sock.o):bss_sock.c:(.text+0x1f2): undefined reference to `__imp_send'
/opt/mingw64/lib/libcrypto.a(bss_sock.o):bss_sock.c:(.text+0x22a): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(bss_sock.o):bss_sock.c:(.text+0x295): undefined reference to `__imp_WSASetLastError'
/opt/mingw64/lib/libcrypto.a(bss_sock.o):bss_sock.c:(.text+0x2aa): undefined reference to `__imp_send'
/opt/mingw64/lib/libcrypto.a(bss_sock.o):bss_sock.c:(.text+0x2da): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(bss_sock.o):bss_sock.c:(.text+0x34d): undefined reference to `__imp_WSASetLastError'
/opt/mingw64/lib/libcrypto.a(bss_sock.o):bss_sock.c:(.text+0x362): undefined reference to `__imp_recv'
/opt/mingw64/lib/libcrypto.a(bss_sock.o):bss_sock.c:(.text+0x38d): undefined reference to `__imp_WSAGetLastError'
/opt/mingw64/lib/libcrypto.a(bss_sock.o):bss_sock.c:(.text+0x445): undefined reference to `__imp_WSAGetLastError'
collect2: error: ld returned 1 exit status
```

As you might notice there is linking error, and we can see there is no `"-lwinmm" "-lws2_32"`
provided to the compiler

### The workaround

To fix linking problem for Go version 1.13+ we can add corresponding flags to linker via `-extldflags`
