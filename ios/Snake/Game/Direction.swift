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

// TODO 3 ✓ Extension: thêm property cho enum có sẵn mà không sửa enum.
extension Direction {
    var opposite: Direction {
        switch self {
        case .up: .down
        case .down: .up
        case .left: .right
        case .right: .left
        }
    }
}
