import SwiftUI

struct TicTacToeGameView: View {
    let state: TicTacToeState
    let tap: (Int) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(statusLine)
                .font(.headline)
                .foregroundStyle(.black.opacity(0.7))
                .accessibilityLabel("Game status")
                .accessibilityValue(statusLine)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(72), spacing: 8), count: 3), spacing: 8) {
                ForEach(0..<9, id: \.self) { index in
                    Button {
                        tap(index)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#E9F0FF"))
                                .frame(width: 72, height: 72)
                            Text(symbol(for: state.board[index]))
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color(hex: "#1E3A8A"))
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(state.board[index] != 0 || state.winner != nil || state.isDraw)
                    .accessibilityLabel(cellLabel(for: index))
                    .accessibilityHint("Double tap to place your mark")
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var statusLine: String {
        if let winner = state.winner {
            return winner == 1 ? "Player X wins" : "Player O wins"
        }
        if state.isDraw {
            return "Draw"
        }
        return state.currentPlayer == 1 ? "Player X turn" : "Player O turn"
    }

    private func symbol(for value: Int) -> String {
        switch value {
        case 1: return "X"
        case 2: return "O"
        default: return ""
        }
    }

    private func cellLabel(for index: Int) -> String {
        let row = (index / 3) + 1
        let column = (index % 3) + 1

        switch state.board[index] {
        case 1:
            return "Row \(row), column \(column), X"
        case 2:
            return "Row \(row), column \(column), O"
        default:
            return "Row \(row), column \(column), empty"
        }
    }
}
