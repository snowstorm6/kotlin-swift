/// Các con số của luật chơi, gom một chỗ thay vì rải trong code.
/// `enum` không có case nào = namespace, không tạo instance được.
enum GameRules {
    /// Mồi đặc biệt: 1/bonusChance cơ hội xuất hiện mỗi tick, sống bonusLifetime tick.
    static let bonusChance = 25
    static let bonusLifetime = 40

    /// Rắn ngắn nhất còn lại khi ăn quả teo.
    static let minSnakeLength = 2
}
