FROM ubuntu:16.04
MAINTAINER myfreeer

# Install
RUN apt-get update
RUN apt-get install -y build-essential checkinstall bison flex gettext git mercurial subversion ninja-build gyp cmake yasm nasm automake pkg-config libtool libtool-bin gcc-multilib g++-multilib libgmp-dev libmpfr-dev libmpc-dev libgcrypt-dev gperf ragel texinfo autopoint re2c asciidoc python-docutils rst2pdf docbook2x unzip p7zip-full

RUN ./mpv-build-lite.sh
