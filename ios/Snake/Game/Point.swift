/// Một ô trên lưới. (0, 0) là góc trên bên trái.
///
/// `struct` là value type: gán sang biến khác là copy. `Hashable` (gồm cả `Equatable`) cho phép
/// so sánh `==`, dùng `contains` và cho vào `Set`; struct mà mọi thuộc tính đều Hashable thì Swift tự sinh.
struct Point: Hashable {
    let x: Int
    let y: Int

    /// Ô kế bên theo một hướng: `head + .up`.
    static func + (point: Point, direction: Direction) -> Point {
        Point(x: point.x + direction.dx, y: point.y + direction.dy)
    }
}
