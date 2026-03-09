import Foundation
@preconcurrency import Messages

@MainActor
final class MessagesCoordinator: ObservableObject {
    @Published var envelope: ArcadeEnvelope?
    @Published var statusText: String = "Start a game and send it to your chat."
    @Published var errorText: String?
    @Published var turnHintText: String?
    @Published var lastPlayedGame: ArcadeGame?
    @Published var localFlappyBest: Int
    @Published var hasPendingTurnUpdate: Bool = false

    private weak var conversation: MSConversation?
    private let defaults: UserDefaults
    private let fallbackPlayerID: String

    private enum DefaultsKey {
        static let lastPlayedGame = "arcade.lastPlayedGame"
        static let localFlappyBest = "arcade.localFlappyBest"
        static let fallbackPlayerID = "arcade.fallbackPlayerID"
        static let pictionaryPromptPrefix = "arcade.pictionary.prompt."
    }

    private enum SendPolicy {
        static let maxPayloadBytes = 6000
        static let maxURLBytes = 7000
        static let retryAttempts = 1
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let existing = defaults.string(forKey: DefaultsKey.fallbackPlayerID), !existing.isEmpty {
            self.fallbackPlayerID = existing
        } else {
            let generated = UUID().uuidString.lowercased()
            defaults.set(generated, forKey: DefaultsKey.fallbackPlayerID)
            self.fallbackPlayerID = generated
        }

        if let raw = defaults.string(forKey: DefaultsKey.lastPlayedGame),
           let game = ArcadeGame(rawValue: raw) {
            self.lastPlayedGame = game
        } else {
            self.lastPlayedGame = nil
        }

        self.localFlappyBest = defaults.integer(forKey: DefaultsKey.localFlappyBest)
    }

    func setConversation(_ conversation: MSConversation?) {
        self.conversation = conversation
    }

    func currentPlayerID() -> String {
        conversation?.localParticipantIdentifier.uuidString.lowercased() ?? fallbackPlayerID
    }

    func isLocalPlayerDrawer(for state: PictionaryState) -> Bool {
        !state.drawerID.isEmpty && state.drawerID == currentPlayerID()
    }

    func localPictionaryPrompt(for sessionID: String) -> String? {
        defaults.string(forKey: pictionaryPromptKey(sessionID: sessionID))
    }

    func isLocalTurnForYahtzee(_ state: YahtzeeState) -> Bool {
        canLocalAct(currentPlayer: state.currentPlayer, playerOneID: state.playerOneID, playerTwoID: state.playerTwoID)
    }

    func isLocalTurnForTicTacToe(_ state: TicTacToeState) -> Bool {
        canLocalAct(currentPlayer: state.currentPlayer, playerOneID: state.playerOneID, playerTwoID: state.playerTwoID)
    }

    func isLocalTurnForConnect4(_ state: Connect4State) -> Bool {
        canLocalAct(currentPlayer: state.currentPlayer, playerOneID: state.playerOneID, playerTwoID: state.playerTwoID)
    }

    func sendPendingTurnUpdate() {
        guard hasPendingTurnUpdate else { return }
        hasPendingTurnUpdate = false
        sendCurrent(summary: statusText)
    }

    func ingest(message: MSMessage?) {
        guard let message else {
            return
        }

        guard let payload = extractPayload(from: message) else {
            errorText = "This message has no playable game payload."
            return
        }

        guard let decoded = ArcadeCodec.decode(payload) else {
            errorText = "Could not load this game message. It may be from an older format."
            return
        }

        let normalized = normalize(decoded)
        envelope = normalized
        statusText = normalized.lastSummary.isEmpty ? "Loaded \(normalized.game.title)." : normalized.lastSummary
        errorText = nil
        hasPendingTurnUpdate = false
        persistLastPlayedGame(normalized.game)
        updateTurnHintAfterReceive(message: message, game: normalized.game)
    }

    func startGame(_ game: ArcadeGame) {
        var fresh = ArcadeEnvelope.fresh(game: game)
        fresh = normalize(fresh)

        envelope = fresh
        statusText = game == .pictionary ? "Draw and send a puzzle to the group." : "New \(game.title) round."
        hasPendingTurnUpdate = false
        persistLastPlayedGame(game)
        if game == .pictionary {
            return
        }
        if isTurnTrackedGame(game) {
            turnHintText = "Your turn."
            return
        }
        updateTurnHintAfterLocalSend(for: game)
        sendCurrent(summary: statusText)
    }

    func startLastPlayedGame() {
        guard let lastPlayedGame else {
            statusText = "Pick a game from the lobby."
            return
        }
        startGame(lastPlayedGame)
    }

    func resetCurrentGame() {
        guard let current = envelope else { return }

        var fresh = ArcadeEnvelope.fresh(game: current.game)
        fresh = normalize(fresh)

        envelope = fresh
        statusText = current.game == .pictionary ? "Start a new drawing and send when ready." : "Round reset for \(current.game.title)."
        hasPendingTurnUpdate = false
        updateTurnHintAfterLocalSend(for: current.game)
        if current.game == .pictionary {
            return
        }
        sendCurrent(summary: statusText)
    }

    func returnToLobby() {
        envelope = nil
        turnHintText = nil
        hasPendingTurnUpdate = false
        statusText = "Pick a game from the lobby."
    }

    func playTicTacToe(at index: Int) {
        guard var e = envelope, e.game == .ticTacToe, var state = e.ticTacToe else { return }
        guard index >= 0 && index < 9 else { return }
        guard state.winner == nil, !state.isDraw, state.board[index] == 0 else { return }
        guard claimTurnOwnership(currentPlayer: state.currentPlayer, playerOneID: &state.playerOneID, playerTwoID: &state.playerTwoID) else {
            return
        }

        state.board[index] = state.currentPlayer

        if let winner = winnerForTicTacToe(board: state.board) {
            state.winner = winner
            statusText = "\(winner == 1 ? "Player X" : "Player O") wins."
        } else if !state.board.contains(0) {
            state.isDraw = true
            statusText = "Draw game."
        } else {
            state.currentPlayer = state.currentPlayer == 1 ? 2 : 1
            statusText = "\(state.currentPlayer == 1 ? "Player X" : "Player O") turn."
        }

        e.ticTacToe = state
        commit(envelope: e, summary: statusText, sendNow: false)
    }

    func dropConnect4(column: Int) {
        guard var e = envelope, e.game == .connect4, var state = e.connect4 else { return }
        guard column >= 0 && column < 7 else { return }
        guard state.winner == nil, !state.isDraw else { return }
        guard claimTurnOwnership(currentPlayer: state.currentPlayer, playerOneID: &state.playerOneID, playerTwoID: &state.playerTwoID) else {
            return
        }

        let row = nextOpenConnect4Row(board: state.board, column: column)
        guard row >= 0 else {
            statusText = "That column is full."
            return
        }

        let index = row * 7 + column
        state.board[index] = state.currentPlayer

        if checkConnect4Win(board: state.board, row: row, col: column, player: state.currentPlayer) {
            state.winner = state.currentPlayer
            statusText = "\(state.currentPlayer == 1 ? "Red" : "Yellow") wins."
        } else if !state.board.contains(0) {
            state.isDraw = true
            statusText = "Draw game."
        } else {
            state.currentPlayer = state.currentPlayer == 1 ? 2 : 1
            statusText = "\(state.currentPlayer == 1 ? "Red" : "Yellow") turn."
        }

        e.connect4 = state
        commit(envelope: e, summary: statusText, sendNow: false)
    }

    func wordleAddLetter(_ letter: String) {
        guard var e = envelope, e.game == .wordle, var state = e.wordle, !state.isOver else { return }
        guard state.currentGuess.count < 5 else {
            statusText = "Use Enter to submit your 5-letter guess."
            return
        }

        let normalized = letter.lowercased()
        guard normalized.count == 1,
              normalized.range(of: "^[a-z]$", options: .regularExpression) != nil else {
            statusText = "Letters A-Z only."
            return
        }

        state.currentGuess.append(contentsOf: normalized)
        e.wordle = state
        envelope = e
        statusText = "Compose guess \(state.guesses.count + 1)/6"
    }

    func wordleBackspace() {
        guard var e = envelope, e.game == .wordle, var state = e.wordle, !state.isOver else { return }
        guard !state.currentGuess.isEmpty else {
            statusText = "Nothing to delete."
            return
        }
        state.currentGuess.removeLast()
        e.wordle = state
        envelope = e
    }

    func wordleSubmitGuess() {
        guard var e = envelope, e.game == .wordle, var state = e.wordle, !state.isOver else { return }

        let guess = state.currentGuess.lowercased()
        guard guess.count == 5 else {
            statusText = "Guess must be exactly 5 letters."
            return
        }
        guard WordleDictionary.asSet.contains(guess) else {
            statusText = "Word not in this game dictionary."
            return
        }

        let eval = evaluateWordle(guess: guess, target: state.targetWord)
        guard eval.count == 5 else {
            statusText = "Could not evaluate guess. Try again."
            return
        }

        state.guesses.append(guess)
        state.evaluations.append(eval)
        state.currentGuess = ""

        if guess == state.targetWord {
            state.isOver = true
            state.didWin = true
            statusText = "Solved in \(state.guesses.count)/6."
        } else if state.guesses.count >= 6 {
            state.isOver = true
            statusText = "Out of guesses. Word was \(state.targetWord.uppercased())."
        } else {
            statusText = "Guess \(state.guesses.count + 1)/6"
        }

        e.wordle = state
        commit(envelope: e, summary: statusText)
    }

    func boggleSubmit(word rawWord: String, at now: Date = Date()) {
        guard var e = envelope, e.game == .boggle, var state = e.boggle else { return }

        if boggleRemainingSeconds(state: state, now: now) == 0 {
            state.isOver = true
            statusText = "Boggle round is over."
            e.boggle = state
            commit(envelope: e, summary: statusText)
            return
        }

        guard !state.isOver else {
            statusText = "Boggle round is over."
            return
        }

        let word = rawWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !word.isEmpty else {
            statusText = "Type a word first."
            return
        }
        guard word.count >= 3 else {
            statusText = "Use at least 3 letters."
            return
        }
        guard word.range(of: "^[a-z]+$", options: .regularExpression) != nil else {
            statusText = "Letters only."
            return
        }
        guard BoggleDictionary.words.contains(word) else {
            statusText = "Word not in dictionary."
            return
        }
        guard !state.foundWords.contains(word) else {
            statusText = "Already found."
            return
        }
        guard canTraceBoggleWord(word, board: state.board) else {
            statusText = "Word cannot be traced on this board."
            return
        }

        state.foundWords.append(word)
        state.score += boggleScore(for: word)
        statusText = "Accepted: \(word.uppercased())"

        e.boggle = state
        commit(envelope: e, summary: statusText)
    }

    func boggleEndIfNeeded(now: Date = Date()) {
        guard var e = envelope, e.game == .boggle, var state = e.boggle else { return }
        guard !state.isOver else { return }
        if boggleRemainingSeconds(state: state, now: now) == 0 {
            state.isOver = true
            e.boggle = state
            statusText = "Time up. Score: \(state.score)."
            commit(envelope: e, summary: statusText)
        }
    }

    func recordFlappyScore(_ score: Int) {
        guard var e = envelope, e.game == .flappyBird, var state = e.flappyBird else { return }

        state.lastScore = max(score, 0)
        state.bestScore = max(state.bestScore, state.lastScore, localFlappyBest)
        state.totalRuns += 1

        if state.bestScore > localFlappyBest {
            persistLocalFlappyBest(state.bestScore)
        }

        statusText = "Flappy run: \(state.lastScore). Best: \(state.bestScore)."
        e.flappyBird = state
        commit(envelope: e, summary: statusText)
    }

    func yahtzeeRoll() {
        guard var e = envelope, e.game == .yahtzee, var state = e.yahtzee else { return }
        guard !state.isOver else {
            statusText = "Game over. Start a new round."
            return
        }
        guard claimTurnOwnership(currentPlayer: state.currentPlayer, playerOneID: &state.playerOneID, playerTwoID: &state.playerTwoID) else {
            return
        }
        guard state.rollsRemaining > 0 else {
            statusText = "No rolls left. Pick a category."
            return
        }

        state.dice = rollYahtzeeDice(dice: state.dice, held: state.held)
        state.rollsRemaining -= 1

        e.yahtzee = state
        envelope = normalize(e)
        statusText = "Player \(state.currentPlayer) rolled. \(state.rollsRemaining) roll\(state.rollsRemaining == 1 ? "" : "s") left."
    }

    func yahtzeeToggleHold(at index: Int) {
        guard var e = envelope, e.game == .yahtzee, var state = e.yahtzee else { return }
        guard !state.isOver else { return }
        guard (0..<5).contains(index) else { return }
        guard claimTurnOwnership(currentPlayer: state.currentPlayer, playerOneID: &state.playerOneID, playerTwoID: &state.playerTwoID) else {
            return
        }
        guard state.rollsRemaining < 3 else {
            statusText = "Roll first, then hold dice."
            return
        }

        state.held[index].toggle()
        e.yahtzee = state
        envelope = e
        statusText = state.held[index] ? "Die \(index + 1) held." : "Die \(index + 1) released."
    }

    func yahtzeeSelectCategory(_ category: YahtzeeCategory) {
        guard var e = envelope, e.game == .yahtzee, var state = e.yahtzee else { return }
        guard !state.isOver else {
            statusText = "Game over. Start a new round."
            return
        }
        guard claimTurnOwnership(currentPlayer: state.currentPlayer, playerOneID: &state.playerOneID, playerTwoID: &state.playerTwoID) else {
            return
        }
        guard state.rollsRemaining < 3 else {
            statusText = "Roll before scoring a category."
            return
        }

        let key = category.rawValue
        if state.currentPlayer == 1 {
            guard state.playerOneScores[key] == nil else {
                statusText = "Category already used."
                return
            }
            state.playerOneScores[key] = scoreYahtzee(category: category, dice: state.dice)
        } else {
            guard state.playerTwoScores[key] == nil else {
                statusText = "Category already used."
                return
            }
            state.playerTwoScores[key] = scoreYahtzee(category: category, dice: state.dice)
        }

        let scored = state.currentPlayer == 1
            ? state.playerOneScores[key, default: 0]
            : state.playerTwoScores[key, default: 0]

        let maxCategories = YahtzeeCategory.allCases.count
        let finished = state.playerOneScores.count >= maxCategories && state.playerTwoScores.count >= maxCategories

        if finished {
            state.isOver = true
            let p1 = totalYahtzeeScore(state.playerOneScores)
            let p2 = totalYahtzeeScore(state.playerTwoScores)
            if p1 == p2 {
                state.winner = nil
                statusText = "Final: \(p1)-\(p2). Draw."
            } else {
                state.winner = p1 > p2 ? 1 : 2
                statusText = "Final: P1 \(p1) - P2 \(p2). Player \(state.winner ?? 0) wins."
            }
        } else {
            let previousPlayer = state.currentPlayer
            if previousPlayer == 2 {
                state.round += 1
            }
            state.currentPlayer = previousPlayer == 1 ? 2 : 1
            state.rollsRemaining = 3
            state.held = Array(repeating: false, count: 5)
            state.dice = Array(repeating: 1, count: 5)
            statusText = "Player \(previousPlayer) scored \(scored) in \(category.title). Player \(state.currentPlayer) turn."
        }

        e.yahtzee = state
        commit(envelope: e, summary: statusText, sendNow: false)
    }

    func publishPictionaryRound(prompt rawPrompt: String, strokes rawStrokes: [PictionaryStroke], drawingDurationMs: Int) {
        guard var e = envelope, e.game == .pictionary else { return }

        let prompt = normalizePictionaryGuess(rawPrompt)
        guard prompt.count >= 2 else {
            statusText = "Use a prompt with at least 2 letters."
            return
        }

        let strokes = sanitizePictionaryStrokes(rawStrokes)
        guard !strokes.isEmpty else {
            statusText = "Draw something before sending."
            return
        }

        let duration = max(drawingDurationMs, 800)
        let salt = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let promptHash = pictionaryPromptHash(prompt: prompt, salt: salt)

        var state = e.pictionary ?? PictionaryState.newRound(drawerID: currentPlayerID())
        state.phase = .guessing
        state.drawerID = currentPlayerID()
        state.promptSalt = salt
        state.promptHash = promptHash
        state.promptLength = prompt.count
        state.promptFirstLetter = String(prompt.prefix(1)).uppercased()
        state.strokes = strokes
        state.drawingDurationMs = duration
        state.totalGuessAttempts = 0
        state.correctResults = []
        state.lastGuessPreview = "Puzzle sent."
        state.publishedAt = Date().timeIntervalSince1970

        e.pictionary = state
        persistPictionaryPrompt(prompt, sessionID: e.sessionID)
        statusText = "Pictionary sent: \(state.promptLength)-letter word."
        commit(envelope: e, summary: statusText)
    }

    func submitPictionaryGuess(_ rawGuess: String, elapsedSeconds: TimeInterval) {
        guard var e = envelope, e.game == .pictionary, var state = e.pictionary else { return }
        guard state.phase == .guessing else {
            statusText = "The puzzle has not been sent yet."
            return
        }

        let playerID = currentPlayerID()
        guard state.drawerID != playerID else {
            statusText = "Drawer cannot submit guesses."
            return
        }

        let guess = normalizePictionaryGuess(rawGuess)
        guard !guess.isEmpty else {
            statusText = "Type a guess first."
            return
        }

        state.totalGuessAttempts += 1
        let hashed = pictionaryPromptHash(prompt: guess, salt: state.promptSalt)

        if hashed == state.promptHash {
            let elapsedMs = max(Int((elapsedSeconds * 1000).rounded()), 0)
            if let idx = state.correctResults.firstIndex(where: { $0.playerID == playerID }) {
                state.correctResults[idx].elapsedMs = min(state.correctResults[idx].elapsedMs, elapsedMs)
                state.correctResults[idx].guessedAt = Date().timeIntervalSince1970
                state.correctResults[idx].guess = guess
            } else {
                state.correctResults.append(
                    PictionaryResult(
                        playerID: playerID,
                        elapsedMs: elapsedMs,
                        guessedAt: Date().timeIntervalSince1970,
                        guess: guess
                    )
                )
            }

            state.correctResults.sort { lhs, rhs in
                if lhs.elapsedMs == rhs.elapsedMs {
                    return lhs.guessedAt < rhs.guessedAt
                }
                return lhs.elapsedMs < rhs.elapsedMs
            }

            let leader = state.correctResults.first
            let solved = formatMilliseconds(elapsedMs)
            if leader?.playerID == playerID {
                statusText = "\(playerLabel(playerID)) solved in \(solved) and is leading."
            } else if let leader {
                statusText = "\(playerLabel(playerID)) solved in \(solved). Leader: \(formatMilliseconds(leader.elapsedMs))."
            } else {
                statusText = "\(playerLabel(playerID)) solved in \(solved)."
            }
            state.lastGuessPreview = "\(playerLabel(playerID)) solved in \(solved)."
        } else {
            statusText = "\(playerLabel(playerID)) guessed \(guess.uppercased()): incorrect."
            state.lastGuessPreview = statusText
        }

        e.pictionary = state
        commit(envelope: e, summary: statusText)
    }

    func boggleRemainingSeconds(state: BoggleState, now: Date = Date()) -> Int {
        let elapsed = Int(now.timeIntervalSince1970 - state.roundStartedAt)
        return max(state.roundLength - elapsed, 0)
    }

    private func commit(envelope: ArcadeEnvelope, summary: String, sendNow: Bool = true) {
        var copy = normalize(envelope)
        copy.updatedAt = Date().timeIntervalSince1970
        copy.lastSummary = summary
        self.envelope = copy
        if sendNow {
            hasPendingTurnUpdate = false
            updateTurnHintAfterLocalSend(for: copy.game)
            sendCurrent(summary: summary)
        } else {
            hasPendingTurnUpdate = true
            if isTurnTrackedGame(copy.game) {
                turnHintText = "Turn ready. Tap gear and send turn."
            }
        }
    }

    private func sendCurrent(summary: String) {
        guard var envelope else { return }
        hasPendingTurnUpdate = false

        envelope.updatedAt = Date().timeIntervalSince1970
        envelope.lastSummary = summary
        envelope = normalize(envelope)
        self.envelope = envelope

        guard let payload = ArcadeCodec.encode(envelope) else {
            errorText = "Unable to encode game state."
            return
        }

        guard payload.utf8.count <= SendPolicy.maxPayloadBytes else {
            errorText = "Game update is too large to send. Start a new round to continue."
            return
        }

        guard let conversation else {
            errorText = "Open a conversation before sending game updates."
            return
        }

        let session = conversation.selectedMessage?.session ?? MSSession()
        let message = MSMessage(session: session)

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "payload", value: payload)
        ]

        guard let url = components.url else {
            errorText = "Could not prepare game message URL."
            return
        }

        guard url.absoluteString.utf8.count <= SendPolicy.maxURLBytes else {
            errorText = "Game update is too large to send. Start a new round to continue."
            return
        }

        message.url = url

        let layout = MSMessageTemplateLayout()
        layout.caption = envelope.game.title
        layout.subcaption = summary
        message.layout = layout

        insert(message: message, into: conversation, retriesRemaining: SendPolicy.retryAttempts)
    }

    private func insert(message: MSMessage, into conversation: MSConversation, retriesRemaining: Int) {
        conversation.insert(message) { [weak self] error in
            guard let self else { return }

            if let error {
                if retriesRemaining > 0 {
                    Task { @MainActor in
                        self.insert(message: message, into: conversation, retriesRemaining: retriesRemaining - 1)
                    }
                    return
                }

                Task { @MainActor in
                    self.errorText = "Could not send update: \(error.localizedDescription)"
                }
                return
            }

            Task { @MainActor in
                self.errorText = nil
            }
        }
    }

    private func normalize(_ envelope: ArcadeEnvelope) -> ArcadeEnvelope {
        var normalized = envelope
        normalized.schemaVersion = ArcadeEnvelope.currentSchemaVersion

        switch normalized.game {
        case .ticTacToe:
            var state = normalized.ticTacToe ?? .newRound()
            if state.playerOneID?.isEmpty == true { state.playerOneID = nil }
            if state.playerTwoID?.isEmpty == true { state.playerTwoID = nil }
            normalized.ticTacToe = state
        case .wordle:
            normalized.wordle = normalized.wordle ?? .newRound()
        case .flappyBird:
            var state = normalized.flappyBird ?? FlappyBirdState()
            state.bestScore = max(state.bestScore, localFlappyBest)
            normalized.flappyBird = state
        case .boggle:
            normalized.boggle = normalized.boggle ?? .newRound()
        case .connect4:
            var state = normalized.connect4 ?? .newRound()
            if state.playerOneID?.isEmpty == true { state.playerOneID = nil }
            if state.playerTwoID?.isEmpty == true { state.playerTwoID = nil }
            normalized.connect4 = state
        case .yahtzee:
            var state = normalized.yahtzee ?? .newRound()
            if state.dice.count != 5 {
                state.dice = Array(repeating: 1, count: 5)
            }
            if state.held.count != 5 {
                state.held = Array(repeating: false, count: 5)
            }
            if state.playerOneID?.isEmpty == true { state.playerOneID = nil }
            if state.playerTwoID?.isEmpty == true { state.playerTwoID = nil }
            normalized.yahtzee = state
        case .pictionary:
            var state = normalized.pictionary ?? .newRound(drawerID: currentPlayerID())
            if state.drawerID.isEmpty {
                state.drawerID = currentPlayerID()
            }
            state.correctResults.sort { lhs, rhs in
                if lhs.elapsedMs == rhs.elapsedMs {
                    return lhs.guessedAt < rhs.guessedAt
                }
                return lhs.elapsedMs < rhs.elapsedMs
            }
            normalized.pictionary = state
        }

        return normalized
    }

    private func extractPayload(from message: MSMessage) -> String? {
        guard let url = message.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        return components.queryItems?.first(where: { $0.name == "payload" })?.value
    }

    private func isTurnTrackedGame(_ game: ArcadeGame) -> Bool {
        switch game {
        case .ticTacToe, .connect4, .yahtzee:
            return true
        case .wordle, .flappyBird, .boggle, .pictionary:
            return false
        }
    }

    private func updateTurnHintAfterReceive(message: MSMessage, game: ArcadeGame) {
        guard isTurnTrackedGame(game) else {
            turnHintText = nil
            return
        }

        guard let conversation else {
            turnHintText = "Pass turns by sending each move."
            return
        }

        let local = conversation.localParticipantIdentifier
        let sender = message.senderParticipantIdentifier
        turnHintText = sender == local ? "Opponent's turn." : "Your turn."
    }

    private func updateTurnHintAfterLocalSend(for game: ArcadeGame) {
        guard isTurnTrackedGame(game) else {
            turnHintText = nil
            return
        }
        turnHintText = "Opponent's turn."
    }

    private func claimTurnOwnership(
        currentPlayer: Int,
        playerOneID: inout String?,
        playerTwoID: inout String?
    ) -> Bool {
        if canLocalAct(currentPlayer: currentPlayer, playerOneID: playerOneID, playerTwoID: playerTwoID) == false {
            return false
        }

        let local = currentPlayerID()
        switch currentPlayer {
        case 1:
            if playerOneID?.isEmpty ?? true {
                playerOneID = local
                return true
            }
            return playerOneID == local
        case 2:
            if playerTwoID?.isEmpty ?? true {
                if playerOneID == local {
                    return false
                }
                playerTwoID = local
                return true
            }
            return playerTwoID == local
        default:
            return false
        }
    }

    private func canLocalAct(currentPlayer: Int, playerOneID: String?, playerTwoID: String?) -> Bool {
        let local = currentPlayerID()
        switch currentPlayer {
        case 1:
            return playerOneID == nil || playerOneID?.isEmpty == true || playerOneID == local
        case 2:
            if playerTwoID == nil || playerTwoID?.isEmpty == true {
                return playerOneID != local
            }
            return playerTwoID == local
        default:
            return false
        }
    }

    private func persistLastPlayedGame(_ game: ArcadeGame) {
        defaults.set(game.rawValue, forKey: DefaultsKey.lastPlayedGame)
        lastPlayedGame = game
    }

    private func persistLocalFlappyBest(_ best: Int) {
        defaults.set(best, forKey: DefaultsKey.localFlappyBest)
        localFlappyBest = best
    }

    private func sanitizePictionaryStrokes(_ strokes: [PictionaryStroke]) -> [PictionaryStroke] {
        let maxStrokes = 20
        let maxPoints = 220
        var remaining = maxPoints
        var cleaned: [PictionaryStroke] = []

        for stroke in strokes.prefix(maxStrokes) {
            guard remaining > 0 else { break }
            let points = stroke.points.prefix(remaining)
            guard !points.isEmpty else { continue }
            cleaned.append(PictionaryStroke(points: Array(points)))
            remaining -= points.count
        }

        return cleaned
    }

    private func formatMilliseconds(_ value: Int) -> String {
        let ms = max(value, 0)
        return String(format: "%.2fs", Double(ms) / 1000.0)
    }

    private func playerLabel(_ playerID: String) -> String {
        let short = String(playerID.suffix(4)).uppercased()
        return "Player \(short)"
    }

    private func persistPictionaryPrompt(_ prompt: String, sessionID: String) {
        defaults.set(prompt, forKey: pictionaryPromptKey(sessionID: sessionID))
    }

    private func pictionaryPromptKey(sessionID: String) -> String {
        "\(DefaultsKey.pictionaryPromptPrefix)\(sessionID)"
    }
}
