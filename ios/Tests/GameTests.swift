import Testing
@testable import snake

// Chạy: cd ios && swift test
// Ở nhánh main các test TODO sẽ đỏ; làm xong TODO nào thì test của TODO đó xanh.

/// Đầu rắn xuất phát ở (4, 10), đi sang phải, bàn 20×20.
private let startHead = Point(x: 4, y: 10)

/// Spawner cố định: luôn đặt mồi ở `at` nếu ô đó còn trống.
private struct FixedSpawner: FoodSpawner {
    let at: Point?

    func spawn(in freeCells: [Point]) -> Point? {
        guard let at, freeCells.contains(at) else { return nil }
        return at
    }
}

/// Bắt đầu ván và cho rắn đi thẳng sang phải `ticks` bước.
private func startedGame(food: Point? = nil, ticks: Int) -> Game {
    var game = Game(spawner: FixedSpawner(at: food))
    game.turn(.right)
    for _ in 0..<ticks { game.tick() }
    return game
}

@Suite("Game")
struct GameTests {
    @Test("Chưa chọn hướng thì rắn đứng yên")
    func readyDoesNotMove() {
        var game = Game(spawner: FixedSpawner(at: nil))
        for _ in 0..<3 { game.tick() }
        #expect(game.snake.head == startHead)
    }

    @Test("Tạm dừng thì rắn đứng yên, chơi tiếp thì đi")
    func pauseAndResume() {
        var game = startedGame(ticks: 1)
        game.pauseOrResume()
        game.tick()
        #expect(game.snake.head == Point(x: 5, y: 10))
        game.pauseOrResume()
        game.tick()
        #expect(game.snake.head == Point(x: 6, y: 10))
    }

    @Test("Bấm nhanh hai phím trong một tick vẫn rẽ đủ hai lần")
    func queuedTurns() {
        var game = Game(spawner: FixedSpawner(at: nil))
        game.turn(.up)
        game.turn(.left)
        game.tick()
        game.tick()
        #expect(game.snake.head == Point(x: 3, y: 9))
        #expect(game.state == .running)
    }
}

@Suite("TODO 1 · Null safety")
struct Todo1Tests {
    @Test("Ăn mồi thì được 1 điểm và rắn dài thêm 1 đốt")
    func eatsFood() {
        let game = startedGame(food: Point(x: 6, y: 10), ticks: 2)
        #expect(game.score == 1)
        #expect(game.snake.body.count == 4)
    }

    @Test("Không còn chỗ đặt mồi thì vẫn chơi bình thường")
    func noFood() {
        let game = startedGame(ticks: 3)
        #expect(game.food == nil)
        #expect(game.score == 0)
        #expect(game.snake.body.count == 3)
    }
}

@Suite("TODO 2 · Data model")
struct Todo2Tests {
    @Test("Đầu rắn trùng một đốt thân là tự cắn")
    func coiledSnakeHitsItself() {
        let coiled = Snake(body: [
            Point(x: 1, y: 1), Point(x: 2, y: 1), Point(x: 2, y: 2), Point(x: 1, y: 2), Point(x: 1, y: 1),
        ])
        #expect(coiled.hitsItself())
    }

    @Test("Rắn thẳng thì không tự cắn")
    func straightSnake() {
        #expect(!Snake(body: [Point(x: 3, y: 1), Point(x: 2, y: 1), Point(x: 1, y: 1)]).hitsItself())
    }

    @Test("Đâm tường thì rắn không còn chạy")
    func wallStopsTheRun() {
        #expect(startedGame(ticks: 16).state != .running)
    }
}

@Suite("TODO 3 · Extension")
struct Todo3Tests {
    @Test("Rẽ ngược chiều đang đi thì bị bỏ qua")
    func ignoresUTurn() {
        var game = startedGame(ticks: 1)
        game.turn(.left)
        game.tick()
        #expect(game.direction == .right)
        #expect(game.snake.head == Point(x: 6, y: 10))
    }
}

@Suite("TODO 4 · Enum")
struct Todo4Tests {
    @Test("Thua thì hiện Game Over kèm số điểm")
    func gameOverShowsScore() {
        let text = startedGame(food: Point(x: 6, y: 10), ticks: 16).state.overlayText ?? ""
        #expect(text.hasPrefix("Game Over · 1 điểm"), "Chữ hiện ra là: \(text)")
    }

    @Test("Đã thua thì tick không làm gì nữa")
    func frozenAfterGameOver() {
        var game = startedGame(ticks: 16)
        let headAfterCrash = game.snake.head
        game.tick()
        #expect(game.snake.head == headAfterCrash)
        #expect((game.state.overlayText ?? "").hasPrefix("Game Over"))
    }
}
