// Make 2 · Property wrapper: `@Persisted var best` giao việc đọc/ghi `best` cho một struct khác.
// Giống `@AppStorage` của SwiftUI. Bên Kotlin là property delegate `by persisted(store)`.

/// Nơi lưu một số nguyên. Make 3 cài bằng file; test và bản demo dùng bản trong bộ nhớ.
/// `throws`: lưu có thể lỗi, và Swift bắt bên gọi phải xử lý. Kotlin không có checked exception.
protocol ScoreStore {
    func load() -> Int
    func save(_ value: Int) throws
}

final class InMemoryScoreStore: ScoreStore {
    private var value: Int

    init(_ value: Int = 0) {
        self.value = value
    }

    func load() -> Int { value }

    func save(_ value: Int) {
        self.value = value
    }
}

/// Đọc từ store một lần, sau đó giữ trong bộ nhớ; mỗi lần gán thì ghi xuống store.
@propertyWrapper
struct Persisted {
    private let store: any ScoreStore
    private var value: Int

    init(store: any ScoreStore) {
        self.store = store
        value = store.load()
    }

    var wrappedValue: Int {
        get { value }
        set {
            value = newValue
            try? store.save(newValue)
        }
    }
}

/// Kỷ lục. Đứng ngoài Game: luật chơi không cần biết điểm được lưu ở đâu.
struct HighScore {
    @Persisted private(set) var best: Int

    init(store: any ScoreStore) {
        _best = Persisted(store: store)
    }

    /// Ghi nhận điểm một ván; trả về true nếu là kỷ lục mới.
    @discardableResult
    mutating func submit(_ score: Int) -> Bool {
        guard score > best else { return false }
        best = score
        return true
    }
}
