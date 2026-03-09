import Foundation

enum ArcadeGame: String, CaseIterable, Codable, Identifiable {
    case ticTacToe
    case wordle
    case flappyBird
    case boggle
    case connect4
    case pictionary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ticTacToe: return "Tic Tac Toe"
        case .wordle: return "Wordle"
        case .flappyBird: return "Flappy Bird"
        case .boggle: return "Boggle"
        case .connect4: return "Connect 4"
        case .pictionary: return "Pictionary"
        }
    }

    var subtitle: String {
        switch self {
        case .ticTacToe: return "Classic 3x3 duel"
        case .wordle: return "Guess in six tries"
        case .flappyBird: return "Tap to survive"
        case .boggle: return "Find words fast"
        case .connect4: return "Connect four chips"
        case .pictionary: return "Draw, replay, and guess"
        }
    }

    var accentHex: String {
        switch self {
        case .ticTacToe: return "#F97316"
        case .wordle: return "#22C55E"
        case .flappyBird: return "#38BDF8"
        case .boggle: return "#8B5CF6"
        case .connect4: return "#EF4444"
        case .pictionary: return "#0EA5E9"
        }
    }
}

struct ArcadeEnvelope: Codable {
    static let currentSchemaVersion = 3

    var schemaVersion: Int
    var game: ArcadeGame
    var sessionID: String
    var updatedAt: TimeInterval
    var lastSummary: String
    var ticTacToe: TicTacToeState?
    var wordle: WordleState?
    var flappyBird: FlappyBirdState?
    var boggle: BoggleState?
    var connect4: Connect4State?
    var pictionary: PictionaryState?

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case game
        case sessionID
        case updatedAt
        case lastSummary
        case ticTacToe
        case wordle
        case flappyBird
        case boggle
        case connect4
        case pictionary
    }

    init(
        schemaVersion: Int = ArcadeEnvelope.currentSchemaVersion,
        game: ArcadeGame,
        sessionID: String,
        updatedAt: TimeInterval,
        lastSummary: String,
        ticTacToe: TicTacToeState?,
        wordle: WordleState?,
        flappyBird: FlappyBirdState?,
        boggle: BoggleState?,
        connect4: Connect4State?,
        pictionary: PictionaryState?
    ) {
        self.schemaVersion = schemaVersion
        self.game = game
        self.sessionID = sessionID
        self.updatedAt = updatedAt
        self.lastSummary = lastSummary
        self.ticTacToe = ticTacToe
        self.wordle = wordle
        self.flappyBird = flappyBird
        self.boggle = boggle
        self.connect4 = connect4
        self.pictionary = pictionary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        game = try container.decodeIfPresent(ArcadeGame.self, forKey: .game) ?? .ticTacToe
        sessionID = try container.decodeIfPresent(String.self, forKey: .sessionID) ?? UUID().uuidString
        updatedAt = try container.decodeIfPresent(TimeInterval.self, forKey: .updatedAt) ?? Date().timeIntervalSince1970
        lastSummary = try container.decodeIfPresent(String.self, forKey: .lastSummary) ?? ""
        ticTacToe = try container.decodeIfPresent(TicTacToeState.self, forKey: .ticTacToe)
        wordle = try container.decodeIfPresent(WordleState.self, forKey: .wordle)
        flappyBird = try container.decodeIfPresent(FlappyBirdState.self, forKey: .flappyBird)
        boggle = try container.decodeIfPresent(BoggleState.self, forKey: .boggle)
        connect4 = try container.decodeIfPresent(Connect4State.self, forKey: .connect4)
        pictionary = try container.decodeIfPresent(PictionaryState.self, forKey: .pictionary)
    }

    static func fresh(game: ArcadeGame) -> ArcadeEnvelope {
        var envelope = ArcadeEnvelope(
            schemaVersion: ArcadeEnvelope.currentSchemaVersion,
            game: game,
            sessionID: UUID().uuidString,
            updatedAt: Date().timeIntervalSince1970,
            lastSummary: "New \(game.title) round",
            ticTacToe: nil,
            wordle: nil,
            flappyBird: nil,
            boggle: nil,
            connect4: nil,
            pictionary: nil
        )

        switch game {
        case .ticTacToe:
            envelope.ticTacToe = TicTacToeState.newRound()
        case .wordle:
            envelope.wordle = WordleState.newRound()
        case .flappyBird:
            envelope.flappyBird = FlappyBirdState()
        case .boggle:
            envelope.boggle = BoggleState.newRound()
        case .connect4:
            envelope.connect4 = Connect4State.newRound()
        case .pictionary:
            envelope.pictionary = PictionaryState.newRound()
        }

        return envelope
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(game, forKey: .game)
        try container.encode(sessionID, forKey: .sessionID)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(lastSummary, forKey: .lastSummary)
        try container.encodeIfPresent(ticTacToe, forKey: .ticTacToe)
        try container.encodeIfPresent(wordle, forKey: .wordle)
        try container.encodeIfPresent(flappyBird, forKey: .flappyBird)
        try container.encodeIfPresent(boggle, forKey: .boggle)
        try container.encodeIfPresent(connect4, forKey: .connect4)
        try container.encodeIfPresent(pictionary, forKey: .pictionary)
    }
}

struct TicTacToeState: Codable {
    var board: [Int]
    var currentPlayer: Int
    var winner: Int?
    var isDraw: Bool

    static func newRound() -> TicTacToeState {
        TicTacToeState(board: Array(repeating: 0, count: 9), currentPlayer: 1, winner: nil, isDraw: false)
    }
}

struct WordleState: Codable {
    var targetWord: String
    var guesses: [String]
    var evaluations: [[Int]]
    var currentGuess: String
    var isOver: Bool
    var didWin: Bool

    static func newRound() -> WordleState {
        WordleState(
            targetWord: WordleDictionary.all.randomElement() ?? "apple",
            guesses: [],
            evaluations: [],
            currentGuess: "",
            isOver: false,
            didWin: false
        )
    }
}

struct FlappyBirdState: Codable {
    var bestScore: Int = 0
    var lastScore: Int = 0
    var totalRuns: Int = 0
}

struct BoggleState: Codable {
    var board: [String]
    var foundWords: [String]
    var score: Int
    var roundStartedAt: TimeInterval
    var roundLength: Int
    var isOver: Bool

    static func newRound(length: Int = 90) -> BoggleState {
        BoggleState(
            board: BoggleBoardGenerator.generate(),
            foundWords: [],
            score: 0,
            roundStartedAt: Date().timeIntervalSince1970,
            roundLength: length,
            isOver: false
        )
    }
}

struct Connect4State: Codable {
    var board: [Int]
    var currentPlayer: Int
    var winner: Int?
    var isDraw: Bool

    static func newRound() -> Connect4State {
        Connect4State(board: Array(repeating: 0, count: 42), currentPlayer: 1, winner: nil, isDraw: false)
    }
}

enum PictionaryPhase: String, Codable {
    case setup
    case guessing
}

struct PictionaryStrokePoint: Codable, Hashable {
    var x: Int
    var y: Int
    var t: Int
}

struct PictionaryStroke: Codable, Hashable {
    var points: [PictionaryStrokePoint]
}

struct PictionaryResult: Codable, Hashable, Identifiable {
    var playerID: String
    var elapsedMs: Int
    var guessedAt: TimeInterval
    var guess: String

    var id: String { playerID }
}

struct PictionaryState: Codable {
    var phase: PictionaryPhase
    var drawerID: String
    var promptHash: String
    var promptSalt: String
    var promptLength: Int
    var promptFirstLetter: String
    var strokes: [PictionaryStroke]
    var drawingDurationMs: Int
    var totalGuessAttempts: Int
    var correctResults: [PictionaryResult]
    var lastGuessPreview: String
    var publishedAt: TimeInterval

    static func newRound(drawerID: String = "") -> PictionaryState {
        PictionaryState(
            phase: .setup,
            drawerID: drawerID,
            promptHash: "",
            promptSalt: "",
            promptLength: 0,
            promptFirstLetter: "",
            strokes: [],
            drawingDurationMs: 0,
            totalGuessAttempts: 0,
            correctResults: [],
            lastGuessPreview: "",
            publishedAt: 0
        )
    }
}

enum ArcadeCodec {
    static func encode(_ envelope: ArcadeEnvelope) -> String? {
        guard let data = try? JSONEncoder().encode(envelope) else {
            return nil
        }
        return data.base64EncodedString()
    }

    static func decode(_ payload: String) -> ArcadeEnvelope? {
        guard let data = Data(base64Encoded: payload) else {
            return nil
        }
        return try? JSONDecoder().decode(ArcadeEnvelope.self, from: data)
    }
}

enum WordleDictionary {
    static let all: [String] = [
        "apple", "beach", "blend", "board", "brave", "brick", "bring", "broad", "candy", "chalk",
        "chase", "chess", "clown", "coast", "crane", "crown", "dance", "dream", "eagle", "earth",
        "flame", "flick", "flood", "focus", "forge", "frame", "frost", "fruit", "giant", "globe",
        "grape", "green", "group", "house", "jelly", "knock", "laser", "lemon", "light", "lucky",
        "magic", "maple", "melon", "metal", "mouse", "noble", "ocean", "olive", "orbit", "piano",
        "plaza", "prize", "queen", "quick", "raven", "river", "robot", "shark", "shore", "slice",
        "smile", "spice", "sport", "stack", "stage", "stare", "steam", "stone", "storm", "sugar",
        "sunny", "sword", "table", "tiger", "toast", "tower", "track", "trend", "trick", "truck",
        "unity", "vigor", "vivid", "whale", "world", "young", "zebra"
    ]

    static let asSet: Set<String> = Set(all)
}

enum BoggleDictionary {
    static let words: Set<String> = [
        "able", "about", "above", "acorn", "actor", "adapt", "after", "again", "agent", "agree", "alarm", "album",
        "alert", "alien", "alike", "alive", "allow", "alone", "along", "angel", "anger", "angle", "apple", "april",
        "arena", "argue", "arise", "arrow", "aside", "asset", "atlas", "audio", "award", "aware", "basic", "beach",
        "beard", "beast", "begin", "below", "bench", "berry", "birth", "black", "blame", "blank", "blend", "bless",
        "blind", "block", "blood", "board", "boast", "bonus", "brain", "brake", "brand", "brass", "brave", "bread",
        "break", "brick", "brief", "bring", "broad", "brown", "brush", "build", "cabin", "cable", "camel", "candy",
        "carry", "catch", "cause", "chain", "chair", "chalk", "charm", "chase", "check", "chess", "chest", "chief",
        "child", "chill", "claim", "class", "clean", "clear", "clerk", "click", "cliff", "climb", "clock", "close",
        "cloud", "clown", "coach", "coast", "color", "count", "court", "cover", "crack", "craft", "crane", "crash",
        "cream", "creek", "crowd", "crown", "curve", "daily", "dance", "delta", "depth", "digit", "diner", "dirty",
        "dodge", "doubt", "dozen", "draft", "drain", "drama", "dream", "dress", "dried", "drink", "drive", "eager",
        "eagle", "early", "earth", "eight", "elite", "empty", "enjoy", "enter", "equal", "error", "event", "exact",
        "exist", "extra", "faith", "false", "fancy", "fault", "favor", "fiber", "field", "fifth", "fight", "final",
        "first", "flame", "flash", "fleet", "flesh", "flick", "flint", "flood", "floor", "fluid", "focus", "force",
        "forge", "forth", "frame", "fresh", "front", "frost", "fruit", "funny", "giant", "given", "glade", "globe",
        "glory", "grace", "grade", "grain", "grand", "grape", "graph", "grass", "great", "green", "grief", "group",
        "guard", "guest", "guide", "habit", "happy", "harsh", "heart", "heavy", "honey", "horse", "house", "human",
        "ideal", "image", "imply", "index", "inner", "input", "issue", "ivory", "jelly", "joint", "judge", "juice",
        "kitty", "knife", "knock", "known", "label", "laser", "laugh", "layer", "learn", "least", "leave", "lemon",
        "light", "limit", "local", "logic", "loose", "lucky", "lunar", "magic", "major", "maker", "maple", "march",
        "match", "medal", "melon", "metal", "might", "minor", "model", "money", "month", "moral", "motor", "mount",
        "mouse", "mouth", "movie", "music", "naked", "nerve", "never", "night", "noble", "noise", "north", "novel",
        "nurse", "ocean", "offer", "often", "olive", "orbit", "order", "organ", "other", "ought", "outer", "panel",
        "panic", "paper", "party", "peace", "phase", "phone", "piano", "piece", "pilot", "pitch", "place", "plain",
        "plane", "plant", "plate", "plaza", "point", "pound", "power", "press", "price", "pride", "prime", "print",
        "prior", "prize", "proof", "proud", "queen", "quick", "quiet", "radio", "raise", "range", "rapid", "raven",
        "reach", "react", "ready", "refer", "relax", "reply", "right", "rival", "river", "robot", "rough", "round",
        "route", "royal", "ruler", "rural", "salad", "scale", "scare", "scene", "scope", "score", "scout", "screw",
        "sense", "serve", "shade", "shake", "shall", "shape", "share", "shark", "sharp", "sheep", "sheet", "shelf",
        "shell", "shift", "shine", "shirt", "shock", "shoot", "shore", "short", "shown", "sight", "silly", "since",
        "skill", "sleep", "slice", "slide", "slope", "small", "smart", "smile", "smoke", "solid", "solve", "sound",
        "south", "space", "spare", "speak", "speed", "spice", "spike", "spine", "split", "sport", "spray", "stack",
        "staff", "stage", "stair", "stake", "stand", "stare", "start", "state", "steam", "steel", "steep", "steer",
        "stick", "still", "stock", "stone", "store", "storm", "story", "strip", "stuck", "study", "stuff", "style",
        "sugar", "sunny", "super", "sweet", "swing", "sword", "table", "taken", "taste", "teach", "thank", "their",
        "theme", "thick", "thing", "think", "third", "those", "throw", "tight", "tiger", "title", "today", "token",
        "topic", "torch", "total", "touch", "tower", "track", "trade", "trail", "train", "trend", "trial", "trick",
        "truck", "truly", "trust", "truth", "twice", "under", "union", "unity", "until", "upper", "upset", "urban",
        "usage", "usual", "valid", "value", "video", "vigor", "vital", "voice", "waste", "watch", "water", "wheel",
        "where", "which", "while", "white", "whole", "whose", "woman", "world", "worry", "worth", "would", "wound",
        "write", "wrong", "young", "youth", "zebra"
    ]
}

enum BoggleBoardGenerator {
    private static let dice = [
        "AAEEGN", "ABBJOO", "ACHOPS", "AFFKPS",
        "AOOTTW", "CIMOTU", "DEILRX", "DELRVY",
        "DISTTY", "EEGHNW", "EEINSU", "EHRTVW",
        "EIOSST", "ELRTTY", "HIMNQU", "HLNNRZ"
    ]

    static func generate() -> [String] {
        let shuffled = dice.shuffled()
        return shuffled.map { die in
            let random = die.randomElement() ?? "A"
            if random == "Q" {
                return "qu"
            }
            return String(random).lowercased()
        }
    }
}
