import SwiftUI

final class GameViewModel: ObservableObject {
    enum Player: String {
        case x = "X"
        case o = "O"

        var next: Player { self == .x ? .o : .x }
    }

    @Published private(set) var board: [Player?] = Array(repeating: nil, count: 9)
    @Published private(set) var currentPlayer: Player = .x
    @Published private(set) var gameState: GameState = .playing
    @Published private(set) var winningLine: [Int] = []

    enum GameState: Equatable {
        case playing
        case won(Player)
        case draw
    }

    // PUBLIC_INTERFACE
    func cellTitle(at index: Int) -> String {
        /**
         Returns the display title for the cell at the given board index (0...8).
         */
        guard (0..<board.count).contains(index) else { return "" }
        return board[index]?.rawValue ?? ""
    }

    // PUBLIC_INTERFACE
    func tapCell(at index: Int) {
        /**
         Handles a user tap on the cell at the given index, updating game state and detecting win/draw.
         */
        guard (0..<board.count).contains(index) else { return }
        guard gameState == .playing else { return }
        guard board[index] == nil else { return }

        board[index] = currentPlayer

        if let win = Self.detectWin(in: board) {
            gameState = .won(win.player)
            winningLine = win.line
            return
        }

        if Self.isDraw(board) {
            gameState = .draw
            winningLine = []
            return
        }

        currentPlayer = currentPlayer.next
    }

    // PUBLIC_INTERFACE
    func reset() {
        /**
         Resets the game to an initial state, clearing the board and setting the current player to X.
         */
        board = Array(repeating: nil, count: 9)
        currentPlayer = .x
        gameState = .playing
        winningLine = []
    }

    var statusText: String {
        switch gameState {
        case .playing:
            return "Turn: \(currentPlayer.rawValue)"
        case .won(let player):
            return "\(player.rawValue) wins!"
        case .draw:
            return "Draw"
        }
    }

    var statusColor: Color {
        switch gameState {
        case .playing:
            return Color.secondary
        case .won:
            return Color(red: 0.02, green: 0.71, blue: 0.83) // #06b6d4
        case .draw:
            return Color(red: 0.39, green: 0.45, blue: 0.55) // #64748b
        }
    }

    private static func isDraw(_ board: [Player?]) -> Bool {
        board.allSatisfy { $0 != nil }
    }

    private static func detectWin(in board: [Player?]) -> (player: Player, line: [Int])? {
        // All winning lines in a 3x3 board
        let lines: [[Int]] = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
            [0, 3, 6], [1, 4, 7], [2, 5, 8], // cols
            [0, 4, 8], [2, 4, 6],            // diagonals
        ]

        for line in lines {
            let a = board[line[0]]
            let b = board[line[1]]
            let c = board[line[2]]
            if let a, a == b, b == c {
                return (a, line)
            }
        }
        return nil
    }
}
