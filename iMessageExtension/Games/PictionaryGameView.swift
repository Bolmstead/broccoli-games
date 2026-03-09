import Foundation
import SwiftUI

struct PictionaryGameView: View {
    let state: PictionaryState
    let isDrawer: Bool
    let localPlayerID: String
    let revealedPrompt: String?
    let publishRound: (String, [PictionaryStroke], Int) -> Void
    let submitGuess: (String, TimeInterval) -> Void

    @State private var promptInput = ""
    @State private var guessInput = ""
    @State private var draftStrokes: [PictionaryStroke] = []
    @State private var activeStroke: [PictionaryStrokePoint] = []
    @State private var drawingAnchor: Date?
    @State private var now = Date()
    @State private var replayAnchor = Date()
    @State private var guessAnchor = Date()

    private let timer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()
    private let pointScale = 1000.0

    var body: some View {
        VStack(spacing: 10) {
            if state.phase == .setup && isDrawer {
                setupView
            } else {
                guessView
            }
        }
        .onReceive(timer) { _ in
            now = Date()
        }
        .onChange(of: state.publishedAt) { _ in
            resetReplayAndGuessTimer()
        }
        .onAppear {
            if state.phase == .setup && isDrawer, let revealedPrompt, !revealedPrompt.isEmpty {
                promptInput = revealedPrompt
            }
            resetReplayAndGuessTimer()
        }
    }

    private var setupView: some View {
        VStack(spacing: 10) {
            TextField("Word or phrase to draw", text: $promptInput)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Color(hex: "#E2E8F0"), in: RoundedRectangle(cornerRadius: 10))

            drawingCanvas

            HStack(spacing: 8) {
                Button("Undo") {
                    if !activeStroke.isEmpty {
                        activeStroke = []
                    } else if !draftStrokes.isEmpty {
                        draftStrokes.removeLast()
                    }
                }
                .font(.subheadline.weight(.bold))
                .frame(minWidth: 80, minHeight: 40)
                .background(Color(hex: "#475569"), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
                .disabled(draftStrokes.isEmpty && activeStroke.isEmpty)

                Button("Clear") {
                    draftStrokes = []
                    activeStroke = []
                    drawingAnchor = nil
                }
                .font(.subheadline.weight(.bold))
                .frame(minWidth: 80, minHeight: 40)
                .background(Color(hex: "#64748B"), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
                .disabled(draftStrokes.isEmpty && activeStroke.isEmpty)

                Button("Send Puzzle") {
                    publishRound(promptInput, draftStrokes, draftDurationMs)
                }
                .font(.subheadline.weight(.heavy))
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Color(hex: "#0284C7"), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
                .disabled(!canPublish)
            }

            HStack {
                Text("Strokes: \(draftStrokes.count)")
                Spacer()
                Text("Replay: \(formatMilliseconds(draftDurationMs))")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.black.opacity(0.65))
        }
    }

    private var guessView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Hint: \(hintText)")
                Spacer()
                Text("Attempts: \(state.totalGuessAttempts)")
            }
            .font(.headline)
            .foregroundStyle(.black.opacity(0.75))

            replayCanvas

            HStack {
                Text("Replay: \(formatMilliseconds(replayElapsedMs)) / \(formatMilliseconds(max(state.drawingDurationMs, 1)))")
                Spacer()
                Text("Your Timer: \(formatSeconds(guessElapsedSeconds))")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.black.opacity(0.75))

            if !state.lastGuessPreview.isEmpty {
                Text(state.lastGuessPreview)
                    .font(.footnote.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.black.opacity(0.75))
            }

            HStack(spacing: 8) {
                Button("Replay") {
                    resetReplayAndGuessTimer()
                }
                .font(.subheadline.weight(.bold))
                .frame(minWidth: 84, minHeight: 42)
                .background(Color(hex: "#475569"), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)

                TextField("Type your guess", text: $guessInput)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 10)
                    .frame(minHeight: 42)
                    .background(Color(hex: "#E2E8F0"), in: RoundedRectangle(cornerRadius: 8))
                    .disabled(!canGuess)

                Button("Guess") {
                    let text = guessInput
                    guessInput = ""
                    submitGuess(text, guessElapsedSeconds)
                }
                .font(.subheadline.weight(.heavy))
                .frame(minWidth: 72, minHeight: 42)
                .background(Color(hex: "#0284C7"), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
                .disabled(!canGuess || normalizePictionaryGuess(guessInput).isEmpty)
            }

            if let mine = myResult {
                Text("You solved in \(formatMilliseconds(mine.elapsedMs)).")
                    .font(.footnote.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color(hex: "#065F46"))
            }

            if !state.correctResults.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Leaderboard")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(.black.opacity(0.8))

                    ForEach(Array(state.correctResults.prefix(5).enumerated()), id: \.element.id) { index, result in
                        HStack {
                            Text("\(index + 1). \(playerLabel(for: result.playerID))")
                            Spacer()
                            Text(formatMilliseconds(result.elapsedMs))
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.black.opacity(0.75))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if isDrawer {
                Text("Drawer mode: monitor guesses and leaderboard.")
                    .font(.footnote.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.black.opacity(0.65))
            }
        }
    }

    private var drawingCanvas: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                context.fill(Path(rect), with: .color(Color(hex: "#F8FAFC")))

                for stroke in draftStrokes {
                    drawStroke(stroke, in: &context, size: size, color: Color(hex: "#111827"), lineWidth: 4)
                }

                drawStroke(PictionaryStroke(points: activeStroke), in: &context, size: size, color: Color(hex: "#111827"), lineWidth: 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.12), lineWidth: 1))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        appendPoint(location: value.location, in: geometry.size)
                    }
                    .onEnded { _ in
                        finishStroke()
                    }
            )
        }
        .frame(height: 220)
    }

    private var replayCanvas: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .color(Color(hex: "#F8FAFC")))

            for stroke in state.strokes {
                drawStroke(stroke, in: &context, size: size, color: Color(hex: "#111827"), lineWidth: 4, maxTime: replayElapsedMs)
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.12), lineWidth: 1))
    }

    private var canPublish: Bool {
        normalizePictionaryGuess(promptInput).count >= 2 && !draftStrokes.isEmpty
    }

    private var draftDurationMs: Int {
        draftStrokes.flatMap(\.points).map(\.t).max() ?? 0
    }

    private var replayElapsedMs: Int {
        let elapsed = Int((now.timeIntervalSince(replayAnchor) * 1000).rounded())
        return min(max(elapsed, 0), max(state.drawingDurationMs, 0))
    }

    private var guessElapsedSeconds: TimeInterval {
        max(now.timeIntervalSince(guessAnchor), 0)
    }

    private var myResult: PictionaryResult? {
        state.correctResults.first { $0.playerID == localPlayerID }
    }

    private var canGuess: Bool {
        !isDrawer && myResult == nil
    }

    private var hintText: String {
        if state.promptLength <= 0 {
            return "No hint"
        }
        if state.promptFirstLetter.isEmpty {
            return "\(state.promptLength) letters"
        }
        return "\(state.promptLength) letters, starts with \(state.promptFirstLetter)"
    }

    private func appendPoint(location: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        let now = Date()
        if drawingAnchor == nil {
            drawingAnchor = now
        }
        guard let drawingAnchor else { return }

        let elapsedMs = max(Int((now.timeIntervalSince(drawingAnchor) * 1000).rounded()), 0)
        let point = PictionaryStrokePoint(
            x: Int((max(0, min(location.x, size.width)) / size.width * pointScale).rounded()),
            y: Int((max(0, min(location.y, size.height)) / size.height * pointScale).rounded()),
            t: elapsedMs
        )

        if let previous = activeStroke.last {
            let dx = point.x - previous.x
            let dy = point.y - previous.y
            let distance = sqrt(Double(dx * dx + dy * dy))
            let dt = point.t - previous.t
            if distance < 12, dt < 30 {
                return
            }
        }

        activeStroke.append(point)
    }

    private func finishStroke() {
        guard !activeStroke.isEmpty else { return }
        draftStrokes.append(PictionaryStroke(points: activeStroke))
        activeStroke = []
    }

    private func drawStroke(
        _ stroke: PictionaryStroke,
        in context: inout GraphicsContext,
        size: CGSize,
        color: Color,
        lineWidth: CGFloat,
        maxTime: Int? = nil
    ) {
        let points: [PictionaryStrokePoint]
        if let maxTime {
            points = stroke.points.filter { $0.t <= maxTime }
        } else {
            points = stroke.points
        }

        guard !points.isEmpty else { return }

        if points.count == 1, let first = points.first {
            let center = point(first, in: size)
            let dot = CGRect(x: center.x - lineWidth / 2, y: center.y - lineWidth / 2, width: lineWidth, height: lineWidth)
            context.fill(Path(ellipseIn: dot), with: .color(color))
            return
        }

        var path = Path()
        path.move(to: point(points[0], in: size))
        for p in points.dropFirst() {
            path.addLine(to: point(p, in: size))
        }
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }

    private func point(_ p: PictionaryStrokePoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: CGFloat(p.x) / pointScale * size.width,
            y: CGFloat(p.y) / pointScale * size.height
        )
    }

    private func resetReplayAndGuessTimer() {
        let now = Date()
        replayAnchor = now
        guessAnchor = now
    }

    private func formatMilliseconds(_ ms: Int) -> String {
        String(format: "%.2fs", Double(max(ms, 0)) / 1000.0)
    }

    private func formatSeconds(_ seconds: TimeInterval) -> String {
        String(format: "%.2fs", max(seconds, 0))
    }

    private func playerLabel(for playerID: String) -> String {
        if playerID == localPlayerID {
            return "You"
        }
        let short = String(playerID.suffix(4)).uppercased()
        return "Player \(short)"
    }
}
