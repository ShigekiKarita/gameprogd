module ship;

import game : Game;

// TODO(karita)
struct Ship {
    @nogc:

    float mRightSpeed = 0.0;
    float mDownSpeed = 0.0;

    this(Game* game) {}
}
