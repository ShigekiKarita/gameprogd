# Game Programming in D

translating C++ codes in https://github.com/gameprogcpp/code

## requirements

### For Ubuntu 

`sudo apt-get install "libsdl2-*-dev"`

### For Windows

download the latest "Development Libraries for Visual C++" from https://www.libsdl.org/download-2.0.php and set enviroment variables `PATH` and `LIB` to the downloaded directory containing SDL2.lib and SDL2.dll e.g., `SDL2-devel-2.0.9-VC/SDL2-2.0.9/lib/x64`.

It is same to the other SDL2 libraries
- https://www.libsdl.org/projects/SDL_image/
- https://www.libsdl.org/projects/SDL_mixer/
- https://www.libsdl.org/projects/SDL_ttf/

If you are using bash shell, `source ./windows/install_sdl2.sh`

##  build

```bash
git submodule update --init --recursive
cd chapter01
dub run
```

see chapterXX/README.md for details.

