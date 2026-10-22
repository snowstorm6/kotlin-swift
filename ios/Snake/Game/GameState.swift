/// Trạng thái ván chơi (State pattern). `switch` trên enum bắt buộc xử lý đủ mọi `case`.
///
/// ready → (bấm hướng) → running ⇄ paused, running → (va chạm) → gameOver → (chơi lại) → ready
enum GameState: Equatable {
    /// Mới mở hoặc vừa chơi lại, chờ người chơi chọn hướng đầu tiên.
    case ready
    case running
    case paused

    // TODO 4 (Enum): thêm case gameOver mang theo số điểm cuối cùng (associated value).
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
        // TODO 4: thêm case cho gameOver, ví dụ "Game Over · 7 điểm\nChạm để chơi lại".
        //  Thêm case ở trên xong, `switch` này sẽ báo lỗi cho tới khi bạn xử lý đủ mọi trường hợp.
        }
    }
}
