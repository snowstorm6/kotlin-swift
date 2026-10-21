// Make 5 · Observer + delegation: Game báo sự kiện cho các GameListener mà không cần biết bên kia làm gì.
// Thống kê, ghi kỷ lục, log… mỗi thứ là một listener riêng, Game không phải sửa khi thêm bớt.

/// `AnyObject` = chỉ class mới conform được: listener là đối tượng có trạng thái riêng, dùng chung giữa các bản copy của Game.
protocol GameListener: AnyObject {
    func game(didEat food: any Food)
    func game(didReach level: Level)
    func gameDidEnd(score: Int)
}

/// Cài đặt mặc định không làm gì, để bên conform chỉ cần viết hàm mình quan tâm.
extension GameListener {
    func game(didEat food: any Food) {}
    func game(didReach level: Level) {}
    func gameDidEnd(score: Int) {}
}

/// Đếm số liệu qua các ván chơi.
final class GameStats: GameListener {
    private(set) var foodsEaten = 0
    private(set) var gamesPlayed = 0

    func game(didEat food: any Food) {
        foodsEaten += 1
    }

    func gameDidEnd(score: Int) {
        gamesPlayed += 1
    }
}

/// Thêm phần ghi lại sự kiện mới nhất lên trên GameStats.
/// Swift không có `by` như Kotlin: muốn bọc GameStats thì phải tự chuyển tiếp từng hàm, kể cả gameDidEnd.
final class LoggingStats: GameListener {
    let stats = GameStats()
    private(set) var lastEvent = ""

    func game(didEat food: any Food) {
        lastEvent = "Ăn \(food.name)"
        stats.game(didEat: food)
    }

    func game(didReach level: Level) {
        lastEvent = "Sang màn \(level.name)"
    }

    func gameDidEnd(score: Int) {
        stats.gameDidEnd(score: score)
    }
}

/// Ghi kỷ lục mỗi khi thua. Nhờ Observer, Game không còn phải biết tới kỷ lục.
final class HighScoreRecorder: GameListener {
    private(set) var highScore: HighScore

    init(highScore: HighScore) {
        self.highScore = highScore
    }

    func gameDidEnd(score: Int) {
        highScore.submit(score)
    }
}
