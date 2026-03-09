import Foundation
import SwiftUI

struct PictionaryGameView: View {
    let state: PictionaryState
    let isDrawer: Bool
    let localPlayerID: String
    let revealedPrompt: String?
    let publishRound: (String, [PictionaryStroke], Int) -> Void
    let submitGuess: (String, TimeInterval) -> Void

    private enum SetupStage {
        case enterPrompt
        case countdown
        case drawing
    }

    @State private var promptInput = ""
    @State private var guessInput = ""
    @State private var draftStrokes: [PictionaryStroke] = []
    @State private var activeStroke: [PictionaryStrokePoint] = []
    @State private var drawingAnchor: Date?
    @State private var countdownAnchor: Date?
    @State private var setupStage: SetupStage = .enterPrompt
    @State private var lockedPrompt = ""
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
            if setupStage == .countdown, countdownRemaining == 0 {
                beginDrawingPhase()
            }
        }
        .onChange(of: state.publishedAt) {
            resetReplayAndGuessTimer(resetGuess: true)
        }
        .onAppear {
            configureInitialLocalState()
        }
    }

    private var setupView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                stageBadge
                Spacer()
                if setupStage == .drawing {
                    Text("Recording \(formatMilliseconds(max(drawingElapsedMs, draftDurationMs)))")
                        .font(.footnote.weight(.heavy))
                        .foregroundStyle(Color(hex: "#065F46"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#D1FAE5"), in: Capsule())
                }
            }

            TextField("Word or phrase to draw", text: $promptInput)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Color(hex: "#E2E8F0"), in: RoundedRectangle(cornerRadius: 10))
                .disabled(setupStage != .enterPrompt)

            drawingCanvas

            HStack(spacing: 8) {
                Button(primarySetupActionTitle) {
                    handlePrimarySetupAction()
                }
                .font(.subheadline.weight(.bold))
                .frame(minWidth: 108, minHeight: 40)
                .background(primarySetupActionColor, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
                .disabled(!canPerformPrimarySetupAction)

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
                .disabled(setupStage != .drawing || (draftStrokes.isEmpty && activeStroke.isEmpty))

                Button("Clear") {
                    draftStrokes = []
                    activeStroke = []
                }
                .font(.subheadline.weight(.bold))
                .frame(minWidth: 80, minHeight: 40)
                .background(Color(hex: "#64748B"), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
                .disabled(setupStage != .drawing || (draftStrokes.isEmpty && activeStroke.isEmpty))
            }

            Button("Send Puzzle") {
                publishRound(lockedPrompt, draftStrokes, draftDurationMs)
            }
            .font(.subheadline.weight(.heavy))
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(Color(hex: "#0284C7"), in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.white)
            .disabled(!canPublish)

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
            timerHUD

            HStack {
                Text("Hint: \(hintText)")
                Spacer()
                Text("Attempts: \(state.totalGuessAttempts)")
            }
            .font(.headline)
            .foregroundStyle(.black.opacity(0.75))

            replayCanvas

            if !state.lastGuessPreview.isEmpty {
                Text(state.lastGuessPreview)
                    .font(.footnote.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.black.opacity(0.75))
            }

            HStack(spacing: 8) {
                Button("Replay") {
                    resetReplayTimer()
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

                Button("Guess") {
                    let text = guessInput
                    guessInput = ""
                    submitGuess(text, guessElapsedSeconds)
                }
                .font(.subheadline.weight(.heavy))
                .frame(minWidth: 72, minHeight: 42)
                .background(Color(hex: "#0284C7"), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
                .disabled(!canSubmitGuess || normalizePictionaryGuess(guessInput).isEmpty)
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

    private var timerHUD: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                timerCard(
                    title: "REPLAY",
                    value: "\(Int((replayProgress * 100).rounded()))%",
                    subtitle: "\(formatMilliseconds(replayElapsedMs)) / \(formatMilliseconds(max(state.drawingDurationMs, 1)))",
                    gradient: [Color(hex: "#F59E0B"), Color(hex: "#F97316")]
                )

                timerCard(
                    title: "YOUR TIME",
                    value: formatSeconds(guessElapsedSeconds),
                    subtitle: canSubmitGuess ? "Running" : "Locked",
                    gradient: [Color(hex: "#06B6D4"), Color(hex: "#2563EB")]
                )
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#CBD5E1"))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [Color(hex: "#34D399"), Color(hex: "#059669")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * replayProgress)
                }
            }
            .frame(height: 10)
        }
    }

    private func timerCard(title: String, value: String, subtitle: String, gradient: [Color]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(.white.opacity(0.85))
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 12))
    }

    private var stageBadge: some View {
        Group {
            switch setupStage {
            case .enterPrompt:
                Text("1) Enter word, then lock it")
            case .countdown:
                Text("Get ready... \(countdownRemaining)")
            case .drawing:
                Text("Draw now")
            }
        }
        .font(.footnote.weight(.heavy))
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(hex: "#0F766E"), in: Capsule())
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
            .overlay {
                if setupStage != .drawing {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.18))
                    Text(setupStage == .countdown ? "Starts in \(countdownRemaining)..." : "Lock the word to begin")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)
                }
            }
            .contentShape(Rectangle())
            .allowsHitTesting(setupStage == .drawing)
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
        setupStage == .drawing && !lockedPrompt.isEmpty && !draftStrokes.isEmpty
    }

    private var canSubmitGuess: Bool {
        !isDrawer && myResult == nil
    }

    private var replayProgress: Double {
        let total = Double(max(state.drawingDurationMs, 1))
        return min(max(Double(replayElapsedMs) / total, 0), 1)
    }

    private var primarySetupActionTitle: String {
        switch setupStage {
        case .enterPrompt:
            return "Lock Word"
        case .countdown:
            return "Get Ready"
        case .drawing:
            return "Change Word"
        }
    }

    private var primarySetupActionColor: Color {
        switch setupStage {
        case .enterPrompt:
            return Color(hex: "#0F766E")
        case .countdown:
            return Color(hex: "#64748B")
        case .drawing:
            return Color(hex: "#7C3AED")
        }
    }

    private var canPerformPrimarySetupAction: Bool {
        switch setupStage {
        case .enterPrompt:
            return normalizePictionaryGuess(promptInput).count >= 2
        case .countdown:
            return false
        case .drawing:
            return true
        }
    }

    private var countdownRemaining: Int {
        guard setupStage == .countdown, let countdownAnchor else { return 0 }
        let elapsed = Int(now.timeIntervalSince(countdownAnchor))
        return max(3 - elapsed, 0)
    }

    private var drawingElapsedMs: Int {
        guard let drawingAnchor else { return 0 }
        return max(Int((now.timeIntervalSince(drawingAnchor) * 1000).rounded()), 0)
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

    private var hintText: String {
        if state.promptLength <= 0 {
            return "No hint"
        }
        if state.promptFirstLetter.isEmpty {
            return "\(state.promptLength) letters"
        }
        return "\(state.promptLength) letters, starts with \(state.promptFirstLetter)"
    }

    private func handlePrimarySetupAction() {
        switch setupStage {
        case .enterPrompt:
            startCountdownIfPromptValid()
        case .countdown:
            break
        case .drawing:
            resetSetupToPromptEntry()
        }
    }

    private func startCountdownIfPromptValid() {
        let normalizedPrompt = normalizePictionaryGuess(promptInput)
        guard normalizedPrompt.count >= 2 else { return }

        lockedPrompt = normalizedPrompt
        promptInput = normalizedPrompt
        draftStrokes = []
        activeStroke = []
        drawingAnchor = nil
        countdownAnchor = Date()
        setupStage = .countdown
    }

    private func beginDrawingPhase() {
        guard setupStage == .countdown else { return }
        setupStage = .drawing
        drawingAnchor = Date()
    }

    private func resetSetupToPromptEntry() {
        setupStage = .enterPrompt
        lockedPrompt = ""
        countdownAnchor = nil
        drawingAnchor = nil
        draftStrokes = []
        activeStroke = []
    }

    private func appendPoint(location: CGPoint, in size: CGSize) {
        guard setupStage == .drawing else { return }
        guard size.width > 0, size.height > 0 else { return }

        let current = Date()
        if drawingAnchor == nil {
            drawingAnchor = current
        }
        guard let drawingAnchor else { return }

        let elapsedMs = max(Int((current.timeIntervalSince(drawingAnchor) * 1000).rounded()), 0)
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
        guard setupStage == .drawing else { return }
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

    private func configureInitialLocalState() {
        if state.phase == .setup && isDrawer {
            if let revealedPrompt, !revealedPrompt.isEmpty {
                promptInput = revealedPrompt
            }
            setupStage = .enterPrompt
            lockedPrompt = ""
            countdownAnchor = nil
            drawingAnchor = nil
            draftStrokes = []
            activeStroke = []
        }
        resetReplayAndGuessTimer(resetGuess: true)
    }

    private func resetReplayTimer() {
        replayAnchor = Date()
    }

    private func resetReplayAndGuessTimer(resetGuess: Bool) {
        let current = Date()
        replayAnchor = current
        if resetGuess {
            guessAnchor = current
        }
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
