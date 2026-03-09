import XCTest

final class ArcadeGameLogicTests: XCTestCase {
    func testTicTacToeWinnerDetectsRowWin() {
        let board = [1, 1, 1,
                     0, 2, 0,
                     2, 0, 0]

        XCTAssertEqual(winnerForTicTacToe(board: board), 1)
    }

    func testTicTacToeWinnerReturnsNilForNoWinner() {
        let board = [1, 2, 1,
                     1, 2, 2,
                     2, 1, 2]

        XCTAssertNil(winnerForTicTacToe(board: board))
    }

    func testConnect4NextOpenRowFindsLowestSlot() {
        var board = Array(repeating: 0, count: 42)
        board[5 * 7 + 3] = 1
        board[4 * 7 + 3] = 2

        XCTAssertEqual(nextOpenConnect4Row(board: board, column: 3), 3)
    }

    func testConnect4WinDetectsVerticalWin() {
        var board = Array(repeating: 0, count: 42)
        for row in 2...5 {
            board[row * 7 + 4] = 1
        }

        XCTAssertTrue(checkConnect4Win(board: board, row: 2, col: 4, player: 1))
    }

    func testWordleEvaluationHandlesDuplicateLetters() {
        let evaluation = evaluateWordle(guess: "allay", target: "alpha")

        XCTAssertEqual(evaluation, [2, 2, 0, 1, 0])
    }

    func testBoggleScoreRules() {
        XCTAssertEqual(boggleScore(for: "cat"), 1)
        XCTAssertEqual(boggleScore(for: "frost"), 2)
        XCTAssertEqual(boggleScore(for: "planet"), 3)
        XCTAssertEqual(boggleScore(for: "capital"), 5)
        XCTAssertEqual(boggleScore(for: "elephant"), 11)
    }

    func testBoggleTracingSupportsQuTile() {
        let board = [
            "qu", "i", "t", "e",
            "a", "r", "s", "n",
            "l", "m", "o", "d",
            "p", "h", "b", "c"
        ]

        XCTAssertTrue(canTraceBoggleWord("quit", board: board))
        XCTAssertFalse(canTraceBoggleWord("qat", board: board))
    }

    func testPictionaryGuessNormalizationCollapsesWhitespace() {
        XCTAssertEqual(normalizePictionaryGuess("  New   York  "), "new york")
        XCTAssertEqual(normalizePictionaryGuess("DOG"), "dog")
    }

    func testPictionaryHashMatchesEquivalentWhitespace() {
        let salt = "abc123"
        let first = pictionaryPromptHash(prompt: "new york", salt: salt)
        let second = pictionaryPromptHash(prompt: "  new   york ", salt: salt)
        XCTAssertEqual(first, second)
    }

    func testYahtzeeScoresUpperSection() {
        let dice = [1, 1, 3, 6, 6]
        XCTAssertEqual(scoreYahtzee(category: .ones, dice: dice), 2)
        XCTAssertEqual(scoreYahtzee(category: .sixes, dice: dice), 12)
    }

    func testYahtzeeComboScoring() {
        XCTAssertEqual(scoreYahtzee(category: .threeOfKind, dice: [2, 2, 2, 5, 6]), 17)
        XCTAssertEqual(scoreYahtzee(category: .fourOfKind, dice: [2, 2, 2, 5, 6]), 0)
        XCTAssertEqual(scoreYahtzee(category: .fullHouse, dice: [3, 3, 2, 2, 2]), 25)
        XCTAssertEqual(scoreYahtzee(category: .smallStraight, dice: [1, 2, 3, 4, 6]), 30)
        XCTAssertEqual(scoreYahtzee(category: .largeStraight, dice: [2, 3, 4, 5, 6]), 40)
        XCTAssertEqual(scoreYahtzee(category: .yahtzee, dice: [4, 4, 4, 4, 4]), 50)
        XCTAssertEqual(scoreYahtzee(category: .chance, dice: [4, 4, 4, 4, 4]), 20)
    }
}
