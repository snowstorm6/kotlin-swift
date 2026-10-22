// Bản chạy trong Terminal. Dùng chung 5 file logic với app Android, không có bản sao nào.
plugins {
    alias(libs.plugins.kotlin.jvm)
    application
}

kotlin {
    jvmToolchain(17)
    sourceSets.main {
        kotlin.srcDir("../app/src/main/java/dev/workshop/snake/game")
    }
}

application {
    applicationName = "snake"
    mainClass.set("dev.workshop.snake.terminal.MainKt")
}
