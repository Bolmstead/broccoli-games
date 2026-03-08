import SwiftUI

struct Connect4GameView: View {
    let state: Connect4State
    let drop: (Int) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(statusLine)
                .font(.headline)
                .foregroundStyle(.black.opacity(0.7))
                .accessibilityLabel("Game status")
                .accessibilityValue(statusLine)

            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { column in
                    Button("Drop") {
                        drop(column)
                    }
                    .font(.caption.weight(.black))
                    .frame(width: 42, height: 44)
                    .background(Color(hex: "#1D4ED8"), in: RoundedRectangle(cornerRadius: 6))
                    .foregroundStyle(.white)
                    .disabled(state.winner != nil || state.isDraw || topCellFilled(column))
                    .accessibilityLabel("Drop in column \(column + 1)")
                }
            }

            VStack(spacing: 4) {
                ForEach(0..<6, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { col in
                            Circle()
                                .fill(chipColor(for: state.board[row * 7 + col]))
                                .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
                                .frame(width: 34, height: 34)
                                .accessibilityLabel("Row \(row + 1), column \(col + 1), \(chipLabel(for: state.board[row * 7 + col]))")
                        }
                    }
                }
            }
            .padding(8)
            .background(Color(hex: "#1E40AF"), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var statusLine: String {
        if let winner = state.winner {
            return winner == 1 ? "Red wins" : "Yellow wins"
        }
        if state.isDraw {
            return "Draw"
        }
        return state.currentPlayer == 1 ? "Red turn" : "Yellow turn"
    }

    private func chipColor(for value: Int) -> Color {
        switch value {
        case 1: return Color(hex: "#EF4444")
        case 2: return Color(hex: "#FACC15")
        default: return Color(hex: "#E2E8F0")
        }
    }

    private func chipLabel(for value: Int) -> String {
        switch value {
        case 1: return "red chip"
        case 2: return "yellow chip"
        default: return "empty"
        }
    }

    private func topCellFilled(_ column: Int) -> Bool {
        state.board[column] != 0
    }
}
