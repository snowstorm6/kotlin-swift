/// Toàn bộ luật chơi. Game không biết gì về màn hình, bàn phím hay thời gian thực:
/// nó chỉ nhận lệnh và chạy từng bước khi được gọi. Phần giao diện (app hoặc Terminal) lo phần còn lại.
///
/// Giao diện nói chuyện với Game qua 3 cửa:
///  - `turn(_:)`         khi người chơi bấm phím hướng: chỉ xếp lệnh vào hàng đợi, chưa đổi gì ngay.
///  - `primaryAction()`  khi bấm Space / chạm bàn chơi: tạm dừng, chơi tiếp, hoặc chơi lại.
///  - `tick()`           gọi đều đặn từ game loop: luật chơi chạy đúng một bước (xem các bước ở tick()).
/// Sau mỗi tick, giao diện đọc `snake`, `foods`, `score`, `state` để vẽ lại.
///
/// Pattern dùng ở đây:
///  - State:    `state` (ready / running / paused / gameOver) quyết định tick() và input làm gì.
///  - Command:  `pendingTurns` giữ các lượt rẽ chờ xử lý, mỗi tick lấy ra một lượt.
///  - Strategy: `spawner` quyết định đặt mồi ở đâu: ngẫu nhiên khi chơi, cố định khi chạy test.
///
/// `Game` là struct (value type): mọi hàm làm thay đổi ván chơi đều là `mutating`.
struct Game {
    private static let startLength = 3
    private static let maxPendingTurns = 2

    let width: Int
    let height: Int
    private let spawner: any FoodSpawner

    private(set) var snake: Snake

    /// Hướng rắn đã đi ở tick gần nhất.
    private(set) var direction: Direction = .right

    /// Make 1: mồi thường, luôn có (trừ khi kín bàn).
    private var staple: (any Food)?

    /// Make 1: mồi đặc biệt, thỉnh thoảng mới có và tự biến mất.
    private var bonus: (any Food)?

    /// Mọi mồi đang có trên bàn, đủ loại. `any Food` = hộp chứa bất kỳ kiểu nào conform Food.
    var foods: [any Food] { [staple, bonus].compactMap { $0 } }
    private(set) var score = 0
    private(set) var state: GameState = .ready

    /// Make 2: mili giây giữa hai bước, càng nhiều điểm càng nhanh.
    /// Giá trị suy ra được từ `score` thì để là computed property, không lưu riêng rồi đồng bộ.
    var stepMillis: Int {
        max(GameRules.minStepMillis, GameRules.startStepMillis - score * GameRules.speedupPerPoint)
    }

    /// Command pattern: phím bấm được xếp hàng, mỗi tick xử lý đúng một phím.
    /// Nhờ vậy bấm nhanh ↑ rồi ← trong cùng một tick vẫn ra đúng hai lượt rẽ.
    private var pendingTurns: [Direction] = []

    /// Số tick đã chạy, để biết khi nào mồi đặc biệt hết hạn.
    private var ticks = 0

    /// Số đốt rắn còn phải dài thêm (ăn táo vàng thì dài thêm 3 đốt trong 3 tick tới).
    private var pendingGrowth = 0

    init(width: Int = 20, height: Int = 20, spawner: any FoodSpawner = RandomFoodSpawner()) {
        self.width = width
        self.height = height
        self.spawner = spawner
        snake = Game.startSnake(height: height)
        refillFood()
    }

    /// Người chơi bấm một hướng. Ở màn chờ thì đây cũng là lệnh bắt đầu ván.
    /// Hướng chưa đổi ngay: lệnh được xếp hàng và chỉ được áp dụng ở tick() kế tiếp.
    /// Hàng đợi giữ tối đa maxPendingTurns lệnh để bấm liên tục không bị dồn quá xa.
    mutating func turn(_ newDirection: Direction) {
        if state == .ready { state = .running }
        if state == .running, pendingTurns.count < Game.maxPendingTurns {
            pendingTurns.append(newDirection)
        }
    }

    /// running ⇄ paused. Ở các trạng thái khác thì không làm gì.
    mutating func pauseOrResume() {
        switch state {
        case .running: state = .paused
        case .paused: state = .running
        default: break
        }
    }

    /// Hành động chính khi chạm bàn chơi hoặc bấm Space: tạm dừng, chơi tiếp, hay chơi lại sau khi thua.
    mutating func primaryAction() {
        switch state {
        case .ready: break
        case .running, .paused: pauseOrResume()
        case .gameOver: restart()
        }
    }

    /// Một bước của game. Game loop gọi hàm này đều đặn, mỗi lần rắn đi đúng một ô:
    ///  1. Chỉ chạy khi đang running. ready, paused, gameOver thì rắn đứng yên.
    ///  2. applyNextTurn(): lấy một lượt rẽ từ hàng đợi, bỏ qua nếu là quay đầu (TODO 3).
    ///  3. eat(_:): ô ngay trước đầu rắn có mồi thì mồi đó tự áp hiệu ứng: cộng điểm, dài thêm
    ///     hoặc ngắn lại (TODO 1, Make 1).
    ///  4. move(_:grow:): rắn tiến một ô. Còn đốt phải dài thêm (pendingGrowth) thì giữ lại đuôi.
    ///  5. Va chạm: đầu ra ngoài lưới hoặc tự cắn mình (TODO 2) thì crash(), chuyển sang gameOver (TODO 4).
    ///     Không va chạm thì refillFood(): đặt lại mồi thường, bỏ mồi đặc biệt hết hạn, có khi thêm mồi mới.
    mutating func tick() {
        // 1.
        guard state == .running else { return }
        ticks += 1
        // 2.
        applyNextTurn()
        // 3.
        eat(snake.head + direction)
        // 4.
        let grow = pendingGrowth > 0
        if grow { pendingGrowth -= 1 }
        snake.move(direction, grow: grow)

        // 5.
        // TODO 2 ✓
        if isOutside(snake.head) || snake.hitsItself() { crash() } else { refillFood() }
    }

    /// Về lại màn chờ với rắn mới, điểm 0, mồi mới.
    mutating func restart() {
        snake = Game.startSnake(height: height)
        direction = .right
        pendingTurns.removeAll()
        score = 0
        ticks = 0
        pendingGrowth = 0
        staple = nil
        bonus = nil
        refillFood()
        state = .ready
    }

    private mutating func applyNextTurn() {
        guard !pendingTurns.isEmpty else { return }
        let newDirection = pendingTurns.removeFirst()
        // TODO 3 ✓
        if newDirection != direction.opposite { direction = newDirection }
    }

    /// Ăn mồi ở ô `next` nếu có. Mỗi loại mồi tự áp hiệu ứng của mình.
    private mutating func eat(_ next: Point) {
        // TODO 1 ✓ `guard let` giống `?: return` bên Kotlin.
        let food: any Food
        if let staple, staple.position == next {
            food = staple
            self.staple = nil
        } else if let bonus, bonus.position == next {
            food = bonus
            self.bonus = nil
        } else {
            return
        }
        food.apply(to: &self)
    }

    /// Đặt lại mồi thường nếu vừa bị ăn, bỏ mồi đặc biệt hết hạn, thỉnh thoảng thêm mồi đặc biệt mới.
    private mutating func refillFood() {
        if bonus?.isExpired(at: ticks) == true { bonus = nil }
        if staple == nil { staple = spawner.spawn(in: freeCells()).map(Apple.init(position:)) }
        if bonus == nil { bonus = spawner.spawnBonus(in: freeCells(), tick: ticks) }
    }

    private func isOutside(_ p: Point) -> Bool {
        !(0..<width).contains(p.x) || !(0..<height).contains(p.y)
    }

    private mutating func crash() {
        // TODO 4 ✓
        state = .gameOver(score: score)
    }

    private static func startSnake(height: Int) -> Snake {
        let y = height / 2
        return Snake(body: (0..<startLength).map { i in Point(x: startLength + 1 - i, y: y) })
    }

    private func freeCells() -> [Point] {
        let occupied = Set(snake.body).union(foods.map(\.position))
        return (0..<height).flatMap { y in (0..<width).map { x in Point(x: x, y: y) } }
            .filter { !occupied.contains($0) }
    }
}

/// Make 1: ván chơi cho mồi tác động lên mình qua protocol hẹp này. Chỉ Food nên gọi các hàm này.
extension Game: FoodEffects {
    mutating func addScore(_ points: Int) {
        score += points
    }

    mutating func grow(_ segments: Int) {
        pendingGrowth += segments
    }

    mutating func shrink(_ segments: Int) {
        snake.shrink(by: segments, minLength: GameRules.minSnakeLength)
    }
}
