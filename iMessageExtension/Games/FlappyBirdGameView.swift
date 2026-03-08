import SwiftUI

struct FlappyBirdGameView: View {
    let globalState: FlappyBirdState
    let localBest: Int
    let submitScore: (Int) -> Void

    @State private var birdY: CGFloat = 170
    @State private var birdVelocity: CGFloat = 0
    @State private var pipes: [Pipe] = []
    @State private var score: Int = 0
    @State private var started = false
    @State private var gameOver = false
    @State private var frameCount = 0
    @State private var scoreSent = false

    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Run: \(score)")
                Spacer()
                Text("Best: \(bestScore)")
            }
            .font(.headline)
            .foregroundStyle(.black.opacity(0.7))
            .accessibilityLabel("Run \(score), best \(bestScore)")

            Canvas { context, size in
                let floorHeight: CGFloat = 32

                let skyRect = CGRect(origin: .zero, size: size)
                context.fill(Path(skyRect), with: .linearGradient(
                    Gradient(colors: [Color(hex: "#8BE9FF"), Color(hex: "#E0F2FE")]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                ))

                let floor = CGRect(x: 0, y: size.height - floorHeight, width: size.width, height: floorHeight)
                context.fill(Path(floor), with: .color(Color(hex: "#84CC16")))

                for pipe in pipes {
                    let topPipe = CGRect(x: pipe.x, y: 0, width: 46, height: pipe.gapY - 54)
                    let bottomPipe = CGRect(
                        x: pipe.x,
                        y: pipe.gapY + 54,
                        width: 46,
                        height: size.height - floorHeight - (pipe.gapY + 54)
                    )

                    context.fill(Path(topPipe), with: .color(Color(hex: "#16A34A")))
                    context.fill(Path(bottomPipe), with: .color(Color(hex: "#16A34A")))
                }

                let birdRect = CGRect(x: 62, y: birdY, width: 22, height: 22)
                context.fill(Path(ellipseIn: birdRect), with: .color(Color(hex: "#FACC15")))
                context.stroke(Path(ellipseIn: birdRect), with: .color(.black.opacity(0.5)), lineWidth: 1)

                if !started {
                    drawOverlay(context: context, size: size, text: "Tap to Start")
                }
                if gameOver {
                    drawOverlay(context: context, size: size, text: "Game Over")
                }
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.12), lineWidth: 1))
            .contentShape(Rectangle())
            .onTapGesture {
                flap()
            }
            .accessibilityLabel("Flappy game field")
            .accessibilityHint("Double tap to flap")

            HStack(spacing: 8) {
                Button("Flap") { flap() }
                    .font(.subheadline.weight(.heavy))
                    .frame(minWidth: 90, minHeight: 44)
                    .background(Color(hex: "#0EA5E9"), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)

                Button("Reset") { resetRun() }
                    .font(.subheadline.weight(.heavy))
                    .frame(minWidth: 90, minHeight: 44)
                    .background(Color(hex: "#475569"), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
            }
        }
        .onReceive(timer) { _ in
            tick()
        }
        .onAppear {
            resetRun()
        }
    }

    private var bestScore: Int {
        max(globalState.bestScore, localBest, score)
    }

    private func flap() {
        guard !gameOver else { return }
        started = true
        birdVelocity = -6.3
    }

    private func resetRun() {
        birdY = 170
        birdVelocity = 0
        pipes = []
        score = 0
        started = false
        gameOver = false
        frameCount = 0
        scoreSent = false
    }

    private func tick() {
        guard started, !gameOver else { return }

        frameCount += 1

        birdVelocity += 0.42
        birdY += birdVelocity

        if frameCount % 88 == 0 {
            let gapY = CGFloat(Int.random(in: 84...170))
            pipes.append(Pipe(x: 320, gapY: gapY, counted: false))
        }

        for idx in pipes.indices {
            pipes[idx].x -= 2.7
        }

        pipes.removeAll { $0.x < -52 }

        for idx in pipes.indices {
            if !pipes[idx].counted && pipes[idx].x + 46 < 62 {
                pipes[idx].counted = true
                score += 1
            }
        }

        let birdRect = CGRect(x: 62, y: birdY, width: 22, height: 22)
        let floorY: CGFloat = 228

        if birdRect.minY <= 0 || birdRect.maxY >= floorY {
            endRun()
            return
        }

        for pipe in pipes {
            let topPipe = CGRect(x: pipe.x, y: 0, width: 46, height: pipe.gapY - 54)
            let bottomPipe = CGRect(x: pipe.x, y: pipe.gapY + 54, width: 46, height: floorY - (pipe.gapY + 54))
            if birdRect.intersects(topPipe) || birdRect.intersects(bottomPipe) {
                endRun()
                return
            }
        }
    }

    private func endRun() {
        gameOver = true
        if !scoreSent {
            submitScore(score)
            scoreSent = true
        }
    }

    private func drawOverlay(context: GraphicsContext, size: CGSize, text: String) {
        let rect = CGRect(x: 80, y: 96, width: size.width - 160, height: 68)
        context.fill(Path(roundedRect: rect, cornerRadius: 10), with: .color(Color.black.opacity(0.6)))
        context.draw(
            Text(text)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white),
            at: CGPoint(x: size.width / 2, y: 130)
        )
    }

    private struct Pipe {
        var x: CGFloat
        var gapY: CGFloat
        var counted: Bool
    }
}
