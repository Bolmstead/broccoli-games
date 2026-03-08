import SwiftUI

struct WordleGameView: View {
    let state: WordleState
    let addLetter: (String) -> Void
    let backspace: () -> Void
    let submit: () -> Void

    private let keyboardRows: [String] = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]

    var body: some View {
        VStack(spacing: 10) {
            Text(headline)
                .font(.headline)
                .foregroundStyle(.black.opacity(0.7))
                .accessibilityLabel("Game status")
                .accessibilityValue(headline)

            VStack(spacing: 6) {
                ForEach(0..<6, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { col in
                            let tile = tileData(row: row, col: col)
                            Text(tile.letter)
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .frame(width: 42, height: 42)
                                .background(tile.color, in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(tile.textColor)
                                .accessibilityLabel(tile.accessibility)
                        }
                    }
                }
            }

            VStack(spacing: 6) {
                ForEach(keyboardRows, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(Array(row), id: \.self) { ch in
                            let letter = String(ch)
                            Button(letter) {
                                addLetter(letter)
                            }
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .frame(width: 30, height: 44)
                            .background(keyColor(letter), in: RoundedRectangle(cornerRadius: 7))
                            .foregroundStyle(.white)
                            .disabled(state.isOver)
                            .accessibilityLabel("Letter \(letter)")
                        }
                    }
                }

                HStack(spacing: 8) {
                    Button("Enter") { submit() }
                        .font(.subheadline.weight(.heavy))
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(Color(hex: "#2563EB"), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                        .disabled(state.isOver)
                        .accessibilityHint("Submit current guess")

                    Button("Delete") { backspace() }
                        .font(.subheadline.weight(.heavy))
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(Color(hex: "#475569"), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                        .disabled(state.isOver)
                        .accessibilityHint("Remove last letter")
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var headline: String {
        if state.isOver {
            if state.didWin {
                return "Solved in \(state.guesses.count)/6"
            }
            return "Word was \(state.targetWord.uppercased())"
        }
        return "Guess \(state.guesses.count + 1) of 6"
    }

    private func tileData(row: Int, col: Int) -> (letter: String, color: Color, textColor: Color, accessibility: String) {
        if row < state.guesses.count {
            let guessChars = Array(state.guesses[row].uppercased())
            let eval = state.evaluations[row][col]
            let letter = String(guessChars[col])
            switch eval {
            case 2:
                return (letter, Color(hex: "#22C55E"), .white, "\(letter), correct")
            case 1:
                return (letter, Color(hex: "#CA8A04"), .white, "\(letter), in word")
            default:
                return (letter, Color(hex: "#64748B"), .white, "\(letter), not in word")
            }
        }

        if row == state.guesses.count {
            let chars = Array(state.currentGuess.uppercased())
            let letter = col < chars.count ? String(chars[col]) : ""
            let accessibility = letter.isEmpty ? "Empty tile" : "\(letter), current guess"
            return (letter, Color(hex: "#E2E8F0"), .black, accessibility)
        }

        return ("", Color(hex: "#F1F5F9"), .black, "Empty tile")
    }

    private func keyColor(_ letter: String) -> Color {
        var best = 0

        for (rowIndex, guess) in state.guesses.enumerated() {
            let chars = Array(guess.uppercased())
            for col in 0..<5 where String(chars[col]) == letter {
                best = max(best, state.evaluations[rowIndex][col])
            }
        }

        switch best {
        case 2: return Color(hex: "#22C55E")
        case 1: return Color(hex: "#CA8A04")
        default: return Color(hex: "#94A3B8")
        }
    }
}
