/// Strategy: quyết định đặt mồi ở ô nào trong các ô còn trống; nil = không đặt.
/// Game chỉ biết protocol này, nên khi chơi dùng bản ngẫu nhiên, khi test dùng bản cố định.
protocol FoodSpawner {
    func spawn(in freeCells: [Point]) -> Point?
}

struct RandomFoodSpawner: FoodSpawner {
    func spawn(in freeCells: [Point]) -> Point? {
        freeCells.randomElement()
    }
}
