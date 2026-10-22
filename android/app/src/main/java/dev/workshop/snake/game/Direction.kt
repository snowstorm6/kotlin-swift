package dev.workshop.snake.game

/** Bốn hướng di chuyển. `dy` âm là đi lên vì trục y hướng xuống. */
enum class Direction(val dx: Int, val dy: Int) {
    UP(0, -1),
    DOWN(0, 1),
    LEFT(-1, 0),
    RIGHT(1, 0),
}

// TODO 3 ✓ Extension: thêm property cho enum có sẵn mà không sửa enum.
val Direction.opposite: Direction
    get() = when (this) {
        Direction.UP -> Direction.DOWN
        Direction.DOWN -> Direction.UP
        Direction.LEFT -> Direction.RIGHT
        Direction.RIGHT -> Direction.LEFT
    }
