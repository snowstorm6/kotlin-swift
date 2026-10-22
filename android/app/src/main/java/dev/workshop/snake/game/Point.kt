package dev.workshop.snake.game

/**
 * Một ô trên lưới. (0, 0) là góc trên bên trái.
 *
 * `data class` tự sinh equals/hashCode/toString/copy, nên hai Point cùng toạ độ là "bằng nhau"
 * (`==`, `in`, `contains` đều dựa vào đó).
 */
data class Point(val x: Int, val y: Int) {
    /** Ô kế bên theo một hướng: `head + Direction.UP`. */
    operator fun plus(direction: Direction): Point = Point(x + direction.dx, y + direction.dy)
}
