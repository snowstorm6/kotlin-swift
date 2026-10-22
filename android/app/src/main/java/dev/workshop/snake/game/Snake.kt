package dev.workshop.snake.game

/**
 * Con rắn: danh sách các đốt, đốt đầu tiên là đầu.
 *
 * Bất biến: `move` không sửa rắn hiện tại mà trả về một con rắn mới (qua `copy`).
 */
data class Snake(val body: List<Point>) {
    val head: Point get() = body.first()

    /** Rắn đi một bước. `grow = true` thì giữ lại đuôi (vừa ăn mồi). */
    fun move(direction: Direction, grow: Boolean = false): Snake {
        val newHead = head + direction
        val tail = if (grow) body else body.dropLast(1)
        return copy(body = listOf(newHead) + tail)
    }

    // TODO 2 ✓ `in` gọi equals() mà data class đã sinh sẵn.
    fun hitsItself(): Boolean = head in body.drop(1)
}
