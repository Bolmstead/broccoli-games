import SwiftUI

struct YahtzeeGameView: View {
    let state: YahtzeeState
    let isLocalTurn: Bool
    let roll: () -> Void
    let toggleHold: (Int) -> Void
    let selectCategory: (YahtzeeCategory) -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(state.isOver ? "Final Scores" : "Round \(state.round) of \(YahtzeeCategory.allCases.count)")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.black.opacity(0.8))
                Spacer()
                Text(state.isOver ? "Game Over" : "P\(state.currentPlayer) turn")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#FEF3C7"), in: Capsule())
                    .foregroundStyle(Color(hex: "#92400E"))
            }

            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    Button {
                        toggleHold(index)
                    } label: {
                        VStack(spacing: 4) {
                            Text(dieFace(state.dice[index]))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            Text(state.held[index] ? "HOLD" : "ROLL")
                                .font(.caption2.weight(.black))
                        }
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .background(
                            state.held[index] ? Color(hex: "#FDE68A") : Color(hex: "#E2E8F0"),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .foregroundStyle(.black.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .disabled(state.isOver || state.rollsRemaining == 3 || !isLocalTurn)
                }
            }

            Button {
                roll()
            } label: {
                Text(state.rollsRemaining > 0 ? "Roll Dice (\(state.rollsRemaining) left)" : "Pick a Category")
                    .font(.subheadline.weight(.heavy))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                        state.rollsRemaining > 0 && !state.isOver ? Color(hex: "#2563EB") : Color(hex: "#94A3B8"),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(state.isOver || state.rollsRemaining == 0 || !isLocalTurn)

            HStack {
                Text("P1: \(totalYahtzeeScore(state.playerOneScores))")
                Spacer()
                Text("P2: \(totalYahtzeeScore(state.playerTwoScores))")
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.black.opacity(0.7))

            ScrollView {
                VStack(spacing: 6) {
                    HStack {
                        Text("Category")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("P1")
                            .frame(width: 34)
                        Text("P2")
                            .frame(width: 34)
                        Text("Action")
                            .frame(width: 78)
                    }
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.6))

                    ForEach(YahtzeeCategory.allCases) { category in
                        row(for: category)
                    }
                }
            }

            if state.isOver {
                Text(winnerText)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color(hex: "#065F46"))
                    .padding(.vertical, 6)
            }
        }
    }

    @ViewBuilder
    private func row(for category: YahtzeeCategory) -> some View {
        let p1 = state.playerOneScores[category.rawValue]
        let p2 = state.playerTwoScores[category.rawValue]
        let activeScores = state.currentPlayer == 1 ? state.playerOneScores : state.playerTwoScores
        let alreadyScored = activeScores[category.rawValue] != nil
        let preview = scoreYahtzee(category: category, dice: state.dice)
        let canChoose = !state.isOver && state.rollsRemaining < 3 && !alreadyScored && isLocalTurn

        HStack(spacing: 8) {
            Text(category.title)
                .font(.footnote.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.black.opacity(0.8))

            Text(p1.map(String.init) ?? "-")
                .font(.footnote.weight(.heavy))
                .frame(width: 34)
                .foregroundStyle(.black.opacity(0.75))

            Text(p2.map(String.init) ?? "-")
                .font(.footnote.weight(.heavy))
                .frame(width: 34)
                .foregroundStyle(.black.opacity(0.75))

            Button {
                selectCategory(category)
            } label: {
                Text(canChoose ? "\(preview)" : (alreadyScored ? "Done" : "--"))
                    .font(.caption.weight(.black))
                    .frame(width: 78, height: 28)
                    .background(canChoose ? Color(hex: "#D1FAE5") : Color(hex: "#E2E8F0"), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(canChoose ? Color(hex: "#065F46") : Color(hex: "#64748B"))
            }
            .buttonStyle(.plain)
            .disabled(!canChoose)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(hex: "#F8FAFC"), in: RoundedRectangle(cornerRadius: 8))
    }

    private var winnerText: String {
        let p1 = totalYahtzeeScore(state.playerOneScores)
        let p2 = totalYahtzeeScore(state.playerTwoScores)
        if let winner = state.winner {
            return "Player \(winner) wins: \(winner == 1 ? p1 : p2) points"
        }
        return "Draw game: \(p1)-\(p2)"
    }

    private func dieFace(_ value: Int) -> String {
        switch value {
        case 1: return "⚀"
        case 2: return "⚁"
        case 3: return "⚂"
        case 4: return "⚃"
        case 5: return "⚄"
        case 6: return "⚅"
        default: return "•"
        }
    }
}
