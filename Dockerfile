ARG IMAGE_BUILD_BASE_TAG

FROM ${IMAGE_BUILD_BASE_TAG} AS builder

ARG IMAGE_VCS_DATE_EPOCH

ENV GZIP="-9n"
ENV QT_HASH_SEED=0
ENV QT_RCC_SOURCE_DATE_OVERRIDE=${IMAGE_VCS_DATE_EPOCH}
ENV SOURCE_DATE_EPOCH=${IMAGE_VCS_DATE_EPOCH}

ARG IMAGE_X86_MICRO_ARCH=x86-64-v2

# Hardening follows https://best.openssf.org/Compiler-Hardening-Guides/.
ENV CFLAGS="-O3 -march=${IMAGE_X86_MICRO_ARCH} -mtune=generic -pipe -fdata-sections -ffunction-sections -fPIC -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -fstack-clash-protection -fstack-protector-strong -fno-plt -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing -ftrivial-auto-var-init=zero -fexceptions -fstrict-flex-arrays=3 -fcf-protection=full -pthread -isystem /usr/include/fortify" \
    CXXFLAGS="-O3 -march=${IMAGE_X86_MICRO_ARCH} -mtune=generic -pipe -fdata-sections -ffunction-sections -fPIC -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -fstack-clash-protection -fstack-protector-strong -fno-plt -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing -ftrivial-auto-var-init=zero -fexceptions -fstrict-flex-arrays=3 -fcf-protection=full -pthread -isystem /usr/include/fortify -w" \
    LDFLAGS="-s -pthread -static -Wl,-O1,--as-needed,--sort-common,-z,nodlopen,-z,noexecstack,-z,now,-z,relro,--no-copy-dt-needed-entries,--build-id" \
    LTO_CFLAGS="-flto=auto -fno-fat-lto-objects" \
    LTO_LDFLAGS="-flto -fuse-linker-plugin"

ENV PREFIX=/usr/local \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

# === install: zlib ===

WORKDIR /src/zlib

RUN <<'EOF'
set -e
export AR=gcc-ar
export NM=gcc-nm
export RANLIB=gcc-ranlib
export CFLAGS="${CFLAGS} ${LTO_CFLAGS}"
export LDFLAGS="${LDFLAGS} ${LTO_LDFLAGS}"
./configure --prefix="${PREFIX}" --static
make -j"$(nproc)"
make install
EOF

# === install: openssl ===

WORKDIR /src/openssl

RUN <<'EOF'
set -e
./config \
    threads \
    no-shared \
    no-dso \
    no-docs \
    no-apps \
    no-tests \
    no-async \
    no-comp \
    no-idea \
    no-mdc2 \
    no-rc5 \
    no-ec2m \
    no-ssl3 \
    no-seed \
    no-weak-ssl-ciphers \
    --prefix="${PREFIX}" \
    --libdir=lib \
    --openssldir=/etc/ssl \
    --release
make -j"$(nproc)"
make install_sw
EOF

# === install: boost (headers only) ===

WORKDIR /src/boost

RUN <<'EOF'
set -e
mkdir ./build
cmake -G Ninja -S ./ -B ./build \
    -D CMAKE_INSTALL_PREFIX=${PREFIX}/boost \
    -D CMAKE_CXX_STANDARD=20 \
    -D CMAKE_AUTOMOC_PATH_PREFIX=ON \
    -D BUILD_SHARED_LIBS=OFF
cmake --build ./build --target install
EOF

# === build: libtorrent ===

WORKDIR /src/libtorrent

RUN <<'EOF'
set -e
export CFLAGS="${CFLAGS} ${LTO_CFLAGS}"
export CXXFLAGS="${CXXFLAGS} ${LTO_CFLAGS}"
export LDFLAGS="${LDFLAGS} ${LTO_LDFLAGS}"
mkdir -p ./build
cmake -G Ninja -S . -B ./build \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_CXX_STANDARD=20 \
    -D CMAKE_INSTALL_PREFIX="${PREFIX}" \
    -D CMAKE_INSTALL_LIBDIR=lib \
    -D CMAKE_PREFIX_PATH="${PREFIX};${PREFIX}/boost" \
    -D CMAKE_C_FLAGS="${CFLAGS}" \
    -D CMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -D CMAKE_AR=/usr/bin/gcc-ar \
    -D CMAKE_NM=/usr/bin/gcc-nm \
    -D CMAKE_RANLIB=/usr/bin/gcc-ranlib \
    -D CMAKE_EXE_LINKER_FLAGS="${LDFLAGS}" \
    -D CMAKE_SHARED_LINKER_FLAGS="${LDFLAGS}" \
    -D CMAKE_AUTOMOC_PATH_PREFIX=ON \
    -D BUILD_SHARED_LIBS=OFF \
    -D OPENSSL_USE_STATIC_LIBS=TRUE \
    -D OPENSSL_ROOT_DIR="${PREFIX}" \
    -D OPENSSL_INCLUDE_DIR="${PREFIX}/include" \
    -D OPENSSL_SSL_LIBRARY="${PREFIX}/lib/libssl.a" \
    -D OPENSSL_CRYPTO_LIBRARY="${PREFIX}/lib/libcrypto.a" \
    -D ZLIB_USE_STATIC_LIBS=TRUE \
    -D ZLIB_ROOT="${PREFIX}" \
    -D ZLIB_INCLUDE_DIR="${PREFIX}/include" \
    -D ZLIB_LIBRARY="${PREFIX}/lib/libz.a"
cmake --build ./build
cmake --install ./build
EOF

# === build: qtbase ===

WORKDIR /src/qtbase

RUN <<'EOF'
set -e
export CFLAGS="${CFLAGS} ${LTO_CFLAGS}"
export CXXFLAGS="${CXXFLAGS} ${LTO_CFLAGS}"
export LDFLAGS="${LDFLAGS} ${LTO_LDFLAGS}"
mkdir ./build
cmake -G Ninja -S . -B ./build \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_CXX_STANDARD=20 \
    -D CMAKE_INSTALL_PREFIX="${PREFIX}" \
    -D CMAKE_PREFIX_PATH="${PREFIX}" \
    -D CMAKE_C_FLAGS="${CFLAGS}" \
    -D CMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -D CMAKE_AR=/usr/bin/gcc-ar \
    -D CMAKE_NM=/usr/bin/gcc-nm \
    -D CMAKE_RANLIB=/usr/bin/gcc-ranlib \
    -D CMAKE_EXE_LINKER_FLAGS="${LDFLAGS}" \
    -D CMAKE_SHARED_LINKER_FLAGS="${LDFLAGS}" \
    -D CMAKE_SKIP_RPATH=ON \
    -D CMAKE_SKIP_INSTALL_RPATH=ON \
    -D CMAKE_AUTOMOC_PATH_PREFIX=ON \
    -D BUILD_SHARED_LIBS=OFF \
    -D QT_FEATURE_static=ON \
    -D QT_FEATURE_shared=OFF \
    -D QT_FEATURE_optimize_full=ON \
    -D QT_FEATURE_gui=OFF \
    -D QT_FEATURE_widgets=OFF \
    -D QT_FEATURE_dbus=OFF \
    -D QT_FEATURE_openssl=ON \
    -D QT_FEATURE_openssl_linked=ON \
    -D QT_FEATURE_system_zlib=ON \
    -D QT_FEATURE_system_pcre2=OFF \
    -D QT_FEATURE_system_sqlite=OFF \
    -D QT_FEATURE_system_doubleconversion=OFF \
    -D QT_FEATURE_system_libb2=OFF \
    -D QT_FEATURE_icu=OFF \
    -D QT_FEATURE_glib=OFF \
    -D QT_FEATURE_zstd=OFF \
    -D QT_FEATURE_brotli=OFF \
    -D QT_FEATURE_testlib=OFF \
    -D QT_BUILD_EXAMPLES=OFF \
    -D QT_BUILD_TESTS=OFF \
    -D QT_BUILD_EXAMPLES_BY_DEFAULT=OFF \
    -D QT_BUILD_TESTS_BY_DEFAULT=OFF \
    -D OPENSSL_USE_STATIC_LIBS=TRUE \
    -D OPENSSL_ROOT_DIR="${PREFIX}" \
    -D OPENSSL_INCLUDE_DIR="${PREFIX}/include" \
    -D OPENSSL_SSL_LIBRARY="${PREFIX}/lib/libssl.a" \
    -D OPENSSL_CRYPTO_LIBRARY="${PREFIX}/lib/libcrypto.a" \
    -D ZLIB_USE_STATIC_LIBS=TRUE \
    -D ZLIB_ROOT="${PREFIX}" \
    -D ZLIB_INCLUDE_DIR="${PREFIX}/include" \
    -D ZLIB_LIBRARY="${PREFIX}/lib/libz.a"
cmake --build ./build
cmake --install ./build
EOF

# === build: qttools (Qt6::LinguistTools, required by qBittorrent) ===

WORKDIR /src/qttools

RUN <<'EOF'
set -e
export CFLAGS="${CFLAGS} ${LTO_CFLAGS}"
export CXXFLAGS="${CXXFLAGS} ${LTO_CFLAGS}"
export LDFLAGS="${LDFLAGS} ${LTO_LDFLAGS}"
mkdir ./build
cmake -G Ninja -S . -B ./build \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX="${PREFIX}" \
    -D CMAKE_PREFIX_PATH="${PREFIX}" \
    -D CMAKE_C_FLAGS="${CFLAGS}" \
    -D CMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -D CMAKE_AR=/usr/bin/gcc-ar \
    -D CMAKE_NM=/usr/bin/gcc-nm \
    -D CMAKE_RANLIB=/usr/bin/gcc-ranlib \
    -D CMAKE_EXE_LINKER_FLAGS="${LDFLAGS}" \
    -D CMAKE_SKIP_RPATH=ON \
    -D CMAKE_SKIP_INSTALL_RPATH=ON \
    -D CMAKE_AUTOMOC_PATH_PREFIX=ON \
    -D BUILD_SHARED_LIBS=OFF \
    -D QT_BUILD_EXAMPLES=OFF \
    -D QT_BUILD_TESTS=OFF \
    -D QT_BUILD_EXAMPLES_BY_DEFAULT=OFF \
    -D QT_BUILD_TESTS_BY_DEFAULT=OFF
cmake --build ./build
cmake --install ./build
EOF

# === build: qBittorrent (nox, WebUI) ===

WORKDIR /src/qBittorrent

RUN <<'EOF'
set -e
export CFLAGS="${CFLAGS} ${LTO_CFLAGS}"
export CXXFLAGS="${CXXFLAGS} ${LTO_CFLAGS}"
export LDFLAGS="${LDFLAGS} ${LTO_LDFLAGS}"
mkdir ./build
cmake -G Ninja -S . -B ./build \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_CXX_STANDARD=20 \
    -D CMAKE_INSTALL_PREFIX="${PREFIX}" \
    -D CMAKE_PREFIX_PATH="${PREFIX};${PREFIX}/boost" \
    -D CMAKE_C_FLAGS="${CFLAGS}" \
    -D CMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -D CMAKE_AR=/usr/bin/gcc-ar \
    -D CMAKE_NM=/usr/bin/gcc-nm \
    -D CMAKE_RANLIB=/usr/bin/gcc-ranlib \
    -D CMAKE_EXE_LINKER_FLAGS="${LDFLAGS}" \
    -D CMAKE_SHARED_LINKER_FLAGS="${LDFLAGS}" \
    -D OPENSSL_USE_STATIC_LIBS=TRUE \
    -D OPENSSL_ROOT_DIR="${PREFIX}" \
    -D OPENSSL_INCLUDE_DIR="${PREFIX}/include" \
    -D OPENSSL_SSL_LIBRARY="${PREFIX}/lib/libssl.a" \
    -D OPENSSL_CRYPTO_LIBRARY="${PREFIX}/lib/libcrypto.a" \
    -D ZLIB_USE_STATIC_LIBS=TRUE \
    -D ZLIB_ROOT="${PREFIX}" \
    -D ZLIB_INCLUDE_DIR="${PREFIX}/include" \
    -D ZLIB_LIBRARY="${PREFIX}/lib/libz.a" \
    -D GUI=OFF \
    -D WEBUI=ON \
    -D STACKTRACE=OFF
cmake --build ./build
cmake --install ./build

if readelf -d "${PREFIX}/bin/qbittorrent-nox" 2>/dev/null | grep -q '(NEEDED)'; then
    echo "qbittorrent-nox unexpectedly has dynamic dependencies" >&2
    exit 1
fi

mkdir -p /opt/qBittorrent /opt/qBittorrent/config /opt/qBittorrent/.tmp

install -m 0755 "${PREFIX}/bin/qbittorrent-nox" /opt/qBittorrent/qbittorrent
EOF

FROM scratch

ARG IMAGE_VCS_DATE
ARG IMAGE_VCS_REV

ARG IMAGE_QBITTORRENT_VERSION
ARG IMAGE_BUILD_REVISION

LABEL org.opencontainers.image.title="qBittorrent" \
    org.opencontainers.image.vendor="Hantong Chen" \
    org.opencontainers.image.authors="Hantong Chen" \
    org.opencontainers.image.description="Third-party rootless reproducible OCI image of [qBittorrent](https://github.com/qbittorrent/qBittorrent)." \
    org.opencontainers.image.documentation="https://github.com/hanyu-dev/oci-image-qbittorrent/blob/main/README.md" \
    org.opencontainers.image.source="https://github.com/hanyu-dev/oci-image-qbittorrent" \
    org.opencontainers.image.url="https://github.com/hanyu-dev/oci-image-qbittorrent" \
    org.opencontainers.image.licenses="GPL-3.0-or-later" \
    org.opencontainers.image.created=${IMAGE_VCS_DATE} \
    org.opencontainers.image.version=${IMAGE_QBITTORRENT_VERSION}-r${IMAGE_BUILD_REVISION} \
    org.opencontainers.image.revision=${IMAGE_VCS_REV}

ARG UID=65532
ARG GID=65532

COPY --from=builder --chown="${UID}:${GID}" /opt/qBittorrent /opt/qBittorrent
COPY --chown="${UID}:${GID}" --chmod=0644 ./assets/config/qBittorrent.conf /opt/qBittorrent/config/qBittorrent.conf

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# Fix CA certificates, see: https://github.com/qbittorrent/qBittorrent/issues/14610#issuecomment-808679015
ENV SSL_CERT_DIR=/etc/ssl/certs \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

ENV HOME=/opt/qBittorrent \
    TMPDIR=/opt/qBittorrent/.tmp

ENV QBT_WEBUI_ADDRESS=0.0.0.0 \
    QBT_WEBUI_PORT=6880 \
    QBT_TORRENTING_PORT=52881

EXPOSE 6880 52881 52881/udp

WORKDIR /opt/qBittorrent

USER "${UID}:${GID}"

ENTRYPOINT ["/opt/qBittorrent/qbittorrent"]

CMD ["--confirm-legal-notice", "--profile=/opt"]
