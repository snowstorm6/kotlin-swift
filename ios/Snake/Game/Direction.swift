/// Bốn hướng di chuyển. `dy` âm là đi lên vì trục y hướng xuống.
enum Direction {
    case up, down, left, right

    var dx: Int {
        switch self {
        case .left: -1
        case .right: 1
        case .up, .down: 0
        }
    }

    var dy: Int {
        switch self {
        case .up: -1
        case .down: 1
        case .left, .right: 0
        }
    }
}

// TODO 3 (Extension): viết `extension Direction` thêm computed property `opposite`,
//  trả về hướng ngược lại (up ↔ down, left ↔ right). Không sửa enum ở trên.
//  Sau đó dùng nó trong Game.applyNextTurn().
