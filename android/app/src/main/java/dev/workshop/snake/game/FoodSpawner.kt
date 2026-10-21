package dev.workshop.snake.game

import kotlin.random.Random

/**
 * Strategy: quyết định đặt mồi ở ô nào trong các ô còn trống; null = không đặt.
 * Game chỉ biết interface này, nên khi chơi dùng bản ngẫu nhiên, khi test dùng bản cố định.
 */
fun interface FoodSpawner {
    fun spawn(freeCells: List<Point>): Point?

    /** Make 1: thỉnh thoảng sinh một mồi đặc biệt. Mặc định không bao giờ, để test không bị ngẫu nhiên. */
    fun spawnBonus(freeCells: List<Point>, tick: Int): Food? = null
}

class RandomFoodSpawner(private val random: Random = Random.Default) : FoodSpawner {
    override fun spawn(freeCells: List<Point>): Point? = freeCells.randomOrNull(random)

    override fun spawnBonus(freeCells: List<Point>, tick: Int): Food? {
        if (random.nextInt(GameRules.BONUS_CHANCE) != 0) return null
        val cell = freeCells.randomOrNull(random) ?: return null
        val expiresAt = tick + GameRules.BONUS_LIFETIME
        return if (random.nextBoolean()) GoldenApple(cell, expiresAt) else ShrinkBerry(cell, expiresAt)
    }
}
