import Foundation

func winnerForTicTacToe(board: [Int]) -> Int? {
    guard board.count == 9 else { return nil }

    let lines = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6]
    ]

    for line in lines {
        let a = line[0], b = line[1], c = line[2]
        if board[a] != 0, board[a] == board[b], board[b] == board[c] {
            return board[a]
        }
    }
    return nil
}

func nextOpenConnect4Row(board: [Int], column: Int) -> Int {
    guard board.count == 42, (0..<7).contains(column) else { return -1 }

    for row in stride(from: 5, through: 0, by: -1) {
        if board[row * 7 + column] == 0 {
            return row
        }
    }
    return -1
}

func checkConnect4Win(board: [Int], row: Int, col: Int, player: Int) -> Bool {
    guard board.count == 42 else { return false }
    guard (0..<6).contains(row), (0..<7).contains(col), player != 0 else { return false }

    let directions = [
        (0, 1), (1, 0), (1, 1), (1, -1)
    ]

    for (dr, dc) in directions {
        var count = 1

        var r = row + dr
        var c = col + dc
        while r >= 0, r < 6, c >= 0, c < 7, board[r * 7 + c] == player {
            count += 1
            r += dr
            c += dc
        }

        r = row - dr
        c = col - dc
        while r >= 0, r < 6, c >= 0, c < 7, board[r * 7 + c] == player {
            count += 1
            r -= dr
            c -= dc
        }

        if count >= 4 {
            return true
        }
    }

    return false
}

func evaluateWordle(guess: String, target: String) -> [Int] {
    let guessChars = Array(guess)
    let targetChars = Array(target)
    guard guessChars.count == 5, targetChars.count == 5 else {
        return []
    }

    var result = Array(repeating: 0, count: 5)
    var used = Array(repeating: false, count: 5)

    for index in 0..<5 {
        if guessChars[index] == targetChars[index] {
            result[index] = 2
            used[index] = true
        }
    }

    for i in 0..<5 where result[i] == 0 {
        for j in 0..<5 where !used[j] {
            if guessChars[i] == targetChars[j] {
                result[i] = 1
                used[j] = true
                break
            }
        }
    }

    return result
}

func boggleScore(for word: String) -> Int {
    switch word.count {
    case 0...2: return 0
    case 3, 4: return 1
    case 5: return 2
    case 6: return 3
    case 7: return 5
    default: return 11
    }
}

func canTraceBoggleWord(_ word: String, board: [String]) -> Bool {
    let normalizedWord = word.lowercased()
    guard normalizedWord.count >= 3, board.count == 16 else {
        return false
    }
    guard normalizedWord.range(of: "^[a-z]+$", options: .regularExpression) != nil else {
        return false
    }

    let size = 4
    let normalizedBoard = board.map { $0.lowercased() }
    var visited = Array(repeating: Array(repeating: false, count: size), count: size)

    func dfs(_ row: Int, _ col: Int, _ index: String.Index) -> Bool {
        let tile = normalizedBoard[row * size + col]
        guard !tile.isEmpty, normalizedWord[index...].hasPrefix(tile) else {
            return false
        }

        let nextIndex = normalizedWord.index(index, offsetBy: tile.count)
        if nextIndex == normalizedWord.endIndex {
            return true
        }

        visited[row][col] = true

        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 {
                    continue
                }
                let nr = row + dr
                let nc = col + dc
                if nr < 0 || nr >= size || nc < 0 || nc >= size || visited[nr][nc] {
                    continue
                }
                if dfs(nr, nc, nextIndex) {
                    visited[row][col] = false
                    return true
                }
            }
        }

        visited[row][col] = false
        return false
    }

    for row in 0..<size {
        for col in 0..<size {
            if dfs(row, col, normalizedWord.startIndex) {
                return true
            }
        }
    }

    return false
}
