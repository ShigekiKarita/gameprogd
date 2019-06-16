module game;

import core.stdc.stdlib : exit;

import bindbc.sdl;

@nogc:

static this()
{
    // Initialize SDL
    int sdlResult = SDL_Init(SDL_INIT_VIDEO);
    if (sdlResult != 0)
    {
        SDL_Log("Unable to initialize SDL: %s", SDL_GetError());
        exit(1);
    }
}

static ~this()
{
    SDL_Quit();
}

struct Vector2
{
    float x, y;
}

struct Game
{
    @nogc:

    // Window created by SDL
    SDL_Window* mWindow;
    // Renderer for 2D drawing
    SDL_Renderer* mRenderer;
    // Number of ticks since start of game
    uint mTicksCount = 0;
    // Game should continue to run
    bool mIsRunning = true;

    // Pong specific
    // Direction of paddle
    int mPaddleDir = 0;
    // Position of paddle
    Vector2 mPaddlePos;
    // Position of ball
    Vector2 mBallPos;
    // Velocity of ball
    Vector2 mBallVel;

    const int thickness = 15;
    const float paddleH = 100.0f;

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
        //
        const size = this.windowSize();
        mPaddlePos.x = 10.0f;
        mPaddlePos.y = size.height / 2.0f;
        mBallPos.x = size.width / 2.0f;
        mBallPos.y = size.height / 2.0f;
        mBallVel.x = -200.0f;
        mBallVel.y = 235.0f;
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

        // Update paddle direction based on W/S keys
        mPaddleDir = 0;
        if (state[SDL_SCANCODE_W])
        {
            mPaddleDir -= 1;
        }
        if (state[SDL_SCANCODE_S])
        {
            mPaddleDir += 1;
        }
    }

    void update()
    {
        // Wait until 16ms has elapsed since last frame
        while (!SDL_TICKS_PASSED(SDL_GetTicks(), mTicksCount + 16)) {}

        // Delta time is the difference in ticks from last frame
        // (converted to seconds)
        auto deltaTime = (SDL_GetTicks() - mTicksCount) / 1000.0f;

        // Clamp maximum delta time value
        if (deltaTime > 0.05f)
        {
            deltaTime = 0.05f;
        }

        // Update tick counts (for next frame)
        mTicksCount = SDL_GetTicks();

        // Update paddle position based on direction
        const size = this.windowSize();
        if (mPaddleDir != 0)
        {
            mPaddlePos.y += mPaddleDir * 300.0f * deltaTime;
            // Make sure paddle doesn't move off screen!
            if (mPaddlePos.y < (paddleH/2.0f + thickness))
            {
                mPaddlePos.y = paddleH/2.0f + thickness;
            }
            else if (mPaddlePos.y > (size.height - paddleH/2.0f - thickness))
            {
                mPaddlePos.y = size.height - paddleH/2.0f - thickness;
            }
        }

        // Update ball position based on ball velocity
        mBallPos.x += mBallVel.x * deltaTime;
        mBallPos.y += mBallVel.y * deltaTime;
        // Bounce if needed
        // Did we intersect with the paddle?
        auto diff = mPaddlePos.y - mBallPos.y;
        // Take absolute value of difference
        diff = (diff > 0.0f) ? diff : -diff;
        if (// Our y-difference is small enough
            diff <= paddleH / 2.0f &&
            // We are in the correct x-position
            mBallPos.x <= 25.0f && mBallPos.x >= 20.0f &&
            // The ball is moving to the left
            mBallVel.x < 0.0f)
        {
            mBallVel.x *= -1.0f;
        }
        // Did the ball go off the screen? (if so, end game)
        else if (mBallPos.x <= 0.0f)
        {
            mIsRunning = false;
        }
        // Did the ball collide with the right wall?
        else if (mBallPos.x >= (size.width - thickness) && mBallVel.x > 0.0f)
        {
            mBallVel.x *= -1.0f;
        }

        // Did the ball collide with the top wall?
        if (mBallPos.y <= thickness && mBallVel.y < 0.0f)
        {
            mBallVel.y *= -1;
        }
        // Did the ball collide with the bottom wall?
        else if (mBallPos.y >= (size.height - thickness) &&
                 mBallVel.y > 0.0f)
        {
            mBallVel.y *= -1;
        }
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
        // Set draw color to blue
        SDL_SetRenderDrawColor(
            mRenderer,
            0,		// R
            0,		// G
            255,	// B
            255		// A
            );
        // Clear back buffer
        SDL_RenderClear(mRenderer);

        // Draw walls
        SDL_SetRenderDrawColor(mRenderer, 255, 255, 255, 255);

        const size = this.windowSize();

        // Draw top wall
        SDL_Rect wall = {
            0,			// Top left x
            0,			// Top left y
            size.width,		// Width
            thickness	// Height
        };
        SDL_RenderFillRect(mRenderer, &wall);

        // Draw bottom wall
        wall.y = size.height - thickness;
        SDL_RenderFillRect(mRenderer, &wall);

        // Draw right wall
        wall.x = size.width - thickness;
        wall.y = 0;
        wall.w = thickness;
        wall.h = size.width;
        SDL_RenderFillRect(mRenderer, &wall);

        // Draw paddle
        SDL_Rect paddle = {
            cast(int) mPaddlePos.x,
            cast(int) (mPaddlePos.y - paddleH/2),
            thickness,
            cast(int) paddleH
        };
        SDL_RenderFillRect(mRenderer, &paddle);

        // Draw ball
        SDL_Rect ball = {
            cast(int) (mBallPos.x - thickness/2),
            cast(int) (mBallPos.y - thickness/2),
            thickness,
            thickness
        };
        SDL_RenderFillRect(mRenderer, &ball);
        // Swap front buffer and back buffer
        SDL_RenderPresent(mRenderer);
    }
}
