package dev.workshop.snake.game

// Make 1 · Interface: nhiều loại mồi. Mỗi loại tự quyết định ăn vào thì ra sao (polymorphism),
// Game không cần `if (food is ...)`. Thêm loại mới chỉ cần một class mới implement Food.

/** Kiểu hiển thị của mồi. Logic không biết gì về Color của Compose hay SwiftUI, giao diện tự chọn màu. */
enum class FoodLook { RED, GOLD, PURPLE }

/** Những gì một miếng mồi được phép làm với ván chơi khi bị ăn. */
interface FoodEffects {
    fun addScore(points: Int)
    fun grow(segments: Int)
    fun shrink(segments: Int)
}

interface Food {
    val name: String
    val position: Point
    val look: FoodLook

    /** Tick mà mồi biến mất; null = không bao giờ biến mất. */
    val expiresAt: Int? get() = null

    /** Default method trong interface. Bên Swift làm bằng protocol extension. */
    fun isExpired(tick: Int): Boolean = expiresAt?.let { tick >= it } ?: false

    fun applyTo(effects: FoodEffects)
}

data class Apple(override val position: Point) : Food {
    override val name = "Táo"
    override val look = FoodLook.RED

    override fun applyTo(effects: FoodEffects) {
        effects.addScore(1)
        effects.grow(1)
    }
}

data class GoldenApple(override val position: Point, override val expiresAt: Int) : Food {
    override val name = "Táo vàng"
    override val look = FoodLook.GOLD

    override fun applyTo(effects: FoodEffects) {
        effects.addScore(5)
        effects.grow(3)
    }
}

data class ShrinkBerry(override val position: Point, override val expiresAt: Int) : Food {
    override val name = "Quả teo"
    override val look = FoodLook.PURPLE

    override fun applyTo(effects: FoodEffects) {
        effects.addScore(2)
        effects.shrink(2)
    }
}
