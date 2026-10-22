/// Con rắn: mảng các đốt, đốt đầu tiên là đầu.
///
/// `struct` nên `move` là `mutating`: nó sửa chính giá trị này, và chỉ gọi được trên `var`.
struct Snake {
    private(set) var body: [Point]

    var head: Point { body[0] }

    /// Rắn đi một bước. `grow = true` thì giữ lại đuôi (vừa ăn mồi).
    mutating func move(_ direction: Direction, grow: Bool = false) {
        body.insert(head + direction, at: 0)
        if !grow { body.removeLast() }
    }

    // TODO 2 (Data model): trả về true khi đầu rắn trùng với một đốt thân (không tính chính cái đầu).
    func hitsItself() -> Bool {
        false
    }
}
