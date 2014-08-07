//
//  ticTacToe.swift
//  ticTacToe
//
//  Created by Johnny Sparks on 8/4/14.
//  Copyright (c) 2014 beergrammer. All rights reserved.
//


func printIntGrid(value:UInt, char:String) {
    func p(i:UInt) -> String {
        return (value & i) == i ? char : "-"
    }
    
    var out  = "\(p(1))\(p(2))\(p(4))\n"
        out += "\(p(8))\(p(16))\(p(32))\n"
        out += "\(p(64))\(p(128))\(p(256))\n"
    
    println(out)
}

import Foundation
import UIKit


class BobbyFisher {
    
    var memory:[GameState:Int] = [GameState:Int]()
    
    func nextPieceToPlayFromGameState(gameState:GameState) -> Piece? {
        var piece:Piece?
        var score = 0

        for child in gameState.childStates() {
            if !piece {
                piece = child.lastPiece!
            }

            let childScore = minimaxState(child, depth:4, player: child.lastPiece!.player, maximize: true)
            if childScore > score {
                score = childScore
                piece = child.lastPiece!
            }
        }
        
        return piece
    }

    
    func minimaxState(state:GameState, depth:Int, player:Player, maximize:Bool) -> Int {
        
        if let score = memory[state] {
            return score
        }
        
        let wins = state.winsFor(maximize ? player : player.otherPlayer())
        let pairs = state.pairsFor(maximize ? player : player.otherPlayer())
//        let fullBoard = state.boardIsFull()
        
        let score = Int(wins * 100 + pairs)
        
        if score > 0 || depth == 0 {
            memory[state] = score
            return score
        }
        
        if maximize {
            var maxScore = -Int.max
            for child in state.childStates() {
                let childScore = minimaxState(child, depth: depth - 1, player: player, maximize: false)
                maxScore = max(maxScore, childScore)
            }
            return maxScore
        }
            
        else {
            var minScore = Int.max
            for child in state.childStates() {
                let childScore = minimaxState(child, depth: depth - 1, player: player, maximize: true)
                minScore = min(minScore, childScore)
            }

            return minScore
        }
    }
}


func == (lhs:GameState, rhs:GameState) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

struct GameState : Hashable {
    var pieces:[Piece]
    var Xs:UInt = 0
    var Os:UInt = 0
    
    init(pieces:[Piece]) {
        self.pieces = []
        for piece in pieces {
            self.addPiece(piece)
        }
    }
    
    var hashValue:Int {
        get {
            return Int(Xs * 100000 + Os)
        }
    }
    
    var lastPiece:Piece? {
        get {
            if( pieces.isEmpty ) {
                return nil
            }
            else {
                return pieces[pieces.count - 1]
            }
        }
    }
    
    func turn() -> Player {
        if lastPiece {
            return lastPiece!.player.otherPlayer()
        }
        else {
            return Player.O
        }
    }
    
    mutating func addPiece(piece:Piece) {
        pieces.append(piece)
        if piece.player == .X {
            Xs += piece.position.toBoardUInt()
        }
        else {
            Os += piece.position.toBoardUInt()
        }
    }
    
    func boardIsFull() -> Bool {
        return pieces.count >= 9
    }
    
    func canPlayPiece(piece:Piece) -> Bool {

        // Don't care who goes first
        if !lastPiece {
            return true
        }
        
        // can't go twice
        if piece.player == lastPiece!.player {
            return false
        }
        
        let pos = piece.position
        if pos.col >= 3 || pos.row >= 3 || pos.row < 0 || pos.col < 0 {
            return false
        }
        
        if (Xs & pos.toBoardUInt()) == pos.toBoardUInt() || (Os & pos.toBoardUInt()) == pos.toBoardUInt() {
            return false
        }   
        
        return true
    }
    
    func childStates() -> [GameState] {
        
        var states:[GameState] = []
        
        for col in 0...2 {
            for row in 0...2 {
                var lastPlayer = Player.X
                if !pieces.isEmpty {
                    lastPlayer = self.lastPiece!.player
                }
                
                let piece = Piece(player: lastPlayer.otherPlayer(), position: Position(row: row, col: col))
                
                if canPlayPiece(piece) {
                    var nextState = copy()
                    nextState.addPiece(piece)
                    states.append(nextState)
                }
            }
        }
        return states
    }
    
    //
    // I was storing all of the pieces in arrays of arrays,
    // and iterating to check for wins. But because my minimax
    // algo is completely unoptimized,
    // I opted for changing the data structure
    //
    // A tic tac toe board can be stored in one UInt32.
    // But I think separating the Xs and Os is more readable
    //
    // The board state would look like this
    //
    //    1  | 2   | 4
    //    --------------
    //    8  | 16  | 32
    //    --------------
    //    64 | 128 | 256
    //
    // Then use bitwise operators to check for matches
    //
    
    func winsFor(player:Player) -> Int {
        
        var wins:UInt = 0
        var boardInt = player == .X ? Xs : Os
        
        // Row Wins
        
        wins += (1  + 2   + 4)   == (boardInt & (1  + 2   + 4))   ? 1 : 0
        wins += (8  + 16  + 32)  == (boardInt & (8  + 16  + 32))  ? 1 : 0
        wins += (64 + 128 + 256) == (boardInt & (64 + 128 + 256)) ? 1 : 0
        
        // column wins
        wins += (1 + 8  + 64)  == (boardInt & (1 + 8  + 64))    ? 1 : 0
        wins += (2 + 16 + 128) == (boardInt & (2 + 16 + 128))   ? 1 : 0
        wins += (4 + 32 + 256) == (boardInt & (4 + 32 + 256))   ? 1 : 0
        
        // diagonal wins
        wins += (1 + 16 + 256)  == (boardInt & (1 + 16 + 256))   ? 1 : 0
        wins += (4 + 16 + 64)   == (boardInt & (4 + 16 + 64))    ? 1 : 0
        
        if wins > 0 {
            printIntGrid(Xs, "x")
            printIntGrid(Os, "o")
        }
        
        return Int(wins)
    }
    
    func pairsFor(player:Player) -> Int {
        
        var pairs:UInt = 0
        var boardInt = player == .X ? Xs : Os
        
        // Row Pairs
        pairs += (1  + 2   + 0)   == (boardInt & (1  + 2   + 0))   ? 1 : 0
        pairs += (1  + 0   + 4)   == (boardInt & (1  + 0   + 4))   ? 1 : 0
        pairs += (0  + 2   + 4)   == (boardInt & (0  + 2   + 4))   ? 1 : 0
        
        pairs += (8  + 16  + 0)  == (boardInt & (8  + 16  + 0))  ? 1 : 0
        pairs += (8  + 0  + 32)  == (boardInt & (8  + 0   + 32))  ? 1 : 0
        pairs += (0  + 16  + 32) == (boardInt & (0  + 16  + 32))  ? 1 : 0
        
        pairs += (64 + 128  + 0) == (boardInt & (64 + 128 + 0)) ? 1 : 0
        pairs += (64 +  0 + 256) == (boardInt & (64 + 0 + 256)) ? 1 : 0
        pairs += (0 + 128 + 256) == (boardInt & (0 + 128 + 256)) ? 1 : 0

        
        // Column Pairs
        pairs += (1 + 8  + 0)   == (boardInt & (1 + 8  + 0))    ? 1 : 0
        pairs += (1 + 0  + 64)  == (boardInt & (1 + 0  + 64))    ? 1 : 0
        pairs += (0 + 8  + 64)  == (boardInt & (0 + 8  + 64))    ? 1 : 0

        pairs += (2 + 16 +  0)  == (boardInt & (2 + 16 + 0))   ? 1 : 0
        pairs += (2 + 0  + 128) == (boardInt & (2 + 0 + 128))   ? 1 : 0
        pairs += (0 + 16 + 128) == (boardInt & (0 + 16 + 128))   ? 1 : 0

        pairs += (4 + 32 + 0)   == (boardInt & (4 + 32 + 0))   ? 1 : 0
        pairs += (4 + 0 + 256)  == (boardInt & (4 + 0 + 256))   ? 1 : 0
        pairs += (0 + 32 + 256) == (boardInt & (0 + 32 + 256))   ? 1 : 0

        
        // diagonal wins
        pairs += (1 + 16 + 0)  == (boardInt & (1 + 16 + 0))   ? 1 : 0
        pairs += (1 + 0 + 256)  == (boardInt & (1 + 0 + 256))   ? 1 : 0
        pairs += (0 + 16 + 256)  == (boardInt & (0 + 16 + 256))   ? 1 : 0

        pairs += (4 + 16 + 0)   == (boardInt & (4 + 16 + 0))    ? 1 : 0
        pairs += (4 + 0 + 64)   == (boardInt & (4 + 0 + 64))    ? 1 : 0
        pairs += (0 + 16 + 64)   == (boardInt & (0 + 16 + 64))    ? 1 : 0

        return Int(pairs)
    }
    
    func copy() -> GameState {
        let state = GameState(pieces: pieces)
        return state
    }
}


enum GameStatus {
    case Xwin, Owin, Tied, Playing
}

enum Diagonal {
    case NWtoSE, SWtoNE
}

enum Player {
    case X, O
    
    func otherPlayer() -> Player {
        if self == .X {
            return .O
        }
        return .X
    }
    
    func toString() -> String {
        if self == .X {
            return "x"
        }
        return "o"
    }
}

struct Position {
    let row:Int
    let col:Int
    
    init(row:Int, col:Int){
        self.row = row
        self.col = col
    }
    
    func toBoardUInt() -> UInt {
        let power = row * 3 + col
        var val = 1
        
        for _ in 0...power-1 {
            val *= 2
        }
        return UInt(val)
    }
}

struct Piece {
    let player:Player
    let position:Position
}


class Game {
    let size:Int
    var states:[GameState] = []
    var gameStatus:GameStatus = .Playing
    
    var onPiecePlayed: ()->() = {}
    var onGameStatusChange: (GameStatus)->() = { status in }
    
    init(size:Int, startingPlayer:Player) {
        self.size = size
    }
    
    func currentGameState() -> GameState {
        if states.count > 0 {
            return states[states.count - 1]
        }
        return GameState(pieces: [])
    }
    
    func clear() {
        states = []
    }
    
    func playPiece(piece:Piece) -> GameStatus {
        if !currentGameState().canPlayPiece(piece) {
            return gameStatus
        }
        
        var newState = currentGameState()
        newState.addPiece(piece)
        states.append(newState)
        self.onPiecePlayed()
        
        if newState.winsFor(piece.player) >= 1 {
            gameStatus = (piece.player == .X) ? .Xwin : .Owin
            self.onGameStatusChange(gameStatus)
            return gameStatus
        }
        
        return gameStatus
    }
    
    func beginAImove() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            let state = self.currentGameState()
            
            let bobbyPiece = BobbyFisher().nextPieceToPlayFromGameState(state)
            
            dispatch_async(dispatch_get_main_queue(), {
                
                if bobbyPiece {
                    
                    if self.currentGameState().canPlayPiece(bobbyPiece!) {
                        self.playPiece(bobbyPiece!)
                    } else {
                        self.beginAImove()
                    }
                    
                }
            })
        })
    }
    
    func place(piece:Piece) {
        
        self.playPiece(piece)
        
        self.beginAImove()
    }
}



class BoardView: UIView {
    var board:Game
    
    var onTileTapped:(pos:Position) -> ()
    
    // local vars
    var tileViews:[[UIView]] = []
    var tapRecognizer:UITapGestureRecognizer?
    
    init(frame: CGRect, board:Game){
        self.board = board
        
        for col in 0...board.size {
            
            var tileRowViews:[UIView] = []
            
            for row in 0...board.size {
                var tileView = UIView(frame: CGRectZero)
                tileRowViews += tileView
            }
            
            tileViews += tileRowViews
        }
        
        self.onTileTapped = {(pos:Position) in }
        
        super.init(frame: frame)
        
        userInteractionEnabled = true
        clipsToBounds = true
        
        tapRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        addGestureRecognizer(tapRecognizer)
    }
    
    func handleTap(sender: UITapGestureRecognizer){
        let point = sender.locationInView(self)
        let col = Int(floor((point.x / frame.width) * CGFloat(board.size)))
        let row = Int(floor((point.y / frame.height) * CGFloat(board.size)))
        self.onTileTapped(pos:Position(row:row, col:col))
    }
    
    func render() {
        for subview in subviews {
            subview.removeFromSuperview()
        }
        
        drawBoard()
        drawPieces()
    }
    
    func drawPieces(){
        for p in board.currentGameState().pieces {
            draw(p)
        }
    }
    
    func draw(piece:Piece){    
        let frame = rectForTileAt(piece.position.row, piece.position.col)
        let pieceView = UIView(frame: frame)
        pieceView.layer.cornerRadius = frame.width / 2.0
        pieceView.backgroundColor = piece.player == .X ? UIColor.orangeColor() : UIColor.blueColor()
        self.addSubview(pieceView)
    }
    
    func rectForTileAt(row:Int, _ col:Int) -> CGRect {
        let size = tileSize()
        return CGRectMake(CGFloat(col) * size.width, CGFloat(row) * size.height, size.width, size.height)
    }
    
    func tileSize() -> CGSize {
        let w = frame.size.width / CGFloat(board.size)
        let h = frame.size.height / CGFloat(board.size)
        
        return CGSize(width: w, height: h)
    }
    
    func drawBoard(){
        var columns = board.size
        var rows = board.size
        
        let size = tileSize()
        let w = size.width
        let h = size.height
        
        for row:Int in 0...rows {
            for col:Int in 0...columns {
                tileViews[row][col].frame = rectForTileAt(row, col)
                tileViews[row][col].backgroundColor = colorAt(row, col)
            }
        }
        
        for tileRowViews in tileViews {
            for tileView in tileRowViews {
                self.addSubview(tileView)
            }
        }
    }
    
    func colorAt( row:Int, _ col:Int) -> UIColor {
        return ((row % 2 == 0) && !(col % 2 == 0)) || (!(row % 2 == 0) && (col % 2 == 0)) ? UIColor.whiteColor() : UIColor.lightGrayColor()
    }
}


