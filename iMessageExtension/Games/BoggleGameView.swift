import Foundation
import SwiftUI

struct BoggleGameView: View {
    let state: BoggleState
    let submitWord: (String) -> Void
    let tick: () -> Void

    @State private var candidate = ""
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Time: \(remaining)s")
                Spacer()
                Text("Score: \(state.score)")
            }
            .font(.headline)
            .foregroundStyle(.black.opacity(0.7))
            .accessibilityLabel("Time \(remaining) seconds, score \(state.score)")

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(56), spacing: 6), count: 4), spacing: 6) {
                ForEach(0..<16, id: \.self) { idx in
                    Text(displayTile(state.board[idx]))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .frame(width: 56, height: 56)
                        .background(Color(hex: "#E0E7FF"), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(Color(hex: "#1E3A8A"))
                        .accessibilityLabel(tileAccessibility(at: idx))
                }
            }

            HStack(spacing: 8) {
                TextField("Type word", text: $candidate)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 10)
                    .frame(minHeight: 44)
                    .background(Color(hex: "#E2E8F0"), in: RoundedRectangle(cornerRadius: 8))
                    .disabled(state.isOver || remaining == 0)

                Button("Add") {
                    let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    submitWord(trimmed)
                    candidate = ""
                }
                .font(.subheadline.weight(.heavy))
                .frame(width: 64, height: 44)
                .background(Color(hex: "#2563EB"), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
                .disabled(state.isOver || remaining == 0)
                .accessibilityHint("Submit typed word")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(state.foundWords.sorted(), id: \.self) { word in
                        Text("\(word.uppercased()) +\(boggleScore(for: word))")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(hex: "#DBEAFE"), in: Capsule())
                            .accessibilityLabel("\(word), \(boggleScore(for: word)) points")
                    }
                }
            }

            if state.isOver || remaining == 0 {
                Text("Round complete")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color(hex: "#DC2626"))
            }
        }
        .onReceive(timer) { _ in
            now = Date()
            tick()
        }
    }

    private var remaining: Int {
        let elapsed = Int(now.timeIntervalSince1970 - state.roundStartedAt)
        return max(state.roundLength - elapsed, 0)
    }

    private func displayTile(_ tile: String) -> String {
        tile == "qu" ? "Qu" : tile.uppercased()
    }

    private func tileAccessibility(at index: Int) -> String {
        let row = (index / 4) + 1
        let col = (index % 4) + 1
        return "Row \(row), column \(col), \(displayTile(state.board[index]))"
    }
}
