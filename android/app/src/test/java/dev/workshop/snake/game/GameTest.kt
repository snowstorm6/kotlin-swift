package dev.workshop.snake.game

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

// Chạy: ./gradlew test (hoặc bấm ▶ cạnh tên class trong Android Studio).
// Ở nhánh main các test TODO sẽ đỏ; làm xong TODO nào thì test của TODO đó xanh.

/** Đầu rắn xuất phát ở (4, 10), đi sang phải, bàn 20×20. */
private val startHead = Point(4, 10)

/** Spawner cố định: luôn đặt mồi ở `at` nếu ô đó còn trống. */
private fun fixedFood(at: Point?) = FoodSpawner { free -> at?.takeIf { it in free } }

/** Bắt đầu ván và cho rắn đi thẳng sang phải `ticks` bước. */
private fun Game.startAndRun(ticks: Int) = apply {
    turn(Direction.RIGHT)
    repeat(ticks) { tick() }
}

class GameTest {
    @Test
    fun `chưa chọn hướng thì rắn đứng yên`() {
        val game = Game(spawner = fixedFood(null))
        repeat(3) { game.tick() }
        assertEquals(startHead, game.snake.head)
    }

    @Test
    fun `tạm dừng thì rắn đứng yên, chơi tiếp thì đi`() {
        val game = Game(spawner = fixedFood(null)).startAndRun(1)
        game.pauseOrResume()
        game.tick()
        assertEquals(Point(5, 10), game.snake.head)
        game.pauseOrResume()
        game.tick()
        assertEquals(Point(6, 10), game.snake.head)
    }

    @Test
    fun `bấm nhanh hai phím trong một tick vẫn rẽ đủ hai lần`() {
        val game = Game(spawner = fixedFood(null))
        game.turn(Direction.UP)
        game.turn(Direction.LEFT)
        repeat(2) { game.tick() }
        assertEquals(Point(3, 9), game.snake.head)
        assertEquals(GameState.Running, game.state)
    }
}

class Todo1NullSafetyTest {
    @Test
    fun `ăn mồi thì được 1 điểm và rắn dài thêm 1 đốt`() {
        val game = Game(spawner = fixedFood(Point(6, 10))).startAndRun(2)
        assertEquals(1, game.score)
        assertEquals(4, game.snake.body.size)
    }

    @Test
    fun `không còn chỗ đặt mồi thì vẫn chơi bình thường`() {
        val game = Game(spawner = fixedFood(null)).startAndRun(3)
        assertNull(game.food)
        assertEquals(0, game.score)
        assertEquals(3, game.snake.body.size)
    }
}

class Todo2DataModelTest {
    @Test
    fun `đầu rắn trùng một đốt thân là tự cắn`() {
        val coiled = Snake(listOf(Point(1, 1), Point(2, 1), Point(2, 2), Point(1, 2), Point(1, 1)))
        assertTrue(coiled.hitsItself())
    }

    @Test
    fun `rắn thẳng thì không tự cắn`() {
        assertEquals(false, Snake(listOf(Point(3, 1), Point(2, 1), Point(1, 1))).hitsItself())
    }

    @Test
    fun `đâm tường thì rắn không còn chạy`() {
        val game = Game(spawner = fixedFood(null)).startAndRun(16)
        assertNotEquals(GameState.Running, game.state)
    }
}

class Todo3ExtensionTest {
    @Test
    fun `rẽ ngược chiều đang đi thì bị bỏ qua`() {
        val game = Game(spawner = fixedFood(null)).startAndRun(1)
        game.turn(Direction.LEFT)
        game.tick()
        assertEquals(Direction.RIGHT, game.direction)
        assertEquals(Point(6, 10), game.snake.head)
    }
}

class Todo4SealedTest {
    @Test
    fun `thua thì hiện Game Over kèm số điểm`() {
        val game = Game(spawner = fixedFood(Point(6, 10))).startAndRun(16)
        val text = game.state.overlayText().orEmpty()
        assertTrue("Chữ hiện ra là: $text", text.startsWith("Game Over · 1 điểm"))
    }

    @Test
    fun `đã thua thì tick không làm gì nữa`() {
        val game = Game(spawner = fixedFood(null)).startAndRun(16)
        val headAfterCrash = game.snake.head
        game.tick()
        assertEquals(headAfterCrash, game.snake.head)
        assertTrue(game.state.overlayText().orEmpty().startsWith("Game Over"))
    }
}
