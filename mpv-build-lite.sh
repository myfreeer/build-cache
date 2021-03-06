#!/bin/bash
# clone repo
git clone https://github.com/myfreeer/mpv-build-lite.git build --branch=toolchain --depth=1
cd build

# init toolchain versions
gcc_version="$(cat toolchain/gcc-base.cmake | grep -ioP 'gcc-\d+\.\d+\.\d+' | sort -u | grep -ioP '[\d\.]+')"
binutils_version="$(cat toolchain/binutils.cmake | grep -ioP 'binutils-(\d+\.)+\d+' | sort -u | grep -ioP '[\d\.]+')"
gmp_version="$(grep -ioP 'gmp-((\d+\.)+\d+)' packages/gmp.cmake | cut -d'-' -f2)"
xvidcore_version="$(grep -ioP 'xvidcore-((\d+\.)+\d+)' packages/xvidcore.cmake | cut -d'-' -f2)"
libiconv_version="$(grep -ioP 'libiconv-((\d+\.)+\d+)' packages/libiconv.cmake | cut -d'-' -f2)"
expat_version="$(grep -ioP 'expat-((\d+\.)+\d+)' packages/expat.cmake | cut -d'-' -f2)"
lzo_version="$(grep -ioP 'lzo-((\d+\.)+\d+)' packages/lzo.cmake | cut -d'-' -f2)"

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
build_package() {
    local name=$1
    local version="$(eval echo "\${${name}_version}")"
    local package="$(eval echo "\${${name}_package}")"
    local files="$(eval echo "\${${name}_files}")"
    echo Building ${name} ${version}...
    ninja ${name}
    if [ -n "$GITHUB_TOKEN" ]; then
        echo Packing ${name} ${version}...
        7z a -mx9 "${package}" ${files}
        echo Uploading ${name} ${version} to cache...
        upload_to_github "${package}"
    fi
}
build_shaderc() {
    ninja shaderc crossc
    if [ -n "$GITHUB_TOKEN" ]; then
        echo Packing shaderc_and_crossc...
        7z a -mx9 shaderc_and_crossc.7z \
            install/mingw/lib/libshaderc_combined.a \
            install/mingw/include/shaderc/* \
            install/mingw/include/crossc.h \
            install/mingw/lib/pkgconfig/crossc.pc \
            install/mingw/lib/libcrossc.a
        echo Uploading shaderc_and_crossc to cache...
        upload_to_github shaderc_and_crossc.7z
    fi
}
# init toolchain
toolchain_package="gcc-${gcc_version}_binutils-${binutils_version}.7z"
gmp_package="gmp-${gmp_version}.7z"
gmp_files='install/mingw/share/info install/mingw/lib/libgmp* install/mingw/include/gmp.h'
xvidcore_package="xvidcore-${xvidcore_version}.7z"
xvidcore_files='install/mingw/include/xvid.h install/mingw/lib/libxvidcore*'
libiconv_package="libiconv-${libiconv_version}.7z"
libiconv_files='install/mingw/bin/iconv* install/mingw/lib/libcharset* install/mingw/lib/libiconv* install/mingw/lib/charset.alias install/mingw/include/iconv.h install/mingw/include/libcharset.h install/mingw/include/localcharset.h'
expat_package="expat-${expat_version}.7z"
expat_files='install/mingw/bin/xmlwf.exe install/mingw/include/expat* install/mingw/lib/libexpat* install/mingw/lib/pkgconfig/expat.pc'
lzo_package="lzo-${lzo_version}.7z"
lzo_files='install/mingw/include/lzo install/mingw/lib/liblzo2* install/mingw/lib/pkgconfig/lzo2.pc install/mingw/share/doc/lzo'

wget -nv "https://github.com/myfreeer/build-cache/releases/download/cache/${toolchain_package}" && \
     7z x "${toolchain_package}" && rm -f "${toolchain_package}" || build_toolchain

# build versioned packages
wget -nv "https://github.com/myfreeer/build-cache/releases/download/cache/${gmp_package}" && \
     7z x "${gmp_package}" && rm -f "${gmp_package}" || build_package gmp
wget -nv "https://github.com/myfreeer/build-cache/releases/download/cache/${xvidcore_package}" && \
     7z x "${xvidcore_package}" && rm -f "${xvidcore_package}" || build_package xvidcore
wget -nv "https://github.com/myfreeer/build-cache/releases/download/cache/${libiconv_package}" && \
     7z x "${libiconv_package}" && rm -f "${libiconv_package}" || build_package libiconv
wget -nv "https://github.com/myfreeer/build-cache/releases/download/cache/${expat_package}" && \
     7z x "${expat_package}" && rm -f "${expat_package}" || build_package expat
wget -nv "https://github.com/myfreeer/build-cache/releases/download/cache/${lzo_package}" && \
     7z x "${lzo_package}" && rm -f "${lzo_package}" || build_package lzo

# build shaderc and crossc
wget -nv "https://github.com/myfreeer/build-cache/releases/download/cache/shaderc_and_crossc.7z" && \
     7z x "shaderc_and_crossc.7z" && rm -f "shaderc_and_crossc.7z" || build_shaderc

# dump build logs
7z a -mx9 -r logs.7z *.log *.cmake *.ninja *.txt
curl -F'file=@logs.7z' https://0x0.st
