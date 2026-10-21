// Make 4 · Generic: một lưới 2 chiều chứa được bất kỳ kiểu gì (Tile, Bool, Character…).
// Khác Kotlin: Swift giữ nguyên Element lúc chạy (không bị xoá như trên JVM), và trình biên dịch
// có thể sinh bản riêng cho từng Element (specialization).

struct Grid<Element> {
    let width: Int
    let height: Int
    private let cells: [Element]

    init(width: Int, height: Int, cells: [Element]) {
        precondition(cells.count == width * height, "Cần \(width * height) ô, có \(cells.count)")
        self.width = width
        self.height = height
        self.cells = cells
    }

    subscript(p: Point) -> Element { cells[p.y * width + p.x] }

    /// Toạ độ của mọi ô, đi từng hàng từ trên xuống.
    /// `some Sequence<Point>` = trả về một kiểu Sequence cụ thể mà bên gọi không cần biết tên.
    var points: some Sequence<Point> {
        let width = width
        return (0..<height).lazy.flatMap { y in (0..<width).lazy.map { x in Point(x: x, y: y) } }
    }

    /// Đọc lưới từ text: mỗi dòng là một hàng, mỗi ký tự là một ô, `transform` đổi ký tự thành Element.
    static func parse(_ text: String, transform: (Character) -> Element) -> Grid<Element> {
        let lines = text.split(separator: "\n").map { $0.trimmingPrefix(while: \.isWhitespace) }.filter { !$0.isEmpty }
        let width = lines[0].count
        precondition(lines.allSatisfy { $0.count == width }, "Các dòng phải dài bằng nhau")
        return Grid(width: width, height: lines.count, cells: lines.flatMap { $0.map(transform) })
    }
}

extension Grid: Sendable where Element: Sendable {}
