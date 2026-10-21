package dev.workshop.snake.game

// Make 5 · Observer + delegation: Game báo sự kiện cho các GameListener mà không cần biết bên kia làm gì.
// Thống kê, ghi kỷ lục, log… mỗi thứ là một listener riêng, Game không phải sửa khi thêm bớt.

interface GameListener {
    fun onFoodEaten(food: Food) {}
    fun onLevelUp(level: Level) {}
    fun onGameOver(score: Int) {}
}

/** Đếm số liệu qua các ván chơi. */
class GameStats : GameListener {
    var foodsEaten = 0
        private set
    var gamesPlayed = 0
        private set

    override fun onFoodEaten(food: Food) {
        foodsEaten++
    }

    override fun onGameOver(score: Int) {
        gamesPlayed++
    }
}

/**
 * Thêm phần ghi lại sự kiện mới nhất lên trên GameStats.
 * `by stats` (class delegation): hàm nào của GameListener không override ở đây, như onGameOver,
 * sẽ tự chuyển sang `stats`. Bên Swift không có `by`, phải tự viết tay từng hàm chuyển tiếp.
 */
class LoggingStats(val stats: GameStats = GameStats()) : GameListener by stats {
    var lastEvent = ""
        private set

    override fun onFoodEaten(food: Food) {
        lastEvent = "Ăn ${food.name}"
        stats.onFoodEaten(food)
    }

    override fun onLevelUp(level: Level) {
        lastEvent = "Sang màn ${level.name}"
    }
}

/** Ghi kỷ lục mỗi khi thua. Nhờ Observer, Game không còn phải biết tới kỷ lục. */
class HighScoreRecorder(val highScore: HighScore) : GameListener {
    override fun onGameOver(score: Int) {
        highScore.submit(score)
    }
}
