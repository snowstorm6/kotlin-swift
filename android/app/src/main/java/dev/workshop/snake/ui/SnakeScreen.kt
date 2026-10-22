package dev.workshop.snake.ui

// Phần giao diện cho sẵn, chỉ cần đọc. Các TODO nằm trong package `game`.
//
// Cùng một game loop như bản Terminal, chỉ khác cách làm từng bước:
//  - Input: nút mũi tên, vuốt, phím → game.turn(hướng); chạm bàn chơi, Space → game.primaryAction().
//    Compose gọi các callback này trên main thread, không cần thread đọc phím riêng.
//  - Loop: một coroutine (LaunchedEffect) lặp: delay(TICK_MS) → game.tick() → frame++.
//  - Vẽ: tăng `frame` làm Compose vẽ lại; Canvas đọc snake, food, state từ Game rồi vẽ.

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.workshop.snake.game.Direction
import dev.workshop.snake.game.Game
import dev.workshop.snake.game.overlayText
import kotlin.math.abs
import kotlinx.coroutines.delay

private const val TICK_MS = 150L

private val Background = Color(0xFF101418)
private val BoardColor = Color(0xFF1B232B)
private val SnakeHead = Color(0xFF7BE07B)
private val SnakeBody = Color(0xFF3FA34D)
private val FoodColor = Color(0xFFFF6B6B)

@Composable
fun SnakeScreen() {
    val game = remember { Game() }
    // Game là object bình thường, Compose không tự biết nó đổi. Mỗi tick tăng `frame` để vẽ lại.
    var frame by remember { mutableLongStateOf(0L) }
    val focus = remember { FocusRequester() }

    // Game loop: một coroutine gọi tick() mỗi TICK_MS mili giây.
    LaunchedEffect(game) {
        while (true) {
            delay(TICK_MS)
            game.tick()
            frame++
        }
    }
    LaunchedEffect(Unit) { focus.requestFocus() }

    fun turn(direction: Direction) {
        game.turn(direction)
    }

    MaterialTheme(colorScheme = darkColorScheme()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Background)
                .safeDrawingPadding()
                .padding(16.dp)
                .focusRequester(focus)
                .focusable()
                .onKeyEvent { event ->
                    if (event.type != KeyEventType.KeyDown) return@onKeyEvent false
                    if (event.key == Key.Spacebar) {
                        game.primaryAction()
                        return@onKeyEvent true
                    }
                    val direction = when (event.key) {
                        Key.DirectionUp, Key.W -> Direction.UP
                        Key.DirectionDown, Key.S -> Direction.DOWN
                        Key.DirectionLeft, Key.A -> Direction.LEFT
                        Key.DirectionRight, Key.D -> Direction.RIGHT
                        else -> return@onKeyEvent false
                    }
                    turn(direction)
                    true
                },
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(
                text = "Điểm: ${game.score}",
                color = Color.White,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
            )
            Board(game = game, frame = frame, onTurn = ::turn)
            DirectionPad(onTurn = ::turn)
        }
    }
}

@Composable
private fun Board(game: Game, frame: Long, onTurn: (Direction) -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(game.width.toFloat() / game.height)
            .clickable { game.primaryAction() }
            .pointerInput(Unit) {
                var drag = Offset.Zero
                detectDragGestures(
                    onDragStart = { drag = Offset.Zero },
                    onDrag = { _, amount -> drag += amount },
                    onDragEnd = {
                        if (drag.getDistance() < 40f) return@detectDragGestures
                        onTurn(
                            if (abs(drag.x) > abs(drag.y)) {
                                if (drag.x > 0) Direction.RIGHT else Direction.LEFT
                            } else {
                                if (drag.y > 0) Direction.DOWN else Direction.UP
                            },
                        )
                    },
                )
            },
        contentAlignment = Alignment.Center,
    ) {
        Canvas(Modifier.fillMaxSize().clipToBounds()) {
            frame // đọc frame để Canvas vẽ lại sau mỗi tick
            val cell = size.width / game.width
            val gap = cell * 0.08f
            fun drawCell(x: Int, y: Int, color: Color) = drawRoundRect(
                color = color,
                topLeft = Offset(x * cell + gap, y * cell + gap),
                size = Size(cell - 2 * gap, cell - 2 * gap),
                cornerRadius = CornerRadius(cell * 0.25f),
            )

            drawRect(BoardColor)
            game.food?.let { drawCell(it.x, it.y, FoodColor) }
            game.snake.body.forEachIndexed { i, p ->
                drawCell(p.x, p.y, if (i == 0) SnakeHead else SnakeBody)
            }
        }
        game.state.overlayText()?.let { text ->
            Text(
                text = text,
                color = Color.White,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .background(Color.Black.copy(alpha = 0.7f), MaterialTheme.shapes.medium)
                    .padding(horizontal = 24.dp, vertical = 16.dp),
            )
        }
    }
}

@Composable
private fun DirectionPad(onTurn: (Direction) -> Unit) {
    @Composable
    fun PadButton(label: String, direction: Direction) {
        FilledTonalButton(onClick = { onTurn(direction) }, modifier = Modifier.size(72.dp)) {
            Text(label, fontSize = 22.sp)
        }
    }

    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        PadButton("↑", Direction.UP)
        Row {
            PadButton("←", Direction.LEFT)
            Spacer(Modifier.size(72.dp))
            PadButton("→", Direction.RIGHT)
        }
        PadButton("↓", Direction.DOWN)
    }
}
