package dev.workshop.snake.game

/** Các con số của luật chơi, gom một chỗ thay vì rải trong code. */
object GameRules {
    /** Mồi đặc biệt: 1/BONUS_CHANCE cơ hội xuất hiện mỗi tick, sống BONUS_LIFETIME tick. */
    const val BONUS_CHANCE = 25
    const val BONUS_LIFETIME = 40

    /** Tốc độ: bắt đầu 150 ms mỗi bước, mỗi điểm nhanh thêm 3 ms, nhanh nhất 60 ms. */
    const val START_STEP_MILLIS = 150L
    const val MIN_STEP_MILLIS = 60L
    const val SPEEDUP_PER_POINT = 3L

    /** Mỗi màn cần thêm chừng này điểm để sang màn sau. */
    const val POINTS_PER_LEVEL = 10

    /** Rắn ngắn nhất còn lại khi ăn quả teo. */
    const val MIN_SNAKE_LENGTH = 2
}
