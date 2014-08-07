//
//  ViewController.swift
//  ticTacToe
//
//  Created by Johnny Sparks on 8/4/14.
//  Copyright (c) 2014 beergrammer. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let game:Game = Game(size:3, startingPlayer:Player.X)
    var boardView:BoardView?
    let restartButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        boardView = BoardView(frame: view.frame, board: game)
        boardView!.setTranslatesAutoresizingMaskIntoConstraints(false)
        boardView!.frame = self.view.frame
        boardView!.render()

        restartButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        restartButton.setTitle("Restart", forState: .Normal)
        restartButton.setTitleColor(UIColor.purpleColor(), forState: .Normal)
        restartButton.addTarget(self, action: "clearBoard", forControlEvents: .TouchUpInside)
        
        boardView!.onTileTapped = { pos in
            self.game.place(Piece(player: Player.O, position: pos))
        }
        
        game.onGameStatusChange = { status in

            var title   = GameStatus.Owin == status ? "Victory" : "You lose!"
            var message = GameStatus.Owin == status ? "... not sure how that happened" : "uh"
            
            UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: "").show()
            
            self.clearBoard()
        }
        
        game.onPiecePlayed = {
            self.boardView!.render()
        }
        
        self.view.addSubview(boardView)
        self.view.addSubview(restartButton)
        
        let views = ["restart":restartButton,"board": boardView! ]
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[restart][board]|", options: nil, metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[board]|", options: nil, metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[restart]|", options: nil, metrics: nil, views: views))
        self.view.addConstraint(NSLayoutConstraint(item: boardView!, attribute: .Height, relatedBy: .Equal, toItem: boardView!, attribute: .Width, multiplier: 1, constant: 0))
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        boardView!.render()
    }
    
    func clearBoard() {
        game.clear()
        boardView!.render()
    }
}

