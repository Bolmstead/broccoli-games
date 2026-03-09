import Foundation
import SwiftUI

struct ArcadeRootView: View {
    @ObservedObject var coordinator: MessagesCoordinator
    @AppStorage("arcade.showTips") private var showTips = true

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#081B44"), Color(hex: "#174172")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                header

                if let envelope = coordinator.envelope {
                    gameScreen(for: envelope)
                } else {
                    lobby
                }
            }
            .padding(12)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BROCCOLI GAMES")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.75))
                        .accessibilityHidden(true)
                    Text("iMessage Arcade")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(.white)
                }
                Spacer()
                if coordinator.envelope != nil {
                    Button("Lobby") {
                        coordinator.returnToLobby()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.22))
                    .accessibilityHint("Return to game list")
                }
            }

            Text(coordinator.statusText)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("Status")
                .accessibilityValue(coordinator.statusText)

            if let turnHintText = coordinator.turnHintText {
                Text(turnHintText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Turn")
                    .accessibilityValue(turnHintText)
            }

            if let errorText = coordinator.errorText {
                Text(errorText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red.opacity(0.95))
                    .accessibilityLabel("Error")
                    .accessibilityValue(errorText)
            }
        }
    }

    private var lobby: some View {
        ScrollView {
            VStack(spacing: 10) {
                if let lastPlayed = coordinator.lastPlayedGame {
                    Button {
                        coordinator.startLastPlayedGame()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Resume Last")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.82))
                                Text(lastPlayed.title)
                                    .font(.title3.weight(.heavy))
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            Image(systemName: "play.fill")
                                .foregroundStyle(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Resume last game, \(lastPlayed.title)")
                }

                Text("Choose a game, send it to chat, and take turns by opening the latest message.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                ForEach(ArcadeGame.allCases) { game in
                    Button {
                        coordinator.startGame(game)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(game.title)
                                    .font(.title3.weight(.heavy))
                                    .foregroundStyle(.white)
                                Text(game.subtitle)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.86))
                            }
                            Spacer()
                            Image(systemName: "paperplane.fill")
                                .font(.title3.weight(.heavy))
                                .foregroundStyle(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: game.accentHex).opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Start \(game.title)")
                    .accessibilityHint("Sends a new round to the current chat")
                }
            }
        }
    }

    @ViewBuilder
    private func gameScreen(for envelope: ArcadeEnvelope) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(envelope.game.title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.white)
                Spacer()
                Button(showTips ? "Hide Tips" : "Show Tips") {
                    showTips.toggle()
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.2))

                Button("New Round") {
                    coordinator.resetCurrentGame()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: envelope.game.accentHex))
            }

            if showTips {
                Text(helpText(for: envelope.game))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("How to play")
            }

            Group {
                switch envelope.game {
                case .ticTacToe:
                    TicTacToeGameView(state: envelope.ticTacToe ?? .newRound()) { index in
                        coordinator.playTicTacToe(at: index)
                    }
                case .wordle:
                    WordleGameView(
                        state: envelope.wordle ?? .newRound(),
                        addLetter: { coordinator.wordleAddLetter($0) },
                        backspace: { coordinator.wordleBackspace() },
                        submit: { coordinator.wordleSubmitGuess() }
                    )
                case .flappyBird:
                    FlappyBirdGameView(
                        globalState: envelope.flappyBird ?? FlappyBirdState(),
                        localBest: coordinator.localFlappyBest
                    ) { score in
                        coordinator.recordFlappyScore(score)
                    }
                case .boggle:
                    BoggleGameView(
                        state: envelope.boggle ?? .newRound(),
                        submitWord: { coordinator.boggleSubmit(word: $0) },
                        tick: { coordinator.boggleEndIfNeeded() }
                    )
                case .connect4:
                    Connect4GameView(state: envelope.connect4 ?? .newRound()) { column in
                        coordinator.dropConnect4(column: column)
                    }
                case .pictionary:
                    let state = envelope.pictionary ?? .newRound(drawerID: coordinator.currentPlayerID())
                    PictionaryGameView(
                        state: state,
                        isDrawer: coordinator.isLocalPlayerDrawer(for: state),
                        localPlayerID: coordinator.currentPlayerID(),
                        revealedPrompt: coordinator.localPictionaryPrompt(for: envelope.sessionID),
                        publishRound: { prompt, strokes, durationMs in
                            coordinator.publishPictionaryRound(
                                prompt: prompt,
                                strokes: strokes,
                                drawingDurationMs: durationMs
                            )
                        },
                        submitGuess: { guess, elapsedSeconds in
                            coordinator.submitPictionaryGuess(guess, elapsedSeconds: elapsedSeconds)
                        }
                    )
                }
            }
            .padding(10)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func helpText(for game: ArcadeGame) -> String {
        switch game {
        case .ticTacToe:
            return "Tap a square to place your mark. Send each move in chat to pass the turn."
        case .wordle:
            return "Guess the 5-letter word in 6 tries. Green is correct, yellow is in the word."
        case .flappyBird:
            return "Tap Flap or the game field to keep flying. Your best score is saved locally."
        case .boggle:
            return "Find words of 3+ letters before time runs out. Q tiles count as QU."
        case .connect4:
            return "Drop chips into columns and connect 4 in any direction. Send each move in chat."
        case .pictionary:
            return "Drawer sketches and sends. Everyone watches replay, guesses in chat, and fastest correct time leads."
        }
    }
}
