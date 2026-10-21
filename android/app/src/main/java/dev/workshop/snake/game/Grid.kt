package dev.workshop.snake.game

// Make 4 · Generic: một lưới 2 chiều chứa được bất kỳ kiểu gì (Tile, Boolean, Char…).
// `out T` = Grid chỉ trả T ra chứ không nhận T vào, nên Grid<Tile> dùng được ở chỗ cần Grid<Any>.
// Lúc chạy trên JVM, T bị xoá (type erasure): Grid<Tile> và Grid<Char> là cùng một class.

class Grid<out T>(val width: Int, val height: Int, private val cells: List<T>) {
    init {
        require(cells.size == width * height) { "Cần ${width * height} ô, có ${cells.size}" }
    }

    operator fun get(p: Point): T = cells[p.y * width + p.x]

    /** Toạ độ của mọi ô, đi từng hàng từ trên xuống. */
    fun points(): Sequence<Point> = sequence {
        for (y in 0 until height) for (x in 0 until width) yield(Point(x, y))
    }

    companion object {
        /** Đọc lưới từ text: mỗi dòng là một hàng, mỗi ký tự là một ô, `transform` đổi ký tự thành T. */
        fun <T> parse(text: String, transform: (Char) -> T): Grid<T> {
            val lines = text.trimIndent().lines().filter { it.isNotBlank() }
            val width = lines.first().length
            require(lines.all { it.length == width }) { "Các dòng phải dài bằng nhau" }
            return Grid(width, lines.size, lines.flatMap { line -> line.map(transform) })
        }
    }
}
