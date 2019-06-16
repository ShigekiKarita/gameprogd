import game : Game;
import bindbc.sdl;

@nogc:

void main()
{
    auto window = SDL_CreateWindow(
        &"Game Programming in D (Chapter 2)"[0], // Window title
        100,	// Top left x-coordinate of window
        100,	// Top left y-coordinate of window
        1024,	// Width of window
        768,	// Height of window
        SDL_WINDOW_SHOWN // | SDL_WINDOW_RESIZABLE
        );

    auto game = Game(window);
    game.loop();
}
