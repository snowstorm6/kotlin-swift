package dev.workshop.snake.game

/** Các con số của luật chơi, gom một chỗ thay vì rải trong code. */
object GameRules {
    /** Mồi đặc biệt: 1/BONUS_CHANCE cơ hội xuất hiện mỗi tick, sống BONUS_LIFETIME tick. */
    const val BONUS_CHANCE = 25
    const val BONUS_LIFETIME = 40

    /** Rắn ngắn nhất còn lại khi ăn quả teo. */
    const val MIN_SNAKE_LENGTH = 2
}
