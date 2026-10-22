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

    // TODO 4 (Sealed): thêm trạng thái GameOver mang theo số điểm cuối cùng.
}

/** Chữ hiện đè lên bàn chơi; null = không hiện gì. Phần giao diện đọc hàm này. */
fun GameState.overlayText(): String? = when (this) {
    GameState.Ready -> "Chọn hướng để bắt đầu"
    GameState.Running -> null
    GameState.Paused -> "Tạm dừng\nChạm để chơi tiếp"
    // TODO 4: thêm nhánh cho GameOver, ví dụ "Game Over · 7 điểm\nChạm để chơi lại".
    //  Thêm GameOver ở trên xong, `when` này sẽ báo lỗi cho tới khi bạn xử lý đủ mọi trường hợp.
}
