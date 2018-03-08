FROM base/devel
MAINTAINER myfreeer

# Install
RUN pacman -Syu git gyp mercurial ninja cmake ragel yasm nasm asciidoc enca gperf unzip p7zip gcc-multilib python2-pip python-docutils python2-rst2pdf python2-lxml python2-pillow --noconfirm --needed --noprogressbar
ADD mpv-build-lite.sh /root/script.sh
RUN /root/script.sh
