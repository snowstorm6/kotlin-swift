import Foundation

// Make 3 · Swift không có scope function. Cùng việc đó, Swift dùng `guard let` để thoát sớm,
// `throws` để báo lỗi cho bên gọi, và `try?` để biến lỗi thành nil.
// Bên Kotlin dùng `use { }`, `apply`, `?.let`.

/// Lưu kỷ lục vào một file text.
struct FileScoreStore: ScoreStore {
    let url: URL

    /// File chưa có hoặc nội dung hỏng thì coi như 0.
    func load() -> Int {
        guard let text = try? String(contentsOf: url, encoding: .utf8),
              let value = Int(text.trimmingCharacters(in: .whitespacesAndNewlines))
        else { return 0 }
        return value
    }

    func save(_ value: Int) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try String(value).write(to: url, atomically: true, encoding: .utf8)
    }
}
