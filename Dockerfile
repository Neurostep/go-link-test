FROM buildpack-deps:stretch-scm as golang-build

RUN apt-get update && apt-get install -y --no-install-recommends \
	g++ \
	gcc \
	libc6-dev \
	make \
	pkg-config \
	&& rm -rf /var/lib/apt/lists/*

ENV GOLANG_VERSION 1.12

RUN set -eux; \
	\
	dpkgArch="$(dpkg --print-architecture)"; \
	case "${dpkgArch##*-}" in \
	#go1.12
	amd64) goRelArch='linux-amd64'; goRelSha256='750a07fef8579ae4839458701f4df690e0b20b8bcce33b437e4df89c451b6f13' ;; \
	armhf) goRelArch='linux-armv6l'; goRelSha256='ea0636f055763d309437461b5817452419411eb1f598dc7f35999fae05bcb79a' ;; \
	arm64) goRelArch='linux-arm64'; goRelSha256='b7bf59c2f1ac48eb587817a2a30b02168ecc99635fc19b6e677cce01406e3fac' ;; \
	i386) goRelArch='linux-386'; goRelSha256='3ac1db65a6fa5c13f424b53ee181755429df0c33775733cede1e0d540440fd7b' ;; \
	ppc64el) goRelArch='linux-ppc64le'; goRelSha256='5be21e7035efa4a270802ea04fb104dc7a54e3492641ae44632170b93166fb68' ;; \
	s390x) goRelArch='linux-s390x'; goRelSha256='c0aef360b99ebb4b834db8b5b22777b73a11fa37b382121b24bf587c40603915' ;; \
	*) goRelArch='src'; goRelSha256='09c43d3336743866f2985f566db0520b36f4992aea2b4b2fd9f52f17049e88f2'; \
	#go1.14
	#amd64) goRelArch='linux-amd64'; goRelSha256='08df79b46b0adf498ea9f320a0f23d6ec59e9003660b4c9c1ce8e5e2c6f823ca' ;; \
    #armhf) goRelArch='linux-armv6l'; goRelSha256='b5e682176d7ad3944404619a39b585453a740a2f82683e789f4279ec285b7ecd' ;; \
    #arm64) goRelArch='linux-arm64'; goRelSha256='cd813387f770c07819912f8ff4b9796a4e317dee92548b7226a19e60ac79eb27' ;; \
    #i386) goRelArch='linux-386'; goRelSha256='cdcdab6c8d1f2dcea3bbec793352ef84db167a2eb6c60ff69e5cf94dca575f9a' ;; \
    #ppc64el) goRelArch='linux-ppc64le'; goRelSha256='b896b5eba616d27fd3bb8218de6bef557cb62221e42f73c84ae4b89cdb602dec' ;; \
    #s390x) goRelArch='linux-s390x'; goRelSha256='22e67470fe872c893face196f02323a11ffe89999260c136b9c50f06619e0243' ;; \
    #*) goRelArch='src'; goRelSha256='6d643e46ad565058c7a39dac01144172ef9bd476521f42148be59249e4b74389'; \
	echo >&2; echo >&2 "warning: current architecture ($dpkgArch) does not have a corresponding Go binary release; will be building from source"; echo >&2 ;; \
	esac; \
	\
	url="https://golang.org/dl/go${GOLANG_VERSION}.${goRelArch}.tar.gz"; \
	wget -O go.tgz "$url"; \
	echo "${goRelSha256} *go.tgz" | sha256sum -c -; \
	tar -C /usr/local -xzf go.tgz; \
	rm go.tgz; \
	\
	if [ "$goRelArch" = 'src' ]; then \
	echo >&2; \
	echo >&2 'error: UNIMPLEMENTED'; \
	echo >&2 'TODO install golang-any from jessie-backports for GOROOT_BOOTSTRAP (and uninstall after build)'; \
	echo >&2; \
	exit 1; \
	fi; \
	\
	export PATH="/usr/local/go/bin:$PATH"; \
	go version

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH

FROM golang-build

USER root

RUN dpkg --add-architecture i386

RUN apt-get update && \
    apt-get -y install git libssl-dev libprotobuf-c-dev \
			gcc-mingw-w64-x86-64 mingw-w64-x86-64-dev g++-mingw-w64-x86-64 mingw-w64 \
			make g++ gcc-multilib g++-multilib \
			mkvtoolnix imagemagick && \
    apt-get -y install libtesseract-dev      libleptonica-dev      libjpeg-dev      libz-dev \
                                                                       libjpeg-dev:i386 libz-dev:i386 && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/*

COPY rebuild-std.sh /usr/local/bin/

RUN rebuild-std.sh

RUN wget --quiet https://www.openssl.org/source/openssl-1.1.1a.tar.gz -O/tmp/openssl.tar.gz && \
	sha256sum /tmp/openssl.tar.gz && echo 'fc20130f8b7cbd2fb918b2f14e2f429e109c31ddd0fb38fc5d71d9ffed3f9f41 /tmp/openssl.tar.gz' | tee | sha256sum -c && \
	cd /tmp && tar xf openssl.tar.gz && cd openssl-1.1.1a && ./Configure --prefix=/opt/mingw64 --cross-compile-prefix=x86_64-w64-mingw32- no-unit-test mingw64 && \
	make -j4 && \
	make install && cd && rm -rf /tmp/openssl*
