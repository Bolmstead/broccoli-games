# Broccoli Pigeon (iMessage Extension)

This repo now contains a native iOS iMessage extension game app (Game Pigeon-style) with exactly these games:

- Tic Tac Toe
- Wordle
- Flappy Bird
- Boggle
- Connect 4
- Pictionary
- Yahtzee

## Project layout

- `project.yml` - XcodeGen spec for the app + iMessage extension targets
- `App/` - Host iOS app (required container for Messages extension)
- `iMessageExtension/` - Messages extension, game UI, and message state logic

## Build steps

1. Install XcodeGen (if missing): `brew install xcodegen`
2. Generate the Xcode project from repo root:
   - `xcodegen generate`
3. Open the generated project in Xcode:
   - `open BroccoliPigeon.xcodeproj`
4. Set your Team for both targets (`BroccoliPigeon` and `BroccoliGamesMessagesExtension`).
5. Build and run on an iPhone simulator or device.
6. Open Messages in the simulator/device and launch the extension from the iMessage app drawer.

## Notes

- The extension serializes game state into `MSMessage.url` payloads so turns and score updates can be sent through chat.
- `New Round` resets the currently active game state and sends a fresh message.
- `Lobby` lets you start one of the five supported games.
