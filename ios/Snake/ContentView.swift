// Phần giao diện cho sẵn, chỉ cần đọc. Các TODO nằm trong thư mục Game/.
//
// Cùng một game loop như bản Terminal, chỉ khác cách làm từng bước:
//  - Input: nút mũi tên, vuốt, phím → game.turn(hướng); chạm bàn chơi, Space → game.primaryAction().
//    SwiftUI gọi các closure này trên main thread, không cần thread đọc phím riêng.
//  - Loop: một Task (.task) lặp: sleep game.stepMillis → game.tick().
//  - Vẽ: Game là struct trong @State, tick() sửa nó nên SwiftUI tự vẽ lại body.

import SwiftUI

private let backgroundColor = Color(red: 0.06, green: 0.08, blue: 0.09)
private let boardColor = Color(red: 0.11, green: 0.14, blue: 0.17)
private let snakeHeadColor = Color(red: 0.48, green: 0.88, blue: 0.48)
private let snakeBodyColor = Color(red: 0.25, green: 0.64, blue: 0.30)

struct ContentView: View {
    // Game là struct: mỗi lần tick() sửa nó, SwiftUI thấy @State đổi và vẽ lại.
    @State private var game = Game()
    @State private var highScore = HighScore(
        store: FileScoreStore(url: .documentsDirectory.appending(path: "highscore.txt"))
    )
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("Điểm: \(game.score)   Kỷ lục: \(highScore.best)")
                .font(.title2.bold())
                .foregroundStyle(.white)

            BoardView(game: game)
                .aspectRatio(CGFloat(game.width) / CGFloat(game.height), contentMode: .fit)
                .overlay {
                    if let text = game.state.overlayText {
                        Text(text)
                            .font(.title3.bold())
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(.black.opacity(0.7), in: .rect(cornerRadius: 12))
                    }
                }
                .contentShape(.rect)
                .onTapGesture { game.primaryAction() }
                .gesture(
                    DragGesture(minimumDistance: 20).onEnded { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        if abs(dx) > abs(dy) {
                            game.turn(dx > 0 ? .right : .left)
                        } else {
                            game.turn(dy > 0 ? .down : .up)
                        }
                    }
                )

            DirectionPad { game.turn($0) }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onKeyPress(keys: [.upArrow, .downArrow, .leftArrow, .rightArrow, .space, "w", "a", "s", "d"]) { press in
            switch press.key {
            case .space: game.primaryAction()
            case .upArrow, "w": game.turn(.up)
            case .downArrow, "s": game.turn(.down)
            case .leftArrow, "a": game.turn(.left)
            default: game.turn(.right)
            }
            return .handled
        }
        .onAppear { focused = true }
        // Game loop: một Task gọi tick() theo nhịp game.stepMillis, tự huỷ khi view biến mất.
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(game.stepMillis))
                game.tick()
                if case .gameOver(let score) = game.state { highScore.submit(score) }
            }
        }
    }
}

private struct BoardView: View {
    let game: Game

    var body: some View {
        Canvas { context, size in
            let cell = size.width / CGFloat(game.width)
            let gap = cell * 0.08

            func drawCell(_ p: Point, _ color: Color) {
                let rect = CGRect(
                    x: CGFloat(p.x) * cell + gap,
                    y: CGFloat(p.y) * cell + gap,
                    width: cell - 2 * gap,
                    height: cell - 2 * gap
                )
                context.fill(Path(roundedRect: rect, cornerRadius: cell * 0.25), with: .color(color))
            }

            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(boardColor))
            for food in game.foods { drawCell(food.position, food.look.color) }
            for (i, p) in game.snake.body.enumerated() {
                drawCell(p, i == 0 ? snakeHeadColor : snakeBodyColor)
            }
        }
    }
}

private struct DirectionPad: View {
    let onTurn: (Direction) -> Void

    var body: some View {
        VStack(spacing: 4) {
            button("arrow.up", .up)
            HStack(spacing: 4) {
                button("arrow.left", .left)
                Color.clear.frame(width: 72, height: 72)
                button("arrow.right", .right)
            }
            button("arrow.down", .down)
        }
    }

    private func button(_ symbol: String, _ direction: Direction) -> some View {
        Button { onTurn(direction) } label: {
            Image(systemName: symbol)
                .font(.title2)
                .frame(width: 56, height: 56)
        }
        .buttonStyle(.bordered)
        .tint(.green)
    }
}

private extension FoodLook {
    var color: Color {
        switch self {
        case .red: Color(red: 1.0, green: 0.42, blue: 0.42)
        case .gold: Color(red: 1.0, green: 0.83, blue: 0.23)
        case .purple: Color(red: 0.71, green: 0.48, blue: 1.0)
        }
    }
}

#Preview {
    ContentView()
}
