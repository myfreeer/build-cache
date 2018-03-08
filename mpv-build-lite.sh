#!/bin/bash
# clone repo
git clone https://github.com/myfreeer/mpv-build-lite.git --depth=1
cd mpv-build-lite

# init toolchain versions
gcc_version="$(cat toolchain/CMakeLists.txt | grep -ioP 'gcc-\d+\.\d+\.\d+' | sort -u | grep -ioP '[\d\.]+')"
binutils_version="$(cat toolchain/CMakeLists.txt | grep -ioP 'binutils-\d+\.\d+' | sort -u | grep -ioP '[\d\.]+')"

# patch source to drop msys2-only workaround
sed -i '/GIT_TAG "v2017.2"/d' packages/spirv-tools.cmake

# init cmake
mkdir -p build64
cd build64
cmake -DTARGET_ARCH=x86_64-w64-mingw32 -G Ninja ..
chmod +x exec
# toolchain building and uploading
# Thanks to https://github.com/mpv-android/mpv-android
upload_to_github() {
    local file="$1"
    local release_id=9992583
    local repo="myfreeer/build-cache"
    local Content_Type=application/octet-stream
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "Uploading ${file}..."
        curl -H "Authorization: token $GITHUB_TOKEN" -H "Content-Type: ${Content_Type}" --data-binary @$file \
            "https://uploads.github.com/repos/${repo}/releases/${release_id}/assets?name=${file}"
    fi
}

build_toolchain() {
    echo Building toolchain gcc-$gcc_version binutils-$binutils_version...
    ninja gcc
    if [ -n "$GITHUB_TOKEN" ]; then
        echo Packing toolchain...
        7z a -mx9 "${toolchain_package}" install/*
        echo Uploading toolchain to cache...
        upload_to_github "${toolchain_package}"
    fi
}
# init toolchain
toolchain_package="gcc-${gcc_version}_binutils-${binutils_version}.7z"

wget -nv "https://github.com/myfreeer/build-cache/releases/download/cache/${toolchain_package}" && \
     7z x "${toolchain_package}" && rm -f "${toolchain_package}" || build_toolchain

# build packages
ninja shaderc
7z a -mx9 shaderc.7z ./install/mingw/lib/libshaderc_combined.a
upload_to_github shaderc.7z
7z a -mx9 -r logs.7z *.log *.cmake *.ninja *.txt
curl -F'file=@logs.7z' https://0x0.st
