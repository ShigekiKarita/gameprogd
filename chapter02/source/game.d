module game;

import core.stdc.stdlib : exit;

import bindbc.sdl;

@nogc:

static this()
{
    // Initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0)
    {
        SDL_Log("Unable to initialize SDL: %s", SDL_GetError());
        exit(1);
    }
    enum flags = IMG_INIT_PNG;
    if (IMG_Init(flags) != flags)
    {
        SDL_Log("Unable to initialize SDL_image: %s", IMG_GetError());
        exit(1);
    }
}

static ~this()
{
    IMG_Quit();
    SDL_Quit();
}

struct Vector2
{
    float x, y;
}

struct Ship {}
struct Actor {}
struct SpriteComponent {}

struct Game
{
    @nogc:

    import containers.hashmap : HashMap;
    import containers.dynamicarray : DynamicArray;

    // // Map of textures loaded
    // HashMap!(string, SDL_Texture*) mTextures;

    // All the actors in the game
    DynamicArray!Actor mActors;
    // Any pending actors
    DynamicArray!Actor mPendingActors;

    // All the sprite components drawn
    DynamicArray!SpriteComponent mSprites;

    // Window created by SDL
    SDL_Window* mWindow;
    // Renderer for 2D drawing
    SDL_Renderer* mRenderer;
    // Number of ticks since start of game
    uint mTicksCount = 0;
    // Game should continue to run
    bool mIsRunning = true;

    // Track if we're updating actors right now
    bool mUpdatingActors;

    // Game-specific
    Ship mShip; // Player's ship


    ~this()
    {
        SDL_DestroyRenderer(mRenderer);
        SDL_DestroyWindow(mWindow);
    }

    this(SDL_Window* window)
    {
        // Create an SDL Window
        mWindow = window;
        if (!this.mWindow)
        {
            SDL_Log("Failed to create window: %s", SDL_GetError());
            exit(1);
        }

        //// Create SDL renderer
        mRenderer = SDL_CreateRenderer(
            mWindow, // Window to create renderer for
            -1,		 // Usually -1
            SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC
            );

        if (!mRenderer)
        {
            SDL_Log("Failed to create renderer: %s", SDL_GetError());
            exit(1);
        }

        const size = this.windowSize();
    }

    void loop()
    {
        while (mIsRunning)
        {
            this.processInput();
            this.update();
            this.render();
        }
    }

    void processInput()
    {
        SDL_Event event;
        while (SDL_PollEvent(&event))
        {
            switch (event.type)
            {
            case SDL_QUIT: // If we get an SDL_QUIT event, end loop
                mIsRunning = false;
                break;
            default:
                break;
            }
        }
        // Get state of keyboard
        // NOTE(karita): fixed typo at bind-sdl at this PR
        // https://github.com/BindBC/bindbc-sdl/pull/13
        const state = SDL_GetKeyboardState(null);
        // If escape is pressed, also end loop
        if (state[SDL_SCANCODE_ESCAPE])
        {
            mIsRunning = false;
        }

        if (state[SDL_SCANCODE_W])
        {

        }
        if (state[SDL_SCANCODE_S])
        {

        }
    }

    void update()
    {
    }

    auto windowSize()
    {
        import std.typecons : tuple;
        int w, h;
        SDL_GetWindowSize(mWindow, &w, &h);
        return tuple!("width", "height")(w, h);
    }

    void render()
    {
    }
}
