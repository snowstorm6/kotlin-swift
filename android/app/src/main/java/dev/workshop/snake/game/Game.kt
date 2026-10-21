package dev.workshop.snake.game

/**
 * Toàn bộ luật chơi. Game không biết gì về màn hình, bàn phím hay thời gian thực:
 * nó chỉ nhận lệnh và chạy từng bước khi được gọi. Phần giao diện (app hoặc Terminal) lo phần còn lại.
 *
 * Giao diện nói chuyện với Game qua 3 cửa:
 *  - `turn(hướng)`      khi người chơi bấm phím hướng: chỉ xếp lệnh vào hàng đợi, chưa đổi gì ngay.
 *  - `primaryAction()`  khi bấm Space / chạm bàn chơi: tạm dừng, chơi tiếp, hoặc chơi lại.
 *  - `tick()`           gọi đều đặn từ game loop: luật chơi chạy đúng một bước (xem các bước ở tick()).
 * Sau mỗi tick, giao diện đọc `snake`, `foods`, `score`, `state` để vẽ lại.
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

    /** Make 1: mồi thường, luôn có (trừ khi kín bàn). */
    private var staple: Food? = null

    /** Make 1: mồi đặc biệt, thỉnh thoảng mới có và tự biến mất. */
    private var bonus: Food? = null

    /** Mọi mồi đang có trên bàn, đủ loại. */
    val foods: List<Food> get() = listOfNotNull(staple, bonus)
    var score: Int = 0
        private set
    var state: GameState = GameState.Ready
        private set

    /**
     * Command pattern: phím bấm được xếp hàng, mỗi tick xử lý đúng một phím.
     * Nhờ vậy bấm nhanh ↑ rồi ← trong cùng một tick vẫn ra đúng hai lượt rẽ.
     */
    private val pendingTurns = ArrayDeque<Direction>()

    /** Số tick đã chạy, để biết khi nào mồi đặc biệt hết hạn. */
    private var ticks = 0

    /** Số đốt rắn còn phải dài thêm (ăn táo vàng thì dài thêm 3 đốt trong 3 tick tới). */
    private var pendingGrowth = 0

    /** Make 1: Game cho mồi tác động lên mình qua interface hẹp này, không lộ cả Game ra. */
    private val effects = object : FoodEffects {
        override fun addScore(points: Int) {
            score += points
        }

        override fun grow(segments: Int) {
            pendingGrowth += segments
        }

        override fun shrink(segments: Int) {
            snake = snake.shrunk(segments, GameRules.MIN_SNAKE_LENGTH)
        }
    }

    init {
        refillFood()
    }

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
            is GameState.GameOver -> restart()
        }
    }

    /**
     * Một bước của game. Game loop gọi hàm này đều đặn, mỗi lần rắn đi đúng một ô:
     *  1. Chỉ chạy khi đang Running. Ready, Paused, GameOver thì rắn đứng yên.
     *  2. applyNextTurn(): lấy một lượt rẽ từ hàng đợi, bỏ qua nếu là quay đầu (TODO 3).
     *  3. eat(): ô ngay trước đầu rắn có mồi thì mồi đó tự áp hiệu ứng: cộng điểm, dài thêm
     *     hoặc ngắn lại (TODO 1, Make 1).
     *  4. move(): rắn tiến một ô. Còn đốt phải dài thêm (pendingGrowth) thì giữ lại đuôi.
     *  5. Va chạm: đầu ra ngoài lưới hoặc tự cắn mình (TODO 2) thì crash(), chuyển sang GameOver (TODO 4).
     *     Không va chạm thì refillFood(): đặt lại mồi thường, bỏ mồi đặc biệt hết hạn, có khi thêm mồi mới.
     */
    fun tick() {
        // 1.
        if (state != GameState.Running) return
        ticks++
        // 2.
        applyNextTurn()
        // 3.
        eat(snake.head + direction)
        // 4.
        val grow = pendingGrowth > 0
        if (grow) pendingGrowth--
        snake = snake.move(direction, grow)

        // 5.
        // TODO 2 ✓
        if (isOutside(snake.head) || snake.hitsItself()) crash() else refillFood()
    }

    /** Về lại màn chờ với rắn mới, điểm 0, mồi mới. */
    fun restart() {
        snake = startSnake()
        direction = Direction.RIGHT
        pendingTurns.clear()
        score = 0
        ticks = 0
        pendingGrowth = 0
        staple = null
        bonus = null
        refillFood()
        state = GameState.Ready
    }

    private fun applyNextTurn() {
        val newDirection = pendingTurns.removeFirstOrNull() ?: return
        // TODO 3 ✓
        if (newDirection != direction.opposite) direction = newDirection
    }

    /** Ăn mồi ở ô `next` nếu có. Mỗi loại mồi tự áp hiệu ứng của mình. */
    private fun eat(next: Point) {
        // TODO 1 ✓ firstOrNull trả về Food?, `?: return` giống `guard let ... else { return }` bên Swift.
        val food = foods.firstOrNull { it.position == next } ?: return
        if (food === staple) staple = null else bonus = null
        food.applyTo(effects)
    }

    /** Đặt lại mồi thường nếu vừa bị ăn, bỏ mồi đặc biệt hết hạn, thỉnh thoảng thêm mồi đặc biệt mới. */
    private fun refillFood() {
        if (bonus?.isExpired(ticks) == true) bonus = null
        if (staple == null) staple = spawner.spawn(freeCells())?.let(::Apple)
        if (bonus == null) bonus = spawner.spawnBonus(freeCells(), ticks)
    }

    private fun isOutside(p: Point): Boolean = p.x !in 0 until width || p.y !in 0 until height

    private fun crash() {
        // TODO 4 ✓
        state = GameState.GameOver(score)
    }

    private fun startSnake(): Snake {
        val y = height / 2
        return Snake(List(START_LENGTH) { i -> Point(START_LENGTH + 1 - i, y) })
    }

    private fun freeCells(): List<Point> {
        val occupied = snake.body.toSet() + foods.map { it.position }
        return (0 until height).flatMap { y -> (0 until width).map { x -> Point(x, y) } }
            .filterNot { it in occupied }
    }

    private companion object {
        const val START_LENGTH = 3
        const val MAX_PENDING_TURNS = 2
    }
}
