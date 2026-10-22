package dev.workshop.snake.terminal

// Bản chạy trong Terminal. File này là phần "giao diện": đọc phím, gọi Game, vẽ ra màn hình.
// Mọi luật chơi nằm trong package `game`; file này không quyết định rắn đi đâu hay ăn gì.
//
// Chương trình chạy theo 3 phần:
//
//  A. Chuẩn bị: bật raw mode cho Terminal, ẩn con trỏ, chạy một thread riêng chỉ để đọc phím.
//
//  B. Game loop, lặp mãi, mỗi vòng là một bước của game:
//       1. Xử lý phím: lấy hết phím vừa bấm trong hàng đợi `keys`.
//            phím hướng  → game.turn(hướng)       Game xếp lượt rẽ vào hàng đợi của nó (Command)
//            Space       → game.primaryAction()   tạm dừng / chơi tiếp / chơi lại (State)
//            q, Esc      → thoát
//       2. game.tick()   luật chơi chạy đúng một bước (các bước nhỏ xem ở Game.tick)
//       3. render(game)  đọc snake, food, score, state rồi vẽ lại cả màn hình
//       4. Ngủ TICK_MS   chờ tới bước sau. Số này quyết định rắn chạy nhanh hay chậm.
//
//  C. Kết thúc (thoát bằng q / Esc / Ctrl+C): trả Terminal về như cũ, hiện lại con trỏ.
//
// Vì sao cần thread đọc phím riêng: System.in.read() đứng chờ tới khi có phím. Nếu đọc ngay trong
// game loop, rắn sẽ đứng yên cho tới khi người chơi bấm. Thread riêng ngồi chờ phím và bỏ vào hàng
// đợi `keys`, còn game loop chỉ lấy những gì đã có rồi chạy tiếp. Bản Swift không cần thread vì đặt
// được read() ở chế độ không chờ.

import dev.workshop.snake.game.Direction
import dev.workshop.snake.game.Game
import dev.workshop.snake.game.Point
import dev.workshop.snake.game.overlayText
import java.util.concurrent.ConcurrentLinkedQueue
import kotlin.concurrent.thread

/** Mili giây giữa hai bước của game. */
private const val TICK_MS = 150L

/** Ký tự ESC mở đầu mọi mã điều khiển Terminal (ANSI escape code): đổi màu, xoá màn hình, ẩn con trỏ… */
private const val ESC = "\u001b"

fun main() {
    // ── A. Chuẩn bị ──────────────────────────────────────────────────────────────
    val game = Game()

    // Hàng đợi phím dùng chung giữa thread đọc phím và game loop. ConcurrentLinkedQueue an toàn khi
    // hai thread cùng đọc/ghi, không cần tự khoá.
    val keys = ConcurrentLinkedQueue<Int>()

    rawMode(true)
    print("$ESC[?25l$ESC[2J") // ẩn con trỏ, xoá màn hình
    // Shutdown hook chạy cả khi thoát bằng Ctrl+C, nên Terminal luôn được trả về như cũ.
    Runtime.getRuntime().addShutdownHook(Thread { print("$ESC[?25h\r\n"); rawMode(false) })

    // Thread đọc phím: đứng chờ từng byte và bỏ vào hàng đợi. Daemon = tự tắt khi main() kết thúc.
    thread(isDaemon = true) { while (true) keys.add(System.`in`.read()) }

    // ── B. Game loop ─────────────────────────────────────────────────────────────
    while (true) {
        // 1. Xử lý mọi phím đã bấm kể từ vòng trước. poll() trả về null khi hàng đợi rỗng.
        while (true) {
            val k = keys.poll() ?: break
            when (k) {
                'q'.code -> return
                // Esc để thoát. Phím mũi tên cũng gửi ESC rồi '[' và một chữ, nên chờ chút xem có '[' theo sau không.
                27 -> {
                    if (keys.isEmpty()) Thread.sleep(30)
                    if (keys.peek() != '['.code) return
                    keys.poll()
                }
                // Phím mũi tên gửi 3 byte ESC [ A/B/C/D. ESC và '[' đã bỏ qua ở trên, còn lại chữ cái.
                'w'.code, 'A'.code -> game.turn(Direction.UP)
                's'.code, 'B'.code -> game.turn(Direction.DOWN)
                'd'.code, 'C'.code -> game.turn(Direction.RIGHT)
                'a'.code, 'D'.code -> game.turn(Direction.LEFT)
                ' '.code -> game.primaryAction()
            }
        }
        // 2. Luật chơi chạy một bước.
        game.tick()
        // 3. Vẽ lại.
        render(game)
        // 4. Chờ tới bước sau.
        Thread.sleep(TICK_MS)
    }
    // C. Kết thúc: `return` ở trên thoát main(), shutdown hook trả Terminal về như cũ.
}

/**
 * Vẽ cả màn hình thành một chuỗi rồi in một lần. `ESC[H` đưa con trỏ về góc trên trái để vẽ đè lên
 * khung cũ thay vì in tiếp xuống dưới, nên màn hình không bị nhấp nháy hay trôi.
 * Trong raw mode, xuống dòng phải viết đủ `\r\n`.
 */
private fun render(game: Game) {
    val sb = StringBuilder("$ESC[H")
    sb.append("Điểm: ${game.score}   (WASD / mũi tên, Space tạm dừng, q / Esc thoát)\r\n")
    sb.append("╔").append("══".repeat(game.width)).append("╗\r\n")
    for (y in 0 until game.height) {
        sb.append("║")
        for (x in 0 until game.width) {
            val p = Point(x, y)
            // Mỗi ô rộng 2 ký tự cho vuông. ESC[92m là chữ xanh lá sáng, ESC[0m trả về màu mặc định.
            sb.append(
                when {
                    p == game.snake.head -> "$ESC[92m██$ESC[0m"
                    p in game.snake.body -> "$ESC[32m██$ESC[0m"
                    p == game.food -> "$ESC[91m●$ESC[0m "
                    else -> "  "
                },
            )
        }
        sb.append("║\r\n")
    }
    sb.append("╚").append("══".repeat(game.width)).append("╝\r\n")
    sb.append((game.state.overlayText()?.replace("\n", " · ")?.replace("Chạm", "Space") ?: "").padEnd(50)).append("\r\n")
    print(sb)
    System.out.flush()
}

/**
 * Terminal mặc định ở chế độ "cooked": gom cả dòng, chờ Enter mới gửi cho chương trình, và in phím ra
 * màn hình. `stty raw -echo` tắt hết những thứ đó để mỗi phím tới chương trình ngay lập tức.
 * `stty sane` trả lại như cũ. JVM không có API cho việc này nên gọi lệnh `stty` của hệ điều hành.
 */
private fun rawMode(on: Boolean) {
    val cmd = if (on) "stty raw -echo < /dev/tty" else "stty sane < /dev/tty"
    ProcessBuilder("sh", "-c", cmd).inheritIO().start().waitFor()
}
