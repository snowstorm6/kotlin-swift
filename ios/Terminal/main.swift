// Bản chạy trong Terminal. File này là phần "giao diện": đọc phím, gọi Game, vẽ ra màn hình.
// Mọi luật chơi nằm trong thư mục Snake/Game; file này không quyết định rắn đi đâu hay ăn gì.
//
// Chương trình chạy theo 3 phần:
//
//  A. Chuẩn bị: bật raw mode cho Terminal (termios), ẩn con trỏ.
//
//  B. Game loop, lặp tới khi người chơi thoát, mỗi vòng là một bước của game:
//       1. Đọc phím: read() lấy các phím vừa bấm, không chờ nếu chưa ai bấm.
//            phím hướng  → game.turn(hướng)       Game xếp lượt rẽ vào hàng đợi của nó (Command)
//            Space       → game.primaryAction()   tạm dừng / chơi tiếp / chơi lại (State)
//            q, Esc      → thoát
//       2. game.tick()   luật chơi chạy đúng một bước (các bước nhỏ xem ở Game.tick)
//       3. render(game)  đọc snake, food, score, state rồi vẽ lại cả màn hình
//       4. Ngủ tickMicros  chờ tới bước sau. Số này quyết định rắn chạy nhanh hay chậm.
//
//  C. Kết thúc: trả Terminal về như cũ, hiện lại con trỏ.
//
// Khác bản Kotlin: ở đây không cần thread đọc phím riêng. termios cho đặt VMIN = 0, VTIME = 0, nên
// read() trả về ngay (0 byte nếu chưa có phím) thay vì đứng chờ. Game loop tự đọc phím ở đầu mỗi vòng.
// File tên main.swift nên code ở cấp ngoài cùng chạy từ trên xuống như hàm main().

import Darwin

/// Micro giây giữa hai bước của game (150 ms).
let tickMicros: UInt32 = 150_000

/// Ký tự ESC mở đầu mọi mã điều khiển Terminal (ANSI escape code): đổi màu, xoá màn hình, ẩn con trỏ…
let esc = "\u{1B}"

// ── A. Chuẩn bị ──────────────────────────────────────────────────────────────────
// Terminal mặc định ở chế độ "cooked": gom cả dòng, chờ Enter mới gửi cho chương trình, và in phím ra
// màn hình. Raw mode tắt hết những thứ đó để mỗi phím tới chương trình ngay lập tức.
// Lưu cấu hình gốc vào `original` để trả lại lúc thoát.
var original = termios()
tcgetattr(STDIN_FILENO, &original)
var raw = original
cfmakeraw(&raw)
raw.c_cc.16 = 0 // VMIN = 0: read() không cần đợi đủ byte nào
raw.c_cc.17 = 0 // VTIME = 0: read() không đợi thêm chút nào, có gì trả nấy
tcsetattr(STDIN_FILENO, TCSANOW, &raw)
print("\(esc)[?25l\(esc)[2J", terminator: "") // ẩn con trỏ, xoá màn hình

var game = Game()
var running = true

// ── B. Game loop ─────────────────────────────────────────────────────────────────
while running {
    // 1. Đọc phím. n là số byte đọc được, 0 nếu từ vòng trước tới giờ không ai bấm gì.
    var buffer = [UInt8](repeating: 0, count: 16)
    var n = read(STDIN_FILENO, &buffer, buffer.count)
    var bytes = Array(buffer.prefix(max(n, 0)))
    // Esc để thoát. Phím mũi tên cũng gửi ESC rồi '[' và một chữ, nên chờ chút xem có '[' theo sau không.
    if bytes.last == 27 {
        usleep(30_000)
        n = read(STDIN_FILENO, &buffer, buffer.count)
        bytes += buffer.prefix(max(n, 0))
    }
    for (i, byte) in bytes.enumerated() {
        if byte == 27, i + 1 >= bytes.count || bytes[i + 1] != UInt8(ascii: "[") { running = false }
        // Phím mũi tên gửi 3 byte ESC [ A/B/C/D. ESC và '[' rơi vào `default`, còn lại chữ cái.
        switch Character(UnicodeScalar(byte)) {
        case "q": running = false
        case "w", "A": game.turn(.up)
        case "s", "B": game.turn(.down)
        case "d", "C": game.turn(.right)
        case "a", "D": game.turn(.left)
        case " ": game.primaryAction()
        default: break
        }
    }
    // 2. Luật chơi chạy một bước.
    game.tick()
    // 3. Vẽ lại.
    render(game)
    // 4. Chờ tới bước sau.
    usleep(tickMicros)
}

// ── C. Kết thúc ──────────────────────────────────────────────────────────────────
tcsetattr(STDIN_FILENO, TCSANOW, &original)
print("\(esc)[?25h")

extension FoodLook {
    var ansi: Int {
        switch self {
        case .red: 91
        case .gold: 93
        case .purple: 95
        }
    }
}

/// Vẽ cả màn hình thành một chuỗi rồi in một lần. `ESC[H` đưa con trỏ về góc trên trái để vẽ đè lên
/// khung cũ thay vì in tiếp xuống dưới, nên màn hình không bị nhấp nháy hay trôi.
/// Trong raw mode, xuống dòng phải viết đủ `\r\n`.
func render(_ game: Game) {
    var s = "\(esc)[H"
    s += "Điểm: \(game.score)   (WASD / mũi tên, Space tạm dừng, q / Esc thoát)\r\n"
    s += "╔" + String(repeating: "══", count: game.width) + "╗\r\n"
    for y in 0..<game.height {
        s += "║"
        for x in 0..<game.width {
            let p = Point(x: x, y: y)
            // Mỗi ô rộng 2 ký tự cho vuông. ESC[92m là chữ xanh lá sáng, ESC[0m trả về màu mặc định.
            if p == game.snake.head { s += "\(esc)[92m██\(esc)[0m" }
            else if game.snake.body.contains(p) { s += "\(esc)[32m██\(esc)[0m" }
            else if let food = game.foods.first(where: { $0.position == p }) { s += "\(esc)[\(food.look.ansi)m●\(esc)[0m " }
            else { s += "  " }
        }
        s += "║\r\n"
    }
    s += "╚" + String(repeating: "══", count: game.width) + "╝\r\n"
    let text = (game.state.overlayText ?? "").split(separator: "\n").first.map(String.init) ?? ""
    s += text + "\(esc)[K\r\n" // ESC[K xoá phần còn lại của dòng
    print(s, terminator: "")
    fflush(stdout)
}
