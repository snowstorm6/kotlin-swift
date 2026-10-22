package dev.workshop.snake.game

/** Bốn hướng di chuyển. `dy` âm là đi lên vì trục y hướng xuống. */
enum class Direction(val dx: Int, val dy: Int) {
    UP(0, -1),
    DOWN(0, 1),
    LEFT(-1, 0),
    RIGHT(1, 0),
}

// TODO 3 (Extension): viết extension property `opposite` cho Direction,
//  trả về hướng ngược lại (UP ↔ DOWN, LEFT ↔ RIGHT). Không sửa enum ở trên.
//  Sau đó dùng nó trong Game.applyNextTurn().
