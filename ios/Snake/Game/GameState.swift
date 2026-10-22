/// Trạng thái ván chơi (State pattern). `switch` trên enum bắt buộc xử lý đủ mọi `case`.
///
/// ready → (bấm hướng) → running ⇄ paused, running → (va chạm) → gameOver → (chơi lại) → ready
enum GameState: Equatable {
    /// Mới mở hoặc vừa chơi lại, chờ người chơi chọn hướng đầu tiên.
    case ready
    case running
    case paused

    // TODO 4 ✓ Một case mang dữ liệu đi kèm.
    case gameOver(score: Int)
}

extension GameState {
    /// Chữ hiện đè lên bàn chơi; nil = không hiện gì. Phần giao diện đọc property này.
    var overlayText: String? {
        switch self {
        case .ready:
            "Chọn hướng để bắt đầu"
        case .running:
            nil
        case .paused:
            "Tạm dừng\nChạm để chơi tiếp"
        case .gameOver(let score):
            "Game Over · \(score) điểm\nChạm để chơi lại"
        }
    }
}
