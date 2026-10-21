package dev.workshop.snake.game

import java.io.File

// Make 3 · Scope function: `use` tự đóng file kể cả khi lỗi, `apply` cấu hình object rồi trả về chính nó,
// `?.let` chỉ chạy khi khác null. Bên Swift dùng `guard let`, `throws` / `try?`.

/** Lưu kỷ lục vào một file text. */
class FileScoreStore(private val file: File) : ScoreStore {
    /** File chưa có hoặc nội dung hỏng thì coi như 0. */
    override fun load(): Int = runCatching {
        file.bufferedReader().use { reader -> reader.readLine()?.trim()?.toIntOrNull() }
    }.getOrNull() ?: 0

    override fun save(value: Int) {
        file.apply { parentFile?.mkdirs() }.writeText(value.toString())
    }
}
