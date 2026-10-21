package dev.workshop.snake.game

import kotlin.properties.ReadWriteProperty
import kotlin.reflect.KProperty

// Make 2 · Property delegate: `var best by persisted(store)` giao việc đọc/ghi `best` cho một object khác.
// Đây là cách cộng đồng Android hay bọc SharedPreferences/DataStore. Bên Swift là property wrapper,
// giống `@AppStorage` của SwiftUI.

/** Nơi lưu một số nguyên. Make 3 cài bằng file; test và bản demo dùng bản trong bộ nhớ. */
interface ScoreStore {
    fun load(): Int
    fun save(value: Int)
}

class InMemoryScoreStore(private var value: Int = 0) : ScoreStore {
    override fun load(): Int = value

    override fun save(value: Int) {
        this.value = value
    }
}

/** Đọc từ store một lần, sau đó giữ trong bộ nhớ; mỗi lần gán thì ghi xuống store. */
private class Persisted(private val store: ScoreStore) : ReadWriteProperty<Any?, Int> {
    private var cached: Int? = null

    override fun getValue(thisRef: Any?, property: KProperty<*>): Int =
        cached ?: store.load().also { cached = it }

    override fun setValue(thisRef: Any?, property: KProperty<*>, value: Int) {
        cached = value
        store.save(value)
    }
}

private fun persisted(store: ScoreStore): ReadWriteProperty<Any?, Int> = Persisted(store)

/** Kỷ lục. Đứng ngoài Game: luật chơi không cần biết điểm được lưu ở đâu. */
class HighScore(store: ScoreStore) {
    var best: Int by persisted(store)
        private set

    /** Ghi nhận điểm một ván; trả về true nếu là kỷ lục mới. */
    fun submit(score: Int): Boolean {
        if (score <= best) return false
        best = score
        return true
    }
}
