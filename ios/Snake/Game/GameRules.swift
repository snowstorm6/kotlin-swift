/// Các con số của luật chơi, gom một chỗ thay vì rải trong code.
/// `enum` không có case nào = namespace, không tạo instance được.
enum GameRules {
    /// Mồi đặc biệt: 1/bonusChance cơ hội xuất hiện mỗi tick, sống bonusLifetime tick.
    static let bonusChance = 25
    static let bonusLifetime = 40

    /// Tốc độ: bắt đầu 150 ms mỗi bước, mỗi điểm nhanh thêm 3 ms, nhanh nhất 60 ms.
    static let startStepMillis = 150
    static let minStepMillis = 60
    static let speedupPerPoint = 3

    /// Mỗi màn cần thêm chừng này điểm để sang màn sau.
    static let pointsPerLevel = 10

    /// Rắn ngắn nhất còn lại khi ăn quả teo.
    static let minSnakeLength = 2
}
