#!/bin/bash
#
#  The MIT License (MIT)
#
#  Copyright (c) 2016 Albert Casals - albert@mitako.eu
#  Copyright (c) 2018 Toshi Nagata.
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.
#
#  love2d-build.sh
#
#  Script to run on the RaspberryPI which downloads, builds and installs the Love2d framework.
#  Usage: sh build-love2d.sh [--no-update|--update-only] [--sdl-only] [--openal-only] [--love-only]
#  A directory love2d_build is created, and all build operations are done within it.
#  The install location is /usr/local/games/love, including the SDL2 and OpenAL shared libraries.

mkdir -p love2d-build
mkdir -p love2d-install/love

DIR="$PWD/love2d-build"
INSTALL_DIR="$PWD/love2d-install"
PREFIX="$INSTALL_DIR/love"

cd "$DIR"

BUILD_ALL=1
DO_UPDATE=0
DO_BUILD=0

SDL_VERSION=SDL2-2.0.8
OPENAL_VERSION=openal-soft-1.18.2
LOVE_VERSION=love-11.1

usage() {
  echo "Usage: $0 [ update | build ] [--sdl-only] [--openal-only] [--love-only]"
  exit 1
}

#  Options
for ARG in "$@"
do
  case "$ARG" in
    'update')        DO_UPDATE=1;;
    'build')         DO_BUILD=1;;
    '--sdl-only')    BUILD_ALL=0; DO_BUILD=1; BUILD_SDL=1;;
    '--openal-only') BUILD_ALL=0; DO_BUILD=1; BUILD_OPENAL=1;;
    '--love-only')   BUILD_ALL=0; DO_BUILD=1; BUILD_LOVE=1;;
    -*)              usage;;
  esac
  shift
done

if [ "$DO_UPDATE" = 0 -a "$DO_BUILD" = 0 ]; then
  #  Do all
  DO_UPDATE=1
  DO_BUILD=1
fi

#  Check whether we are running on armv6 or armv7
mach=`uname -m`
if [ "$mach" = "armv7l" ]; then
  ARCHFLAG="-march=armv6"
elif [ "$mach" != "armv6l" ]; then
  echo "We are not running on ARM system (uname -m: $mach)"
  exit 1
fi

export CFLAGS="-I/opt/vc/include -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux $ARCHFLAG"
export LDFLAGS="-L/opt/vc/lib $ARCHFLAG"

#  Install dependencies
if [ "$DO_UPDATE" = "1" ]; then
  echo ">>> Installing dependencies"
  PKGS="
build-essential devscripts pkg-config git-core debhelper dh-autoreconf
libasound2-dev libudev0 libudev-dev libdbus-1-dev libx11-dev libxcursor-dev
libxext-dev libxi-dev libxinerama-dev libxrandr-dev libxss-dev libxt-dev libxxf86vm-dev
libfreetype6-dev libopenal-dev libmodplug-dev libvorbis-dev
libgl1-mesa-dev libibus-1.0-dev
libtheora-dev libphysfs-dev libluajit-5.1-dev libmpg123-dev
libraspberrypi-dev
cmake
"
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends $PKGS
  if [ "$?" != "0" ]; then
    echo ">>> ERROR: Installing dependencies"
    exit 1
  fi
fi

if [ "$DO_BUILD" != "1" ]; then
  exit 0
fi

#  Clean up the target directory, if this is a fresh build
if [ "$BUILD_ALL" = "1" ]; then
  BUILD_SDL=1; BUILD_OPENAL=1; BUILD_LOVE=1
  cd "$PREFIX" && rm -rf *
  cd "$DIR" && rm -rf *
fi

#  Build SDL
if [ "$BUILD_SDL" = "1" ]; then
  echo ">>> Getting SDL2 sources"
  curl -L "https://www.libsdl.org/release/$SDL_VERSION.tar.gz" >"$SDL_VERSION.tar.gz"
  rm -rf "$SDL_VERSION"
  tar -zxf "$SDL_VERSION.tar.gz"
  cd "$SDL_VERSION"

  echo ">>> Building SDL2"
  mkdir build
  cd build
  ../configure --host=arm-raspberry-linux-gnueabihf --prefix="$PREFIX" --disable-pulseaudio --disable-esd --disable-video-mir --disable-video-wayland --disable-video-x11 --disable-video-opengl

  if [ "$?" != "0" ]; then
    echo ">>> ERROR: Could not configure SDL2 libraries"
    exit 1
  fi

  make && make install
  if [ "$?" != "0" ]; then
    echo ">>> ERROR: Could not build SDL2 libraries"
    exit 1
  fi
  
  #  Remove the static version (--disable-static does not work)
  cd "$PREFIX/lib"
  rm -f libSDL2*.a

  cd "$DIR"
  echo ">>> SDL2 build complete."
fi

#  Build OpenAL
if [ "$BUILD_OPENAL" = "1" ]; then
  echo ">>> Building OpenAL"
  curl -L "http://kcat.strangesoft.net/openal-releases/$OPENAL_VERSION.tar.bz2" >"$OPENAL_VERSION.tar.bz2"
  rm -rf "$OPENAL_VERSION"
  tar -jxf "$OPENAL_VERSION.tar.bz2"
  cd "$OPENAL_VERSION/build"
  cmake -DALSOFT_BACKEND_JACK=OFF -DALSOFT_BACKEND_PULSEAUDIO=OFF -DCMAKE_INSTALL_PREFIX="$PREFIX" ..
  if [ "$?" != "0" ]; then
    echo ">>> ERROR: Cannot configure OpenAL"
    exit 1
  fi
  make && make install
  if [ "$?" != "0" ]; then
    echo ">>> ERROR: Cannot build OpenAL"
    exit 1
  fi
  cd "$DIR"
  echo ">>> OpenAL build complete."
fi

#  Build Love2d
if [ "$BUILD_LOVE" = "1" ]; then
  echo ">>> Building Love2D"
  curl -L "https://bitbucket.org/rude/love/downloads/${LOVE_VERSION}-linux-src.tar.gz" > ${LOVE_VERSION}-linux-src.tar.gz
  rm -rf "$LOVE_VERSION"
  tar -xzf "${LOVE_VERSION}-linux-src.tar.gz"
  cd ${LOVE_VERSION}
#  ./configure --prefix="$PREFIX" SDL_CFLAGS="-I$PREFIX/include" SDL_LIBS="-L$PREFIX/lib -lSDL2" openal_CFLAGS="-I$PREFIX/include" openal_LIBS="-L$PREFIX/lib -lopenal"
  ./configure --prefix="$PREFIX" PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
  if [ "$?" != "0" ]; then
    echo ">>> ERROR: Cannot configure Love2D"
    exit 1
  fi
  make && make install
  if [ "$?" != "0" ]; then
    echo ">>> ERROR: Cannot build Love2D"
    exit 1
  fi
  cd "$PREFIX"
  cat <<'EOL' >run_love.sh
#!/bin/sh
export SDL_VIDEO_GL_DRIVER=/opt/vc/lib/libbrcmGLESv2.so
export SDL_VIDEO_EGL_DRIVER=/opt/vc/lib/libbrcmEGL.so
stty -echo
LD_LIBRARY_PATH=/usr/local/games/love/lib:$LD_LIBRARY_PATH /usr/local/games/love/bin/love "$@"
stty echo
EOL
  chmod +x run_love.sh
  cd ..
  cat <<'EOL2' >install.sh
#!/bin/sh
  if [ "$1" != "--no-update" ]; then
    sudo apt-get update
    sudo apt-get install libluajit-5.1-dev libphysfs-dev
  fi
  if [ -e /usr/local/games/love ]; then
    sudo rm -rf /usr/local/games/_love
    sudo mv /usr/local/games/love /usr/local/games/_love
  fi
  sudo mv love /usr/local/games
EOL2
  if [ -e /usr/local/games/love ]; then
    sudo rm -rf /usr/local/games/_love
    sudo mv /usr/local/games/love /usr/local/games/_love
  fi
  sudo cp -R love /usr/local/games
  cd ..
  tar -zcf "$DIR/love2d-install.tar.gz" love2d-install
  cd "$DIR"
  echo ">>> Love2D build complete."
fi

exit 0
