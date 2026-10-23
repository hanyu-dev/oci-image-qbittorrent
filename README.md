# oci-image-qbittorrent

Third-party rootless reproducible OCI image of [qBittorrent](https://github.com/qbittorrent/qBittorrent/).

## Reproducibility

To verify the reproducibility of the build, you can use the following command to build the image locally and compare the digest with the one published on GitHub Container Registry (ghcr.io).

```bash
export IMAGE_NAME=hanyu-dev/oci-image-qbittorrent
export IMAGE_REGISTRY=ghcr.io
export IMAGE_X86_MICRO_ARCH_VARIANTS="x86-64-v3,x86-64-v2"

# See .github/workflows/build-image.yaml
export IMAGE_DEP_ZLIB_VERSION=
export IMAGE_DEP_ZLIB_COMMIT=
export IMAGE_DEP_OPENSSL_VERSION=
export IMAGE_DEP_OPENSSL_COMMIT=
export IMAGE_DEP_BOOST_VERSION=
export IMAGE_DEP_BOOST_COMMIT=
export IMAGE_DEP_LIBTORRENT_VERSION=
export IMAGE_DEP_LIBTORRENT_COMMIT=
export IMAGE_DEP_QT_VERSION=
export IMAGE_DEP_QT_BASE_COMMIT=
export IMAGE_DEP_QT_TOOLS_COMMIT=
export IMAGE_QBITTORRENT_VERSION=
export IMAGE_QBITTORRENT_COMMIT=
export IMAGE_BUILD_REVISION=

# See .github/workflows/build-image.yaml
export IMAGE_BUILDAH_VERSION=
export IMAGE_BUILDAH_DIGEST=

podman run \
    --rm -it \
    --device /dev/fuse \
    --security-opt label=disable \
    -v "$PWD:/workspace" \
    -w /workspace \
    -e IMAGE_NAME="${IMAGE_NAME}" \
    -e IMAGE_REGISTRY="${IMAGE_REGISTRY}" \
    -e IMAGE_X86_MICRO_ARCH_VARIANTS="${IMAGE_X86_MICRO_ARCH_VARIANTS}" \
    -e IMAGE_DEP_ZLIB_VERSION="${IMAGE_DEP_ZLIB_VERSION}" \
    -e IMAGE_DEP_ZLIB_COMMIT="${IMAGE_DEP_ZLIB_COMMIT}" \
    -e IMAGE_DEP_OPENSSL_VERSION="${IMAGE_DEP_OPENSSL_VERSION}" \
    -e IMAGE_DEP_OPENSSL_COMMIT="${IMAGE_DEP_OPENSSL_COMMIT}" \
    -e IMAGE_DEP_BOOST_VERSION="${IMAGE_DEP_BOOST_VERSION}" \
    -e IMAGE_DEP_BOOST_COMMIT="${IMAGE_DEP_BOOST_COMMIT}" \
    -e IMAGE_DEP_LIBTORRENT_VERSION="${IMAGE_DEP_LIBTORRENT_VERSION}" \
    -e IMAGE_DEP_LIBTORRENT_COMMIT="${IMAGE_DEP_LIBTORRENT_COMMIT}" \
    -e IMAGE_DEP_QT_VERSION="${IMAGE_DEP_QT_VERSION}" \
    -e IMAGE_DEP_QT_BASE_COMMIT="${IMAGE_DEP_QT_BASE_COMMIT}" \
    -e IMAGE_DEP_QT_TOOLS_COMMIT="${IMAGE_DEP_QT_TOOLS_COMMIT}" \
    -e IMAGE_QBITTORRENT_VERSION="${IMAGE_QBITTORRENT_VERSION}" \
    -e IMAGE_QBITTORRENT_COMMIT="${IMAGE_QBITTORRENT_COMMIT}" \
    -e IMAGE_BUILD_REVISION="${IMAGE_BUILD_REVISION}" \
    --user=root \
    quay.io/buildah/stable:v${IMAGE_BUILDAH_VERSION}@sha256:${IMAGE_BUILDAH_DIGEST} \
    ./build.sh
```

## License

The build scripts, Dockerfile, quadlet, and other assets in this repository are released under the MIT License. The qBittorrent binary and image contents are distributed under the qBittorrent project's GPL-3.0-or-later terms.
