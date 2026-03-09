import Foundation
import SwiftUI

struct ArcadeRootView: View {
    @ObservedObject var coordinator: MessagesCoordinator

    private let lobbyColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    @State private var showGameMenu = false
    @State private var showInfoSheet = false

    var body: some View {
        ZStack {
            if let envelope = coordinator.envelope {
                expandedGame(envelope)
            } else {
                compactLobby
            }
        }
    }

    private var compactLobby: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#090A0F"), Color(hex: "#171A23")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

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
                        ForEach(ArcadeGame.playableOptions) { game in
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
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        }
    }

    private func expandedGame(_ envelope: ArcadeEnvelope) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#D1D5DB"), Color(hex: "#E5E7EB")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Group {
                switch envelope.game {
                case .ticTacToe:
                    let state = envelope.ticTacToe ?? .newRound()
                    TicTacToeGameView(state: state, isLocalTurn: coordinator.isLocalTurnForTicTacToe(state)) { index in
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
                    let state = envelope.connect4 ?? .newRound()
                    Connect4GameView(state: state, isLocalTurn: coordinator.isLocalTurnForConnect4(state)) { column in
                        coordinator.dropConnect4(column: column)
                    }
                case .yahtzee:
                    let state = envelope.yahtzee ?? .newRound()
                    YahtzeeGameView(state: state, isLocalTurn: coordinator.isLocalTurnForYahtzee(state)) {
                        coordinator.yahtzeeRoll()
                    } toggleHold: { index in
                        coordinator.yahtzeeToggleHold(at: index)
                    } selectCategory: { category in
                        coordinator.yahtzeeSelectCategory(category)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 66)

            VStack {
                Spacer()
                HStack {
                    Button {
                        showGameMenu = true
                    } label: {
                        Circle()
                            .fill(.white.opacity(0.85))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(Color(hex: "#6B7280"))
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        showInfoSheet = true
                    } label: {
                        Circle()
                            .fill(.white.opacity(0.85))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "questionmark")
                                    .font(.system(size: 22, weight: .black))
                                    .foregroundStyle(Color(hex: "#6B7280"))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
        .confirmationDialog("Game", isPresented: $showGameMenu, titleVisibility: .hidden) {
            if coordinator.hasPendingTurnUpdate {
                Button("Send Turn") { coordinator.sendPendingTurnUpdate() }
            }
            Button("New Round") { coordinator.resetCurrentGame() }
            Button("Lobby") { coordinator.returnToLobby() }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showInfoSheet) {
            VStack(alignment: .leading, spacing: 12) {
                Text(envelope.game.title)
                    .font(.title2.weight(.heavy))
                Text(helpText(for: envelope.game))
                    .font(.body)
                Spacer()
            }
            .padding(20)
            .presentationDetents([.height(230)])
        }
    }

    private func compactTitle(for game: ArcadeGame) -> String {
        switch game {
        case .ticTacToe: return "TIC TAC"
        case .wordle: return "WORDLE"
        case .flappyBird: return "FLAPPY"
        case .boggle: return "BOGGLE"
        case .connect4: return "CONNECT 4"
        case .yahtzee: return "YAHTZEE"
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
        case .yahtzee: return "die.face.5.fill"
        case .pictionary: return "pencil.and.scribble"
        }
    }

    private func helpText(for game: ArcadeGame) -> String {
        switch game {
        case .ticTacToe:
            return "Tap a square to place your mark. Send each move in chat to pass turns."
        case .wordle:
            return "Guess the 5-letter word in 6 tries. Green is correct, yellow is in the word."
        case .flappyBird:
            return "Tap Flap or game field to keep flying. Avoid pipes and beat your best score."
        case .boggle:
            return "Find words of 3+ letters before time runs out. Q tiles count as QU."
        case .connect4:
            return "Drop chips into columns and connect 4 in any direction."
        case .yahtzee:
            return "Roll up to 3 times, hold dice, then score one category each turn. Highest total wins."
        case .pictionary:
            return "Drawer enters a word, waits for countdown, draws, and sends. Others replay and guess for fastest time."
        }
    }
}
