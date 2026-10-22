package dev.workshop.snake.game

/**
 * Trạng thái ván chơi (State pattern). `sealed` = trình biên dịch biết hết mọi trạng thái,
 * nên mọi `when` trên GameState đều phải xử lý đủ.
 *
 * Ready → (bấm hướng) → Running ⇄ Paused, Running → (va chạm) → GameOver → (chơi lại) → Ready
 */
sealed interface GameState {
    /** Mới mở hoặc vừa chơi lại, chờ người chơi chọn hướng đầu tiên. */
    data object Ready : GameState
    data object Running : GameState
    data object Paused : GameState

    // TODO 4 ✓ Một trạng thái mang dữ liệu đi kèm.
    data class GameOver(val score: Int) : GameState
}

/** Chữ hiện đè lên bàn chơi; null = không hiện gì. Phần giao diện đọc hàm này. */
fun GameState.overlayText(): String? = when (this) {
    GameState.Ready -> "Chọn hướng để bắt đầu"
    GameState.Running -> null
    GameState.Paused -> "Tạm dừng\nChạm để chơi tiếp"
    is GameState.GameOver -> "Game Over · $score điểm\nChạm để chơi lại"
}
