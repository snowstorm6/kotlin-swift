import Foundation
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
        #expect(game.foods.isEmpty)
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

@Suite("Make 1 · Protocol")
struct Make1Tests {
    /// Không có mồi thường; mồi đặc biệt `bonus` xuất hiện ngay từ đầu ván.
    private struct BonusOnly: FoodSpawner {
        let bonus: any Food

        func spawn(in freeCells: [Point]) -> Point? { nil }

        func spawnBonus(in freeCells: [Point], tick: Int) -> (any Food)? {
            tick == 0 ? bonus : nil
        }
    }

    private func run(_ bonus: any Food, ticks: Int) -> Game {
        var game = Game(spawner: BonusOnly(bonus: bonus))
        game.turn(.right)
        for _ in 0..<ticks { game.tick() }
        return game
    }

    @Test("Ăn táo vàng được 5 điểm và dài thêm 3 đốt")
    func goldenApple() {
        let game = run(GoldenApple(position: Point(x: 5, y: 10), expiresAt: 99), ticks: 4)
        #expect(game.score == 5)
        #expect(game.snake.body.count == 6)
    }

    @Test("Ăn quả teo được 2 điểm và ngắn đi nhưng còn ít nhất 2 đốt")
    func shrinkBerry() {
        let game = run(ShrinkBerry(position: Point(x: 5, y: 10), expiresAt: 99), ticks: 2)
        #expect(game.score == 2)
        #expect(game.snake.body.count == GameRules.minSnakeLength)
    }

    @Test("Mồi đặc biệt tự biến mất khi hết hạn")
    func bonusExpires() {
        #expect(run(GoldenApple(position: Point(x: 0, y: 0), expiresAt: 3), ticks: 3).foods.isEmpty)
    }
}

@Suite("Make 2 · Property wrapper")
struct Make2Tests {
    @Test("Kỷ lục chỉ tăng và được ghi xuống store")
    func onlyIncreases() {
        let store = InMemoryScoreStore()
        var highScore = HighScore(store: store)
        let first = highScore.submit(7)
        let second = highScore.submit(3)
        #expect(first)
        #expect(!second)
        #expect(highScore.best == 7)
        #expect(store.load() == 7)
    }

    @Test("Kỷ lục đọc lại từ store khi mở game")
    func loadsFromStore() {
        #expect(HighScore(store: InMemoryScoreStore(12)).best == 12)
    }

    @Test("Ván mới bắt đầu ở tốc độ chậm nhất")
    func startSpeed() {
        #expect(Game(spawner: FixedSpawner(at: nil)).stepMillis == GameRules.startStepMillis)
    }
}

@Suite("Make 3 · guard let, throws")
struct Make3Tests {
    private func tempDirectory() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    }

    @Test("Ghi rồi đọc lại đúng giá trị, tự tạo thư mục")
    func roundTrip() throws {
        let url = tempDirectory().appending(path: "sub/highscore.txt")
        try FileScoreStore(url: url).save(42)
        #expect(FileScoreStore(url: url).load() == 42)
    }

    @Test("File chưa có hoặc nội dung hỏng thì coi như 0")
    func missingOrBroken() throws {
        let dir = tempDirectory()
        #expect(FileScoreStore(url: dir.appending(path: "missing.txt")).load() == 0)
        let broken = dir.appending(path: "broken.txt")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try "không phải số".write(to: broken, atomically: true, encoding: .utf8)
        #expect(FileScoreStore(url: broken).load() == 0)
    }
}

@Suite("Make 4 · Generic")
struct Make4Tests {
    /// Táo lần lượt hiện ở các ô cho trước.
    private final class PathSpawner: FoodSpawner {
        private var path: [Point]

        init(_ path: [Point]) {
            self.path = path
        }

        func spawn(in freeCells: [Point]) -> Point? {
            guard !path.isEmpty else { return nil }
            let next = path.removeFirst()
            return freeCells.contains(next) ? next : nil
        }
    }

    @Test("Đọc màn chơi từ text")
    func parseLevel() {
        let level = Level(name: "Thử", text: "#..\n...\n..#")
        #expect(level.tiles.width == 3)
        #expect(level.tiles.height == 3)
        #expect(level.walls == [Point(x: 0, y: 0), Point(x: 2, y: 2)])
    }

    @Test("Đủ điểm thì sang màn sau, rắn về chỗ xuất phát")
    func levelUp() {
        var game = Game(spawner: PathSpawner((5...14).map { Point(x: $0, y: 10) }))
        game.turn(.right)
        for _ in 0..<10 { game.tick() }
        #expect(game.score == 10)
        #expect(game.levelNumber == 2)
        #expect(game.snake.head == startHead)
    }

    @Test("Đâm tường trong màn thì thua")
    func hitsWall() {
        let rows = (0..<20).map { $0 == 10 ? "......#............." : String(repeating: ".", count: 20) }
        var game = Game(spawner: FixedSpawner(at: nil), levels: [Level(name: "Tường", text: rows.joined(separator: "\n"))])
        game.turn(.right)
        game.tick()
        game.tick()
        #expect(game.state == .gameOver(score: 0))
    }
}

@Suite("Make 5 · Observer, delegation")
struct Make5Tests {
    @Test("Listener nhận đủ sự kiện, LoggingStats chuyển tiếp gameDidEnd sang stats")
    func listenersReceiveEvents() {
        let stats = LoggingStats()
        let recorder = HighScoreRecorder(highScore: HighScore(store: InMemoryScoreStore()))
        var game = Game(spawner: FixedSpawner(at: Point(x: 6, y: 10)), listeners: [stats, recorder])
        game.turn(.right)
        for _ in 0..<16 { game.tick() }
        #expect(stats.stats.foodsEaten == 1)
        #expect(stats.stats.gamesPlayed == 1)
        #expect(stats.lastEvent == "Ăn Táo")
        #expect(recorder.highScore.best == 1)
        #expect(game.state == .gameOver(score: 1))
    }
}
