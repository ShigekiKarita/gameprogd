cd $(dirname $0)

if [ ! -e SDL2-devel-2.0.9-VC.zip ]; then
    wget https://www.libsdl.org/release/SDL2-devel-2.0.9-VC.zip
fi
if [ ! -e SDL2_image-devel-2.0.5-VC.zip ]; then
    wget https://www.libsdl.org/projects/SDL_image/release/SDL2_image-devel-2.0.5-VC.zip
fi
if [ ! -e SDL2_ttf-devel-2.0.15-VC.zip ]; then
    wget https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-devel-2.0.15-VC.zip
fi
if [ ! -e SDL2_mixer-devel-2.0.4-VC.zip ]; then
    wget https://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-devel-2.0.4-VC.zip
fi

for s in SDL2-devel-2.0.9 SDL2_image-devel-2.0.5 SDL2_ttf-devel-2.0.15 SDL2_mixer-devel-2.0.4; do
    d="$(pwd)/$(echo $s | sed s/devel-//)/lib/x64"
    echo $d
    if [ ! -e $d ]; then
	unzip ${s}-VC.zip
    fi
    export LIB=${d}:${LIB}
    export PATH=${d}:${PATH}
done

cd -
