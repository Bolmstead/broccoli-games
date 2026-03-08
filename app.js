(function () {
  const gameListEl = document.getElementById("gameList");
  const gameTitleEl = document.getElementById("gameTitle");
  const gameDescriptionEl = document.getElementById("gameDescription");
  const gameControlsEl = document.getElementById("gameControls");
  const statusBarEl = document.getElementById("statusBar");
  const gameContainerEl = document.getElementById("gameContainer");

  let activeGameId = null;
  let activeGameInstance = null;

  const WORDLE_WORDS = [
    "apple", "beach", "blend", "board", "brave", "brick", "bring", "broad", "cabin", "candy",
    "chalk", "charm", "chase", "chess", "chili", "cloud", "clown", "coast", "crane", "crown",
    "dance", "dream", "dried", "eagle", "earth", "flame", "flick", "flint", "flood", "focus",
    "forge", "frame", "fresh", "frost", "fruit", "giant", "globe", "grape", "grass", "green",
    "group", "house", "jelly", "knock", "laser", "lemon", "light", "liver", "lobby", "lucky",
    "magic", "maple", "march", "medal", "melon", "metal", "mouse", "noble", "ocean", "olive",
    "orbit", "piano", "plaza", "pride", "prize", "queen", "quick", "raven", "rider", "river",
    "roast", "robot", "rouge", "scarf", "score", "shade", "shake", "shark", "shore", "slice",
    "smile", "spice", "spike", "sport", "stack", "stage", "stare", "steam", "stone", "storm",
    "sugar", "sunny", "sword", "table", "tiger", "toast", "tower", "track", "trend", "trick",
    "truck", "ultra", "unity", "vigor", "vivid", "whale", "wheat", "world", "young", "zebra"
  ];

  const BOGGLE_WORDS = new Set([
    "able", "about", "above", "ache", "acid", "acorn", "across", "actor", "adapt", "adder",
    "after", "again", "agent", "agree", "alarm", "album", "alert", "alien", "align", "alike",
    "alive", "allow", "alone", "along", "alter", "angel", "anger", "angle", "ankle", "apple",
    "april", "arena", "argue", "arise", "armed", "arrow", "aside", "asset", "atlas", "atom",
    "audio", "avoid", "awake", "award", "aware", "baker", "basic", "beach", "beard", "beast",
    "begin", "being", "belly", "below", "bench", "berry", "birth", "black", "blame", "blank",
    "blend", "bless", "blind", "block", "blood", "board", "boast", "bonus", "boost", "brain",
    "brake", "brand", "brass", "brave", "bread", "break", "brick", "brief", "bring", "broad",
    "brown", "brush", "build", "cabin", "cable", "camel", "candy", "carry", "catch", "cause",
    "chain", "chair", "chalk", "charm", "chase", "cheap", "check", "chess", "chest", "chief",
    "child", "chill", "choir", "chose", "civic", "claim", "class", "clean", "clear", "clerk",
    "click", "cliff", "climb", "clock", "close", "cloud", "clown", "coach", "coast", "color",
    "could", "count", "court", "cover", "crack", "craft", "crane", "crash", "cream", "creek",
    "crowd", "crown", "curve", "daily", "dance", "dealt", "delta", "demon", "depth", "digit",
    "diner", "dirty", "dodge", "donor", "doubt", "dozen", "draft", "drain", "drama", "dream",
    "dress", "dried", "drink", "drive", "eager", "eagle", "early", "earth", "eight", "elect",
    "elite", "empty", "enjoy", "enter", "equal", "error", "event", "exact", "exist", "extra",
    "faith", "false", "fancy", "fault", "favor", "fiber", "field", "fifth", "fight", "final",
    "first", "flame", "flash", "fleet", "flesh", "flick", "flint", "flood", "floor", "fluid",
    "focus", "force", "forge", "forth", "frame", "fresh", "front", "frost", "fruit", "funny",
    "giant", "given", "glade", "globe", "glory", "grace", "grade", "grain", "grand", "grape",
    "graph", "grass", "great", "green", "grief", "gross", "group", "guard", "guest", "guide",
    "habit", "happy", "harsh", "heart", "heavy", "honey", "horse", "house", "human", "humor",
    "ideal", "image", "imply", "index", "inner", "input", "issue", "ivory", "jelly", "joint",
    "judge", "juice", "kitty", "knife", "knock", "known", "label", "laser", "laugh", "layer",
    "learn", "least", "leave", "lemon", "light", "limit", "local", "logic", "loose", "lucky",
    "lunar", "magic", "major", "maker", "maple", "march", "match", "medal", "melon", "metal",
    "might", "minor", "model", "money", "month", "moral", "motor", "mount", "mouse", "mouth",
    "movie", "music", "naked", "nerve", "never", "night", "noble", "noise", "north", "novel",
    "nurse", "ocean", "offer", "often", "olive", "orbit", "order", "organ", "other", "ought",
    "outer", "panel", "panic", "paper", "party", "peace", "phase", "phone", "piano", "piece",
    "pilot", "pitch", "place", "plain", "plane", "plant", "plate", "plaza", "point", "pound",
    "power", "press", "price", "pride", "prime", "print", "prior", "prize", "proof", "proud",
    "queen", "quick", "quiet", "radio", "raise", "range", "rapid", "raven", "reach", "react",
    "ready", "refer", "relax", "reply", "right", "rival", "river", "robot", "rough", "round",
    "route", "royal", "ruler", "rural", "salad", "scale", "scare", "scene", "scope", "score",
    "scout", "screw", "sense", "serve", "shade", "shake", "shall", "shape", "share", "shark",
    "sharp", "sheep", "sheet", "shelf", "shell", "shift", "shine", "shirt", "shock", "shoot",
    "shore", "short", "shown", "sight", "silly", "since", "skill", "sleep", "slice", "slide",
    "slope", "small", "smart", "smile", "smoke", "solid", "solve", "sound", "south", "space",
    "spare", "speak", "speed", "spice", "spike", "spine", "spite", "split", "spoke", "sport",
    "spout", "spray", "stack", "staff", "stage", "stair", "stake", "stand", "stare", "start",
    "state", "steam", "steel", "steep", "steer", "stick", "still", "stock", "stone", "store",
    "storm", "story", "strip", "stuck", "study", "stuff", "style", "sugar", "sunny", "super",
    "sweet", "swing", "sword", "table", "taken", "taste", "teach", "thank", "their", "theme",
    "thick", "thing", "think", "third", "those", "throw", "tight", "tiger", "title", "today",
    "token", "topic", "torch", "total", "touch", "tower", "track", "trade", "trail", "train",
    "trend", "trial", "trick", "truck", "truly", "trust", "truth", "twice", "under", "union",
    "unity", "until", "upper", "upset", "urban", "usage", "usual", "valid", "value", "video",
    "vigor", "vital", "voice", "waste", "watch", "water", "wheel", "where", "which", "while",
    "white", "whole", "whose", "woman", "world", "worry", "worth", "would", "wound", "write",
    "wrong", "young", "youth", "zebra"
  ]);

  const LETTER_SCORES = {
    3: 1,
    4: 1,
    5: 2,
    6: 3,
    7: 5
  };

  const BOGGLE_DICE = [
    "AAEEGN", "ABBJOO", "ACHOPS", "AFFKPS",
    "AOOTTW", "CIMOTU", "DEILRX", "DELRVY",
    "DISTTY", "EEGHNW", "EEINSU", "EHRTVW",
    "EIOSST", "ELRTTY", "HIMNQU", "HLNNRZ"
  ];

  function setStatus(message, type = "info") {
    statusBarEl.textContent = message;
    statusBarEl.className = "status-bar";
    if (type) {
      statusBarEl.classList.add(type);
    }
  }

  function clearNode(node) {
    while (node.firstChild) {
      node.removeChild(node.firstChild);
    }
  }

  function createButton(label, className, onClick) {
    const button = document.createElement("button");
    button.type = "button";
    button.textContent = label;
    button.className = `btn ${className}`;
    button.addEventListener("click", onClick);
    return button;
  }

  function chooseRandom(array) {
    return array[Math.floor(Math.random() * array.length)];
  }

  function shuffle(array) {
    const clone = [...array];
    for (let i = clone.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1));
      [clone[i], clone[j]] = [clone[j], clone[i]];
    }
    return clone;
  }

  function evaluateWordleGuess(guess, target) {
    const result = Array(5).fill("absent");
    const targetChars = target.split("");
    const used = Array(5).fill(false);

    for (let i = 0; i < 5; i += 1) {
      if (guess[i] === targetChars[i]) {
        result[i] = "correct";
        used[i] = true;
      }
    }

    for (let i = 0; i < 5; i += 1) {
      if (result[i] !== "absent") {
        continue;
      }
      for (let j = 0; j < 5; j += 1) {
        if (!used[j] && guess[i] === targetChars[j]) {
          result[i] = "present";
          used[j] = true;
          break;
        }
      }
    }

    return result;
  }

  function scoreBoggleWord(word) {
    if (word.length >= 8) {
      return 11;
    }
    return LETTER_SCORES[word.length] || 0;
  }

  function canBuildWordFromBoard(word, board) {
    const size = 4;
    const letters = word.split("");
    const visited = Array.from({ length: size }, () => Array(size).fill(false));

    function dfs(row, col, index) {
      if (board[row][col] !== letters[index]) {
        return false;
      }
      if (index === letters.length - 1) {
        return true;
      }

      visited[row][col] = true;

      for (let dr = -1; dr <= 1; dr += 1) {
        for (let dc = -1; dc <= 1; dc += 1) {
          if (dr === 0 && dc === 0) {
            continue;
          }
          const nextRow = row + dr;
          const nextCol = col + dc;
          if (
            nextRow < 0 ||
            nextRow >= size ||
            nextCol < 0 ||
            nextCol >= size ||
            visited[nextRow][nextCol]
          ) {
            continue;
          }
          if (dfs(nextRow, nextCol, index + 1)) {
            visited[row][col] = false;
            return true;
          }
        }
      }

      visited[row][col] = false;
      return false;
    }

    for (let row = 0; row < size; row += 1) {
      for (let col = 0; col < size; col += 1) {
        if (board[row][col] === letters[0] && dfs(row, col, 0)) {
          return true;
        }
      }
    }

    return false;
  }

  function renderGameList(games) {
    clearNode(gameListEl);

    games.forEach((game) => {
      const card = document.createElement("button");
      card.type = "button";
      card.className = "game-card";
      card.dataset.gameId = game.id;
      card.innerHTML = `<h3>${game.title}</h3><p>${game.short}</p>`;
      card.addEventListener("click", () => selectGame(game.id));
      gameListEl.appendChild(card);
    });
  }

  function markActiveGameCard() {
    const cards = gameListEl.querySelectorAll(".game-card");
    cards.forEach((card) => {
      card.classList.toggle("active", card.dataset.gameId === activeGameId);
    });
  }

  function selectGame(gameId) {
    const game = GAMES.find((entry) => entry.id === gameId);
    if (!game) {
      return;
    }

    if (activeGameInstance && typeof activeGameInstance.destroy === "function") {
      activeGameInstance.destroy();
    }

    activeGameId = gameId;
    markActiveGameCard();

    gameTitleEl.textContent = game.title;
    gameDescriptionEl.textContent = game.description;

    clearNode(gameControlsEl);
    clearNode(gameContainerEl);

    activeGameInstance = game.create({
      containerEl: gameContainerEl,
      controlsEl: gameControlsEl,
      setStatus
    });

    const resetButton = createButton("New Round", "btn-primary", () => {
      if (activeGameInstance && typeof activeGameInstance.reset === "function") {
        activeGameInstance.reset();
      }
    });
    gameControlsEl.prepend(resetButton);
  }

  function createTicTacToe({ containerEl, setStatus }) {
    let board = Array(9).fill("");
    let current = "X";
    let gameOver = false;

    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6]
    ];

    const wrapper = document.createElement("div");
    wrapper.className = "game-layout";

    const note = document.createElement("p");
    note.className = "kicker";
    note.textContent = "Player X vs Player O";

    const boardEl = document.createElement("div");
    boardEl.className = "board-grid tictactoe-board";

    const cells = [];

    function checkWinner() {
      for (const [a, b, c] of lines) {
        if (board[a] && board[a] === board[b] && board[b] === board[c]) {
          return board[a];
        }
      }
      return null;
    }

    function render() {
      cells.forEach((cell, index) => {
        cell.textContent = board[index];
        cell.disabled = gameOver || Boolean(board[index]);
      });

      const winner = checkWinner();
      if (winner) {
        gameOver = true;
        setStatus(`Player ${winner} wins!`, "win");
      } else if (board.every(Boolean)) {
        gameOver = true;
        setStatus("Draw. Tap New Round to play again.", "info");
      } else {
        setStatus(`Player ${current}'s turn.`, "info");
      }
    }

    for (let i = 0; i < 9; i += 1) {
      const cell = document.createElement("button");
      cell.type = "button";
      cell.className = "cell";
      cell.addEventListener("click", () => {
        if (board[i] || gameOver) {
          return;
        }
        board[i] = current;
        current = current === "X" ? "O" : "X";
        render();
      });
      cells.push(cell);
      boardEl.appendChild(cell);
    }

    wrapper.append(note, boardEl);
    containerEl.appendChild(wrapper);

    function reset() {
      board = Array(9).fill("");
      current = "X";
      gameOver = false;
      render();
    }

    reset();

    return {
      reset,
      destroy() {}
    };
  }

  function createWordle({ containerEl, setStatus }) {
    let target = chooseRandom(WORDLE_WORDS);
    let guesses = [];
    let evaluations = [];
    let currentGuess = "";
    let gameOver = false;

    const keyboardState = new Map();

    const wrapper = document.createElement("div");
    wrapper.className = "game-layout";

    const note = document.createElement("p");
    note.className = "kicker";
    note.textContent = "Guess the 5-letter word in 6 tries";

    const boardEl = document.createElement("div");
    boardEl.className = "wordle-board";

    const keyboardEl = document.createElement("div");
    keyboardEl.className = "keyboard";

    const rows = [];

    for (let rowIndex = 0; rowIndex < 6; rowIndex += 1) {
      const rowEl = document.createElement("div");
      rowEl.className = "wordle-row";
      const cells = [];
      for (let col = 0; col < 5; col += 1) {
        const cell = document.createElement("div");
        cell.className = "wordle-cell";
        rowEl.appendChild(cell);
        cells.push(cell);
      }
      rows.push(cells);
      boardEl.appendChild(rowEl);
    }

    const keyboardRows = ["QWERTYUIOP", "ASDFGHJKL", "ENTERZXCVBNMBACK"];
    const letterButtons = new Map();

    function buildKeyboardRow(layout) {
      const rowEl = document.createElement("div");
      rowEl.className = "kb-row";

      let i = 0;
      while (i < layout.length) {
        if (layout.startsWith("ENTER", i)) {
          const key = document.createElement("button");
          key.type = "button";
          key.className = "kb-key wide";
          key.textContent = "Enter";
          key.addEventListener("click", () => handleInput("ENTER"));
          rowEl.appendChild(key);
          i += 5;
          continue;
        }

        if (layout.startsWith("BACK", i)) {
          const key = document.createElement("button");
          key.type = "button";
          key.className = "kb-key wide";
          key.textContent = "Back";
          key.addEventListener("click", () => handleInput("BACKSPACE"));
          rowEl.appendChild(key);
          i += 4;
          continue;
        }

        const letter = layout[i];
        const key = document.createElement("button");
        key.type = "button";
        key.className = "kb-key";
        key.textContent = letter;
        key.addEventListener("click", () => handleInput(letter));
        rowEl.appendChild(key);
        letterButtons.set(letter, key);
        i += 1;
      }

      return rowEl;
    }

    keyboardRows.forEach((layout) => keyboardEl.appendChild(buildKeyboardRow(layout)));

    function paintKeyboard() {
      for (const [letter, state] of keyboardState.entries()) {
        const keyEl = letterButtons.get(letter);
        if (keyEl) {
          keyEl.dataset.state = state;
        }
      }
    }

    function updateKeyboardStates(guess, evaluation) {
      const rank = { absent: 1, present: 2, correct: 3 };
      guess.split("").forEach((letter, index) => {
        const next = evaluation[index];
        const existing = keyboardState.get(letter);
        if (!existing || rank[next] > rank[existing]) {
          keyboardState.set(letter, next);
        }
      });
      paintKeyboard();
    }

    function render() {
      for (let row = 0; row < 6; row += 1) {
        for (let col = 0; col < 5; col += 1) {
          const cell = rows[row][col];
          cell.className = "wordle-cell";

          if (row < guesses.length) {
            const letter = guesses[row][col];
            const evalState = evaluations[row][col];
            cell.textContent = letter.toUpperCase();
            cell.classList.add(evalState);
          } else if (row === guesses.length) {
            cell.textContent = currentGuess[col] ? currentGuess[col].toUpperCase() : "";
          } else {
            cell.textContent = "";
          }
        }
      }
    }

    function endGame(won) {
      gameOver = true;
      if (won) {
        setStatus("You solved it. Nice game.", "win");
      } else {
        setStatus(`Out of tries. Word was ${target.toUpperCase()}.`, "lose");
      }
    }

    function submitGuess() {
      if (currentGuess.length !== 5) {
        setStatus("Word must be 5 letters.", "info");
        return;
      }

      if (!WORDLE_WORDS.includes(currentGuess)) {
        setStatus("Word not in dictionary.", "info");
        return;
      }

      const result = evaluateWordleGuess(currentGuess, target);
      guesses.push(currentGuess);
      evaluations.push(result);
      updateKeyboardStates(currentGuess.toUpperCase(), result);

      if (currentGuess === target) {
        currentGuess = "";
        render();
        endGame(true);
        return;
      }

      currentGuess = "";
      if (guesses.length >= 6) {
        render();
        endGame(false);
        return;
      }

      setStatus(`Try ${guesses.length + 1} of 6.`, "info");
      render();
    }

    function handleInput(key) {
      if (gameOver) {
        return;
      }

      if (key === "ENTER") {
        submitGuess();
        return;
      }

      if (key === "BACKSPACE") {
        currentGuess = currentGuess.slice(0, -1);
        render();
        return;
      }

      if (/^[A-Z]$/.test(key) && currentGuess.length < 5) {
        currentGuess += key.toLowerCase();
        render();
      }
    }

    function onKeydown(event) {
      const key = event.key;
      if (key === "Enter") {
        handleInput("ENTER");
        return;
      }
      if (key === "Backspace") {
        handleInput("BACKSPACE");
        return;
      }
      if (/^[a-zA-Z]$/.test(key)) {
        handleInput(key.toUpperCase());
      }
    }

    window.addEventListener("keydown", onKeydown);

    wrapper.append(note, boardEl, keyboardEl);
    containerEl.appendChild(wrapper);

    function reset() {
      target = chooseRandom(WORDLE_WORDS);
      guesses = [];
      evaluations = [];
      currentGuess = "";
      gameOver = false;
      keyboardState.clear();
      letterButtons.forEach((button) => {
        delete button.dataset.state;
      });
      setStatus("Type a guess and press Enter.", "info");
      render();
    }

    reset();

    return {
      reset,
      destroy() {
        window.removeEventListener("keydown", onKeydown);
      }
    };
  }

  function createFlappyBird({ containerEl, setStatus }) {
    const wrapper = document.createElement("div");
    wrapper.className = "game-layout";

    const note = document.createElement("p");
    note.className = "kicker";
    note.textContent = "Press Space or Tap to flap";

    const canvasWrap = document.createElement("div");
    canvasWrap.className = "canvas-wrap";

    const canvas = document.createElement("canvas");
    canvas.className = "flappy-canvas";
    canvas.width = 420;
    canvas.height = 540;
    canvasWrap.appendChild(canvas);

    const meta = document.createElement("div");
    meta.className = "flappy-meta";
    const scoreEl = document.createElement("span");
    const bestEl = document.createElement("span");
    meta.append(scoreEl, bestEl);

    wrapper.append(note, meta, canvasWrap);
    containerEl.appendChild(wrapper);

    const ctx = canvas.getContext("2d");

    let animationId = null;
    let started = false;
    let ended = false;
    let score = 0;
    let best = 0;

    const bird = {
      x: 95,
      y: 240,
      r: 15,
      velocity: 0
    };

    const gravity = 0.46;
    const flapBoost = -7.4;
    const pipeWidth = 62;
    const pipeGap = 145;
    const pipeSpeed = 2.9;
    let pipes = [];
    let spawnTick = 0;

    function updateMeta() {
      scoreEl.textContent = `Score: ${score}`;
      bestEl.textContent = `Best: ${best}`;
    }

    function spawnPipe() {
      const margin = 64;
      const maxTop = canvas.height - pipeGap - margin;
      const topHeight = Math.floor(Math.random() * (maxTop - margin + 1)) + margin;
      pipes.push({ x: canvas.width, topHeight, passed: false });
    }

    function flap() {
      if (ended) {
        return;
      }
      started = true;
      bird.velocity = flapBoost;
    }

    function collideWithPipe(pipe) {
      const withinX = bird.x + bird.r > pipe.x && bird.x - bird.r < pipe.x + pipeWidth;
      if (!withinX) {
        return false;
      }
      const hitTop = bird.y - bird.r < pipe.topHeight;
      const hitBottom = bird.y + bird.r > pipe.topHeight + pipeGap;
      return hitTop || hitBottom;
    }

    function renderScene() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      ctx.fillStyle = "#6ec95d";
      ctx.fillRect(0, canvas.height - 52, canvas.width, 52);

      ctx.fillStyle = "#2d8a3a";
      pipes.forEach((pipe) => {
        ctx.fillRect(pipe.x, 0, pipeWidth, pipe.topHeight);
        ctx.fillRect(pipe.x, pipe.topHeight + pipeGap, pipeWidth, canvas.height);
      });

      ctx.beginPath();
      ctx.arc(bird.x, bird.y, bird.r, 0, Math.PI * 2);
      ctx.fillStyle = "#ffcb26";
      ctx.fill();
      ctx.strokeStyle = "#223";
      ctx.lineWidth = 2;
      ctx.stroke();

      ctx.beginPath();
      ctx.arc(bird.x + 5, bird.y - 4, 2, 0, Math.PI * 2);
      ctx.fillStyle = "#111";
      ctx.fill();

      if (!started && !ended) {
        ctx.fillStyle = "rgba(4, 27, 71, 0.76)";
        ctx.fillRect(56, 220, canvas.width - 112, 88);
        ctx.fillStyle = "#fff";
        ctx.textAlign = "center";
        ctx.font = "700 22px 'Chakra Petch'";
        ctx.fillText("Tap or Space to Start", canvas.width / 2, 272);
      }

      if (ended) {
        ctx.fillStyle = "rgba(4, 27, 71, 0.82)";
        ctx.fillRect(74, 210, canvas.width - 148, 110);
        ctx.fillStyle = "#fff";
        ctx.textAlign = "center";
        ctx.font = "700 28px 'Chakra Petch'";
        ctx.fillText("Game Over", canvas.width / 2, 257);
        ctx.font = "600 19px 'Chakra Petch'";
        ctx.fillText("Tap New Round", canvas.width / 2, 290);
      }
    }

    function step() {
      if (!ended && started) {
        bird.velocity += gravity;
        bird.y += bird.velocity;

        spawnTick += 1;
        if (spawnTick >= 90) {
          spawnTick = 0;
          spawnPipe();
        }

        pipes.forEach((pipe) => {
          pipe.x -= pipeSpeed;

          if (!pipe.passed && pipe.x + pipeWidth < bird.x) {
            pipe.passed = true;
            score += 1;
            best = Math.max(best, score);
            updateMeta();
            setStatus(`Flap streak: ${score}`, "info");
          }
        });

        pipes = pipes.filter((pipe) => pipe.x + pipeWidth > -5);

        const hitPipe = pipes.some((pipe) => collideWithPipe(pipe));
        const hitBounds = bird.y + bird.r >= canvas.height - 52 || bird.y - bird.r <= 0;

        if (hitPipe || hitBounds) {
          ended = true;
          setStatus(`Crashed at ${score}. Hit New Round.`, "lose");
        }
      }

      renderScene();
      animationId = window.requestAnimationFrame(step);
    }

    function onKeydown(event) {
      if (event.code === "Space") {
        event.preventDefault();
        flap();
      }
    }

    function onPointerDown() {
      flap();
    }

    window.addEventListener("keydown", onKeydown);
    canvas.addEventListener("pointerdown", onPointerDown);

    function reset() {
      started = false;
      ended = false;
      score = 0;
      pipes = [];
      spawnTick = 0;
      bird.y = 240;
      bird.velocity = 0;
      updateMeta();
      setStatus("Tap the game area or press Space to flap.", "info");
      renderScene();
    }

    reset();
    animationId = window.requestAnimationFrame(step);

    return {
      reset,
      destroy() {
        if (animationId) {
          window.cancelAnimationFrame(animationId);
        }
        window.removeEventListener("keydown", onKeydown);
        canvas.removeEventListener("pointerdown", onPointerDown);
      }
    };
  }

  function createBoggle({ containerEl, setStatus }) {
    let board = [];
    let remaining = 90;
    let timerId = null;
    let wordsFound = new Set();
    let score = 0;
    let over = false;

    const wrapper = document.createElement("div");
    wrapper.className = "boggle-wrap";

    const note = document.createElement("p");
    note.className = "kicker";
    note.textContent = "Find 3+ letter words before time runs out";

    const meta = document.createElement("div");
    meta.className = "meta-row";
    const timerEl = document.createElement("span");
    const scoreEl = document.createElement("span");
    meta.append(timerEl, scoreEl);

    const boardEl = document.createElement("div");
    boardEl.className = "boggle-board";

    const controls = document.createElement("form");
    controls.className = "boggle-controls";

    const input = document.createElement("input");
    input.className = "text-input";
    input.autocomplete = "off";
    input.maxLength = 16;
    input.placeholder = "Type word";

    const submit = document.createElement("button");
    submit.type = "submit";
    submit.className = "btn btn-secondary";
    submit.textContent = "Add Word";

    controls.append(input, submit);

    const wordList = document.createElement("div");
    wordList.className = "word-list";

    wrapper.append(note, meta, boardEl, controls, wordList);
    containerEl.appendChild(wrapper);

    function updateMeta() {
      timerEl.textContent = `Time: ${remaining}s`;
      scoreEl.textContent = `Score: ${score}`;
    }

    function renderWords() {
      clearNode(wordList);
      if (wordsFound.size === 0) {
        const empty = document.createElement("span");
        empty.textContent = "No words yet";
        empty.style.color = "#546282";
        wordList.appendChild(empty);
        return;
      }

      [...wordsFound]
        .sort()
        .forEach((word) => {
          const chip = document.createElement("span");
          chip.className = "word-chip";
          chip.textContent = `${word.toUpperCase()} (+${scoreBoggleWord(word)})`;
          wordList.appendChild(chip);
        });
    }

    function renderBoard() {
      clearNode(boardEl);
      board.forEach((row) => {
        row.forEach((letter) => {
          const cell = document.createElement("div");
          cell.className = "boggle-cell";
          cell.textContent = letter.toUpperCase();
          boardEl.appendChild(cell);
        });
      });
    }

    function generateBoard() {
      const dice = shuffle(BOGGLE_DICE);
      const flat = dice.map((die) => chooseRandom(die.split("")).toLowerCase());
      const result = [];
      for (let i = 0; i < 4; i += 1) {
        result.push(flat.slice(i * 4, i * 4 + 4));
      }
      return result;
    }

    function tick() {
      remaining -= 1;
      updateMeta();
      if (remaining <= 0) {
        over = true;
        clearInterval(timerId);
        setStatus(`Time up. Final score: ${score}.`, "win");
      }
    }

    function startTimer() {
      clearInterval(timerId);
      timerId = setInterval(() => {
        if (!over) {
          tick();
        }
      }, 1000);
    }

    controls.addEventListener("submit", (event) => {
      event.preventDefault();
      if (over) {
        setStatus("Round finished. Start a new round.", "info");
        return;
      }

      const raw = input.value.trim().toLowerCase();
      input.value = "";

      if (raw.length < 3) {
        setStatus("Word must be at least 3 letters.", "info");
        return;
      }

      if (!/^[a-z]+$/.test(raw)) {
        setStatus("Use letters only.", "info");
        return;
      }

      if (!BOGGLE_WORDS.has(raw)) {
        setStatus("Not in dictionary.", "info");
        return;
      }

      if (wordsFound.has(raw)) {
        setStatus("Already found that word.", "info");
        return;
      }

      if (!canBuildWordFromBoard(raw, board)) {
        setStatus("That word cannot be traced on this board.", "info");
        return;
      }

      wordsFound.add(raw);
      score += scoreBoggleWord(raw);
      renderWords();
      updateMeta();
      setStatus(`Accepted: ${raw.toUpperCase()}`, "win");
    });

    function reset() {
      board = generateBoard();
      remaining = 90;
      wordsFound = new Set();
      score = 0;
      over = false;
      renderBoard();
      renderWords();
      updateMeta();
      startTimer();
      setStatus("Find words before the timer ends.", "info");
      input.focus();
    }

    reset();

    return {
      reset,
      destroy() {
        clearInterval(timerId);
      }
    };
  }

  function createConnect4({ containerEl, setStatus }) {
    const ROWS = 6;
    const COLS = 7;

    let board = [];
    let current = "R";
    let over = false;

    const wrapper = document.createElement("div");
    wrapper.className = "game-layout";

    const note = document.createElement("p");
    note.className = "kicker";
    note.textContent = "Red vs Yellow - connect four in any direction";

    const boardWrap = document.createElement("div");
    boardWrap.className = "connect-board-wrap";

    const controls = document.createElement("div");
    controls.className = "connect-controls";

    const boardEl = document.createElement("div");
    boardEl.className = "connect-board";

    boardWrap.append(controls, boardEl);
    wrapper.append(note, boardWrap);
    containerEl.appendChild(wrapper);

    const dropButtons = [];
    const cellEls = [];

    function nextOpenRow(col) {
      for (let row = ROWS - 1; row >= 0; row -= 1) {
        if (!board[row][col]) {
          return row;
        }
      }
      return -1;
    }

    function hasWinner(row, col, token) {
      const vectors = [
        [0, 1],
        [1, 0],
        [1, 1],
        [1, -1]
      ];

      for (const [dr, dc] of vectors) {
        let count = 1;

        let r = row + dr;
        let c = col + dc;
        while (r >= 0 && r < ROWS && c >= 0 && c < COLS && board[r][c] === token) {
          count += 1;
          r += dr;
          c += dc;
        }

        r = row - dr;
        c = col - dc;
        while (r >= 0 && r < ROWS && c >= 0 && c < COLS && board[r][c] === token) {
          count += 1;
          r -= dr;
          c -= dc;
        }

        if (count >= 4) {
          return true;
        }
      }

      return false;
    }

    function render() {
      for (let row = 0; row < ROWS; row += 1) {
        for (let col = 0; col < COLS; col += 1) {
          const token = board[row][col];
          const cell = cellEls[row][col];
          cell.className = "connect-cell";
          if (token === "R") {
            cell.classList.add("red");
          } else if (token === "Y") {
            cell.classList.add("yellow");
          }
        }
      }

      dropButtons.forEach((button, col) => {
        button.disabled = over || nextOpenRow(col) === -1;
      });

      if (!over) {
        setStatus(`Player ${current === "R" ? "Red" : "Yellow"} turn.`, "info");
      }
    }

    for (let col = 0; col < COLS; col += 1) {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "drop-btn";
      btn.textContent = "Drop";
      btn.addEventListener("click", () => {
        if (over) {
          return;
        }

        const row = nextOpenRow(col);
        if (row === -1) {
          return;
        }

        board[row][col] = current;

        if (hasWinner(row, col, current)) {
          over = true;
          setStatus(`Player ${current === "R" ? "Red" : "Yellow"} wins!`, "win");
          render();
          return;
        }

        if (board.every((line) => line.every(Boolean))) {
          over = true;
          setStatus("Draw game. Start a new round.", "info");
          render();
          return;
        }

        current = current === "R" ? "Y" : "R";
        render();
      });
      controls.appendChild(btn);
      dropButtons.push(btn);
    }

    for (let row = 0; row < ROWS; row += 1) {
      const rowEls = [];
      for (let col = 0; col < COLS; col += 1) {
        const cell = document.createElement("div");
        cell.className = "connect-cell";
        boardEl.appendChild(cell);
        rowEls.push(cell);
      }
      cellEls.push(rowEls);
    }

    function reset() {
      board = Array.from({ length: ROWS }, () => Array(COLS).fill(""));
      current = "R";
      over = false;
      render();
    }

    reset();

    return {
      reset,
      destroy() {}
    };
  }

  const GAMES = [
    {
      id: "tictactoe",
      title: "Tic Tac Toe",
      short: "Classic 3x3 duel",
      description: "Pass-and-play. First player to get 3 in a row wins.",
      create: createTicTacToe
    },
    {
      id: "wordle",
      title: "Wordle",
      short: "6 tries, 5 letters",
      description: "Guess the hidden word using color feedback for each letter.",
      create: createWordle
    },
    {
      id: "flappy",
      title: "Flappy Bird",
      short: "Tap to fly",
      description: "Stay airborne and thread through pipes for the longest streak.",
      create: createFlappyBird
    },
    {
      id: "boggle",
      title: "Boggle",
      short: "Word hunt sprint",
      description: "Find traceable words on the 4x4 board before the 90 second timer ends.",
      create: createBoggle
    },
    {
      id: "connect4",
      title: "Connect 4",
      short: "7x6 strategy battle",
      description: "Drop pieces into columns. Connect four first to win.",
      create: createConnect4
    }
  ];

  renderGameList(GAMES);
  selectGame("tictactoe");
})();
