import Foundation
import SwiftUI

struct ArcadeRootView: View {
    @ObservedObject var coordinator: MessagesCoordinator
    @AppStorage("arcade.showTips") private var showTips = true

    private let lobbyColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#090A0F"), Color(hex: "#171A23")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if let envelope = coordinator.envelope {
                VStack(spacing: 10) {
                    activeHeader
                    gameScreen(for: envelope)
                }
                .padding(10)
            } else {
                compactLobby
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
            }
        }
    }

    private var compactLobby: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "#16A34A"), Color(hex: "#84CC16")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 34, height: 34)
                    .overlay(Text("🥦").font(.system(size: 18)))

                Text("Games")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.white)

                Divider()
                    .frame(height: 20)
                    .overlay(Color.white.opacity(0.28))

                Text("Settings")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))

                Divider()
                    .frame(height: 20)
                    .overlay(Color.white.opacity(0.28))

                Text("Store")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

            if let errorText = coordinator.errorText {
                Text(errorText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red.opacity(0.95))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ScrollView {
                LazyVGrid(columns: lobbyColumns, spacing: 10) {
                    ForEach(ArcadeGame.allCases) { game in
                        Button {
                            coordinator.startGame(game)
                        } label: {
                            VStack(spacing: 6) {
                                ZStack(alignment: .topTrailing) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(LinearGradient(
                                            colors: [Color(hex: game.accentHex).opacity(0.95), Color(hex: game.accentHex).opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(height: 62)
                                        .overlay(
                                            Image(systemName: iconName(for: game))
                                                .font(.system(size: 25, weight: .black))
                                                .foregroundStyle(.white)
                                        )

                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 10, weight: .heavy))
                                        .foregroundStyle(Color(hex: "#FACC15"))
                                        .padding(5)
                                }

                                Text(compactTitle(for: game))
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Start \(game.title)")
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    private var activeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Broccoli Games")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                Spacer()
                Button("Lobby") {
                    coordinator.returnToLobby()
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.22))
            }

            Text(coordinator.statusText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))

            if let turnHintText = coordinator.turnHintText {
                Text(turnHintText)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
            }

            if let errorText = coordinator.errorText {
                Text(errorText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red.opacity(0.95))
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

    private func compactTitle(for game: ArcadeGame) -> String {
        switch game {
        case .ticTacToe: return "TIC TAC"
        case .wordle: return "WORDLE"
        case .flappyBird: return "FLAPPY"
        case .boggle: return "BOGGLE"
        case .connect4: return "CONNECT 4"
        case .pictionary: return "PICTIONARY"
        }
    }

    private func iconName(for game: ArcadeGame) -> String {
        switch game {
        case .ticTacToe: return "grid"
        case .wordle: return "textformat.abc"
        case .flappyBird: return "bird.fill"
        case .boggle: return "character.book.closed.fill"
        case .connect4: return "circle.grid.3x3.fill"
        case .pictionary: return "pencil.and.scribble"
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
