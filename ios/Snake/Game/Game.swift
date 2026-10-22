/// Toàn bộ luật chơi. Game không biết gì về màn hình, bàn phím hay thời gian thực:
/// nó chỉ nhận lệnh và chạy từng bước khi được gọi. Phần giao diện (app hoặc Terminal) lo phần còn lại.
///
/// Giao diện nói chuyện với Game qua 3 cửa:
///  - `turn(_:)`         khi người chơi bấm phím hướng: chỉ xếp lệnh vào hàng đợi, chưa đổi gì ngay.
///  - `primaryAction()`  khi bấm Space / chạm bàn chơi: tạm dừng, chơi tiếp, hoặc chơi lại.
///  - `tick()`           gọi đều đặn từ game loop: luật chơi chạy đúng một bước (xem các bước ở tick()).
/// Sau mỗi tick, giao diện đọc `snake`, `food`, `score`, `state` để vẽ lại.
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

    /// Mồi hiện tại. nil khi không còn ô trống nào để đặt mồi.
    private(set) var food: Point?
    private(set) var score = 0
    private(set) var state: GameState = .ready

    /// Command pattern: phím bấm được xếp hàng, mỗi tick xử lý đúng một phím.
    /// Nhờ vậy bấm nhanh ↑ rồi ← trong cùng một tick vẫn ra đúng hai lượt rẽ.
    private var pendingTurns: [Direction] = []

    init(width: Int = 20, height: Int = 20, spawner: any FoodSpawner = RandomFoodSpawner()) {
        self.width = width
        self.height = height
        self.spawner = spawner
        snake = Game.startSnake(height: height)
        food = spawnFood()
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
        // TODO 4: thêm gameOver xong, `switch` này cũng báo thiếu case. Thua rồi thì restart().
        }
    }

    /// Một bước của game. Game loop gọi hàm này đều đặn, mỗi lần rắn đi đúng một ô:
    ///  1. Chỉ chạy khi đang running. ready, paused, gameOver thì rắn đứng yên.
    ///  2. applyNextTurn(): lấy một lượt rẽ từ hàng đợi, bỏ qua nếu là quay đầu (TODO 3).
    ///  3. tryEat(_:): ô ngay trước đầu rắn có mồi không; có thì cộng điểm, đặt mồi mới (TODO 1).
    ///  4. move(_:grow:): rắn tiến một ô. Vừa ăn thì giữ lại đuôi, nên dài thêm một đốt.
    ///  5. Va chạm: đầu ra ngoài lưới hoặc tự cắn mình (TODO 2) thì crash(), chuyển sang gameOver (TODO 4).
    mutating func tick() {
        // 1.
        guard state == .running else { return }
        // 2.
        applyNextTurn()
        // 3.
        let next = snake.head + direction
        let grow = tryEat(next)
        // 4.
        snake.move(direction, grow: grow)

        // 5.
        // TODO 2 (Data model): nếu đầu rắn ra ngoài lưới hoặc tự cắn mình (Snake.hitsItself)
        //  thì gọi crash(). Hiện giờ rắn đi xuyên ra ngoài màn hình.
    }

    /// Về lại màn chờ với rắn mới, điểm 0, mồi mới.
    mutating func restart() {
        snake = Game.startSnake(height: height)
        direction = .right
        pendingTurns.removeAll()
        score = 0
        food = spawnFood()
        state = .ready
    }

    private mutating func applyNextTurn() {
        guard !pendingTurns.isEmpty else { return }
        let newDirection = pendingTurns.removeFirst()
        // TODO 3: rắn đang đi sang phải mà rẽ trái thì nó tự cắn cổ mình.
        //  Bỏ qua lượt rẽ nếu newDirection là hướng ngược với direction (dùng extension ở Direction.swift).
        direction = newDirection
    }

    /// Trả về true nếu ô `next` đang có mồi: cộng điểm, đặt mồi mới.
    private mutating func tryEat(_ next: Point) -> Bool {
        // TODO 1 ✓ `guard let` giống `?: return` bên Kotlin.
        guard let food, food == next else { return false }
        score += 1
        self.food = spawnFood()
        return true
    }

    private mutating func crash() {
        // TODO 4 (Enum): thay vì về lại màn chờ ngay, chuyển state sang .gameOver kèm số điểm.
        restart()
    }

    private static func startSnake(height: Int) -> Snake {
        let y = height / 2
        return Snake(body: (0..<startLength).map { i in Point(x: startLength + 1 - i, y: y) })
    }

    private func spawnFood() -> Point? {
        let occupied = Set(snake.body)
        let free = (0..<height).flatMap { y in (0..<width).map { x in Point(x: x, y: y) } }
            .filter { !occupied.contains($0) }
        return spawner.spawn(in: free)
    }
}
