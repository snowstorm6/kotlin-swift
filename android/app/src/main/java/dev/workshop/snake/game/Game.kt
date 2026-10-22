package dev.workshop.snake.game

/**
 * Toàn bộ luật chơi. Game không biết gì về màn hình, bàn phím hay thời gian thực:
 * nó chỉ nhận lệnh và chạy từng bước khi được gọi. Phần giao diện (app hoặc Terminal) lo phần còn lại.
 *
 * Giao diện nói chuyện với Game qua 3 cửa:
 *  - `turn(hướng)`      khi người chơi bấm phím hướng: chỉ xếp lệnh vào hàng đợi, chưa đổi gì ngay.
 *  - `primaryAction()`  khi bấm Space / chạm bàn chơi: tạm dừng, chơi tiếp, hoặc chơi lại.
 *  - `tick()`           gọi đều đặn từ game loop: luật chơi chạy đúng một bước (xem các bước ở tick()).
 * Sau mỗi tick, giao diện đọc `snake`, `food`, `score`, `state` để vẽ lại.
 *
 * Pattern dùng ở đây:
 *  - State:    `state` (Ready / Running / Paused / GameOver) quyết định tick() và input làm gì.
 *  - Command:  `pendingTurns` giữ các lượt rẽ chờ xử lý, mỗi tick lấy ra một lượt.
 *  - Strategy: `spawner` quyết định đặt mồi ở đâu: ngẫu nhiên khi chơi, cố định khi chạy test.
 */
class Game(
    val width: Int = 20,
    val height: Int = 20,
    private val spawner: FoodSpawner = RandomFoodSpawner(),
) {
    var snake: Snake = startSnake()
        private set

    /** Hướng rắn đã đi ở tick gần nhất. */
    var direction: Direction = Direction.RIGHT
        private set

    /** Mồi hiện tại. null khi không còn ô trống nào để đặt mồi. */
    var food: Point? = spawnFood()
        private set
    var score: Int = 0
        private set
    var state: GameState = GameState.Ready
        private set

    /**
     * Command pattern: phím bấm được xếp hàng, mỗi tick xử lý đúng một phím.
     * Nhờ vậy bấm nhanh ↑ rồi ← trong cùng một tick vẫn ra đúng hai lượt rẽ.
     */
    private val pendingTurns = ArrayDeque<Direction>()

    /**
     * Người chơi bấm một hướng. Ở màn chờ thì đây cũng là lệnh bắt đầu ván.
     * Hướng chưa đổi ngay: lệnh được xếp hàng và chỉ được áp dụng ở tick() kế tiếp.
     * Hàng đợi giữ tối đa MAX_PENDING_TURNS lệnh để bấm liên tục không bị dồn quá xa.
     */
    fun turn(newDirection: Direction) {
        if (state == GameState.Ready) state = GameState.Running
        if (state == GameState.Running && pendingTurns.size < MAX_PENDING_TURNS) {
            pendingTurns.addLast(newDirection)
        }
    }

    /** Running ⇄ Paused. Ở các trạng thái khác thì không làm gì. */
    fun pauseOrResume() {
        state = when (state) {
            GameState.Running -> GameState.Paused
            GameState.Paused -> GameState.Running
            else -> state
        }
    }

    /** Hành động chính khi chạm bàn chơi hoặc bấm Space: tạm dừng, chơi tiếp, hay chơi lại sau khi thua. */
    fun primaryAction() {
        when (state) {
            GameState.Ready -> Unit
            GameState.Running, GameState.Paused -> pauseOrResume()
            // TODO 4: thêm GameOver xong, `when` này cũng báo thiếu nhánh. Thua rồi thì restart().
        }
    }

    /**
     * Một bước của game. Game loop gọi hàm này đều đặn, mỗi lần rắn đi đúng một ô:
     *  1. Chỉ chạy khi đang Running. Ready, Paused, GameOver thì rắn đứng yên.
     *  2. applyNextTurn(): lấy một lượt rẽ từ hàng đợi, bỏ qua nếu là quay đầu (TODO 3).
     *  3. tryEat(): ô ngay trước đầu rắn có mồi không; có thì cộng điểm, đặt mồi mới (TODO 1).
     *  4. move(): rắn tiến một ô. Vừa ăn thì giữ lại đuôi, nên dài thêm một đốt.
     *  5. Va chạm: đầu ra ngoài lưới hoặc tự cắn mình (TODO 2) thì crash(), chuyển sang GameOver (TODO 4).
     */
    fun tick() {
        // 1.
        if (state != GameState.Running) return
        // 2.
        applyNextTurn()
        // 3.
        val next = snake.head + direction
        val grow = tryEat(next)
        // 4.
        snake = snake.move(direction, grow)

        // 5.
        // TODO 2 (Data model): nếu đầu rắn ra ngoài lưới hoặc tự cắn mình (Snake.hitsItself)
        //  thì gọi crash(). Hiện giờ rắn đi xuyên ra ngoài màn hình.
    }

    /** Về lại màn chờ với rắn mới, điểm 0, mồi mới. */
    fun restart() {
        snake = startSnake()
        direction = Direction.RIGHT
        pendingTurns.clear()
        score = 0
        food = spawnFood()
        state = GameState.Ready
    }

    private fun applyNextTurn() {
        val newDirection = pendingTurns.removeFirstOrNull() ?: return
        // TODO 3: rắn đang đi sang phải mà rẽ trái thì nó tự cắn cổ mình.
        //  Bỏ qua lượt rẽ nếu newDirection là hướng ngược với direction (dùng extension ở Direction.kt).
        direction = newDirection
    }

    /** Trả về true nếu ô `next` đang có mồi: cộng điểm, đặt mồi mới. */
    private fun tryEat(next: Point): Boolean {
        // TODO 1 ✓ `?: return` giống `guard let ... else { return }` bên Swift.
        val current = food ?: return false
        if (current != next) return false
        score += 1
        food = spawnFood()
        return true
    }

    private fun crash() {
        // TODO 4 (Sealed): thay vì về lại màn chờ ngay, chuyển state sang GameOver kèm số điểm.
        restart()
    }

    private fun startSnake(): Snake {
        val y = height / 2
        return Snake(List(START_LENGTH) { i -> Point(START_LENGTH + 1 - i, y) })
    }

    private fun spawnFood(): Point? {
        val occupied = snake.body.toSet()
        val free = (0 until height).flatMap { y -> (0 until width).map { x -> Point(x, y) } }
            .filterNot { it in occupied }
        return spawner.spawn(free)
    }

    private companion object {
        const val START_LENGTH = 3
        const val MAX_PENDING_TURNS = 2
    }
}
