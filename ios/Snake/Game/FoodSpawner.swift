/// Strategy: quyết định đặt mồi ở ô nào trong các ô còn trống; nil = không đặt.
/// Game chỉ biết protocol này, nên khi chơi dùng bản ngẫu nhiên, khi test dùng bản cố định.
protocol FoodSpawner {
    func spawn(in freeCells: [Point]) -> Point?

    /// Make 1: thỉnh thoảng sinh một mồi đặc biệt.
    func spawnBonus(in freeCells: [Point], tick: Int) -> (any Food)?
}

extension FoodSpawner {
    /// Mặc định không bao giờ có mồi đặc biệt, để test không bị ngẫu nhiên.
    func spawnBonus(in freeCells: [Point], tick: Int) -> (any Food)? { nil }
}

struct RandomFoodSpawner: FoodSpawner {
    func spawn(in freeCells: [Point]) -> Point? {
        freeCells.randomElement()
    }

    func spawnBonus(in freeCells: [Point], tick: Int) -> (any Food)? {
        guard Int.random(in: 0..<GameRules.bonusChance) == 0, let cell = freeCells.randomElement() else { return nil }
        let expiresAt = tick + GameRules.bonusLifetime
        return Bool.random()
            ? GoldenApple(position: cell, expiresAt: expiresAt)
            : ShrinkBerry(position: cell, expiresAt: expiresAt)
    }
}
