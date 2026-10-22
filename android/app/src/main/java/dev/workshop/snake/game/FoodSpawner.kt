package dev.workshop.snake.game

import kotlin.random.Random

/**
 * Strategy: quyết định đặt mồi ở ô nào trong các ô còn trống; null = không đặt.
 * Game chỉ biết interface này, nên khi chơi dùng bản ngẫu nhiên, khi test dùng bản cố định.
 */
fun interface FoodSpawner {
    fun spawn(freeCells: List<Point>): Point?
}

class RandomFoodSpawner(private val random: Random = Random.Default) : FoodSpawner {
    override fun spawn(freeCells: List<Point>): Point? = freeCells.randomOrNull(random)
}
