# Snake · Kotlin ⇄ Swift

Bài thực hành cho buổi sharing "Kotlin vs Swift – Language & Runtime".
Một game rắn viết song song hai lần: `android/` (Kotlin + Compose) và `ios/` (Swift + SwiftUI).
Bạn code bằng ngôn ngữ mình **chưa** quen: dev Android làm bên `ios/`, dev iOS làm bên `android/`.

## Chạy

Mỗi ngôn ngữ có hai cách chạy, dùng chung đúng 5 file logic chứa TODO. Sửa một lần, cả hai cách đều thấy.

**Bản app mobile**

| | Mở | Chạy |
|---|---|---|
| Kotlin | Android Studio › Open › thư mục `android/` | Chọn emulator, bấm ▶ |
| Swift | Xcode › mở `ios/Snake.xcodeproj` | Chọn một iPhone Simulator, bấm ⌘R |

Điều khiển: nút mũi tên, vuốt trên bàn chơi, hoặc phím mũi tên / WASD. Chạm vào bàn (hoặc Space) để tạm dừng, chơi tiếp, hay chơi lại khi đã thua.

**Bản Terminal** (không cần emulator hay Simulator)

```bash
./run-kotlin.sh
```

```bash
./run-swift.sh
```

Chạy trong Terminal của macOS, hoặc tab Terminal của Android Studio. Không chạy bằng ▶ trong IDE được, vì console của IDE không đọc được từng phím.
Điều khiển: phím mũi tên / WASD, Space để tạm dừng / chơi tiếp / chơi lại, `q` hoặc Esc để thoát.
Cần có: JDK 17+ cho Kotlin (Android Studio có sẵn), Xcode hoặc Xcode Command Line Tools cho Swift.

## Game chạy thế nào

Code chia hai phần. **Logic** (`Game` và các file cùng thư mục) giữ luật chơi, không biết gì về màn hình hay thời gian. **Giao diện** (app hoặc Terminal) đọc phím, gọi Game theo nhịp, rồi vẽ.

Game loop, ví dụ ở bản Terminal (`android/terminal/.../Main.kt`, `ios/Terminal/main.swift`):

```
Chuẩn bị: bật raw mode cho Terminal (đọc từng phím, không chờ Enter), ẩn con trỏ
   │
   ▼
┌─► 1. Đọc phím      phím hướng → game.turn()      Space → game.primaryAction()      q / Esc → thoát
│   2. game.tick()   luật chơi chạy đúng một bước
│   3. render()      vẽ lại cả màn hình từ snake, food, score, state
└── 4. Ngủ 150 ms    rồi quay lại bước 1
   │
   ▼
Kết thúc: trả Terminal về như cũ
```

Bên trong một `game.tick()` (`Game.kt` / `Game.swift`):

| Bước | Làm gì | TODO |
|---|---|---|
| 1 | Chỉ chạy khi đang Running; Ready, Paused, GameOver thì rắn đứng yên | |
| 2 | `applyNextTurn()`: lấy một lượt rẽ trong hàng đợi, bỏ qua nếu là quay đầu | TODO 3 |
| 3 | `tryEat()`: ô trước đầu rắn có mồi thì cộng điểm, đặt mồi mới | TODO 1 |
| 4 | `move()`: rắn tiến một ô, vừa ăn thì dài thêm | |
| 5 | Va chạm tường hoặc tự cắn thì `crash()` chuyển sang GameOver | TODO 2, TODO 4 |

Trạng thái ván chơi: `Ready` → (bấm hướng) → `Running` ⇄ (Space) `Paused`; `Running` → (va chạm) → `GameOver` → (Space) → `Ready`.

Bản app chạy y hệt các bước trên, chỉ khác: input đến từ nút bấm / vuốt, vòng lặp là một coroutine (Compose) hoặc Task (SwiftUI), và vẽ bằng Canvas.

## 4 TODO

Toàn bộ TODO nằm trong 5 file logic thuần ngôn ngữ, cùng tên ở hai bên:
`android/app/src/main/java/dev/workshop/snake/game/` và `ios/Snake/Game/`
(`Point`, `Direction`, `Snake`, `GameState`, `Game`). Phần giao diện (app: `ui/`, `ContentView.swift`; Terminal: `android/terminal/`, `ios/Terminal/`) cho sẵn, chỉ cần đọc.

| TODO | Khái niệm | Việc cần làm | File |
|---|---|---|---|
| 1 | Null safety | Rắn ăn mồi (`food` có thể null) | `Game` |
| 2 | Data model | Va chạm tường và tự cắn mình | `Snake`, `Game` |
| 3 | Extension | Cấm quay đầu 180° | `Direction`, `Game` |
| 4 | Sealed / enum | Màn Game Over kèm điểm | `GameState`, `Game` |

Tìm nhanh: Android Studio › View › Tool Windows › TODO; Xcode › ⌘⇧F tìm `TODO`.

## Tự kiểm tra bằng unit test

Mỗi TODO có test riêng. Ở nhánh `main` các test TODO đỏ; làm xong TODO nào thì test của TODO đó xanh.

```bash
cd android && ./gradlew test
```

```bash
cd ios && swift test
```

Trong Android Studio có thể bấm ▶ cạnh tên class test trong `app/src/test/`.

## Cách tổ chức code

Logic game không biết gì về giao diện hay thời gian thực, nên chạy chung được cho app và Terminal, và test được. Một vài pattern quen thuộc trong code game (xem [Game Programming Patterns](https://gameprogrammingpatterns.com/contents.html)):

| Pattern | Ở đâu | Để làm gì |
|---|---|---|
| Game loop | Phần giao diện gọi `tick()` đều đặn | Logic chỉ cần biết "một bước", không biết mili giây |
| State | `GameState`: Ready → Running ⇄ Paused → GameOver | Mỗi trạng thái xử lý input khác nhau, compiler bắt thiếu trường hợp |
| Command | Hàng đợi `pendingTurns` trong `Game` | Bấm nhanh nhiều phím trong một tick vẫn đúng thứ tự |
| Strategy | `FoodSpawner` | Chơi thì sinh mồi ngẫu nhiên, test thì đặt mồi cố định |
| Observer | `GameListener` (nhánh `full`) | Thống kê, kỷ lục, log nghe sự kiện mà Game không cần biết |

## Các nhánh (checkpoint)

Mỗi nhánh hơn nhánh trước đúng một TODO:

```
main ── todo-1-done ── todo-2-done ── todo-3-done ── solution ── full
```

- `main`: bản khởi đầu, còn đủ 4 TODO.
- `todo-N-done`: đã làm xong TODO 1 tới N.
- `solution`: xong cả 4 TODO.
- `full`: thêm cả 5 tính năng của phần Make bên dưới, mỗi tính năng một commit.

Làm không kịp? Cất code đang làm rồi nhảy sang checkpoint:

```bash
git stash
git switch todo-2-done
```

Xem lời giải của riêng một TODO, ví dụ TODO 3:

```bash
git diff todo-2-done todo-3-done
```

## Make (bài về nhà)

Chọn 1–2 tính năng, làm từ nhánh `solution` bằng ngôn ngữ bạn chưa quen, rồi gửi pull request.
Nhánh `full` có sẵn lời giải mẫu cho cả 5, xem riêng từng tính năng bằng `git log --oneline solution..full`.

| Make | Khái niệm | Tính năng | Kotlin | Swift |
|---|---|---|---|---|
| 1 | Interface / protocol | Nhiều loại mồi: táo, táo vàng, quả teo. Mỗi loại tự áp hiệu ứng | `interface Food`, default method | `protocol Food`, `[any Food]`, protocol extension, generic `inout` |
| 2 | Property delegate / wrapper | Kỷ lục tự lưu khi gán; rắn nhanh dần theo điểm | `var best by persisted(store)` | `@Persisted var best` (giống `@AppStorage`) |
| 3 | Scope function | Lưu kỷ lục vào file | `use { }`, `apply`, `?.let`, `runCatching` | `guard let`, `throws`, `try?` |
| 4 | Generic | 3 màn chơi viết bằng text | `Grid<out T>`, type erasure | `Grid<Element>`, `some Sequence` |
| 5 | Delegation | Thống kê, sự kiện mới nhất, ghi kỷ lục qua listener | `interface GameListener`, `by` | `protocol GameListener`, chuyển tiếp bằng tay |

Mỗi bài Make đều có unit test ở nhánh `full` (`Make1FoodTest`… bên Kotlin, `Make 1 · Protocol`… bên Swift).
