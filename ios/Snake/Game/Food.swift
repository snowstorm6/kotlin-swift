// Make 1 · Protocol: nhiều loại mồi. Mỗi loại tự quyết định ăn vào thì ra sao (polymorphism),
// Game không cần `if food is ...`. Thêm loại mới chỉ cần một struct mới conform Food.

/// Kiểu hiển thị của mồi. Logic không biết gì về Color của SwiftUI hay Compose, giao diện tự chọn màu.
enum FoodLook { case red, gold, purple }

/// Những gì một miếng mồi được phép làm với ván chơi khi bị ăn. Game conform protocol này.
protocol FoodEffects {
    mutating func addScore(_ points: Int)
    mutating func grow(_ segments: Int)
    mutating func shrink(_ segments: Int)
}

protocol Food {
    var name: String { get }
    var position: Point { get }
    var look: FoodLook { get }

    /// Tick mà mồi biến mất; nil = không bao giờ biến mất.
    var expiresAt: Int? { get }

    /// Generic với `inout`: mồi sửa trực tiếp ván chơi (một struct) qua protocol hẹp FoodEffects.
    func apply<Effects: FoodEffects>(to effects: inout Effects)
}

/// Protocol extension cho mọi Food một cài đặt mặc định. Bên Kotlin làm bằng default method trong interface.
extension Food {
    var expiresAt: Int? { nil }

    func isExpired(at tick: Int) -> Bool {
        guard let expiresAt else { return false }
        return tick >= expiresAt
    }
}

struct Apple: Food {
    let position: Point
    let name = "Táo"
    let look = FoodLook.red

    func apply<Effects: FoodEffects>(to effects: inout Effects) {
        effects.addScore(1)
        effects.grow(1)
    }
}

struct GoldenApple: Food {
    let position: Point
    let expiresAt: Int?
    let name = "Táo vàng"
    let look = FoodLook.gold

    func apply<Effects: FoodEffects>(to effects: inout Effects) {
        effects.addScore(5)
        effects.grow(3)
    }
}

struct ShrinkBerry: Food {
    let position: Point
    let expiresAt: Int?
    let name = "Quả teo"
    let look = FoodLook.purple

    func apply<Effects: FoodEffects>(to effects: inout Effects) {
        effects.addScore(2)
        effects.shrink(2)
    }
}
