//
//  ITPlayerViewController.swift
//  IndeeTv
//
//  Created by Govind Sah on 11/06/19.
//  Copyright © 2019 Govind Sah. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ITPlayerViewController: ITBaseViewController {

    var media: ITMedia!
    var player: ITFairplayPlayer!
    var playerViewController: AVPlayerViewController!
    
    /// to load the AVPlayer over the playerContainerView
    @IBOutlet weak var playerContainerView: UIView!
    
    init(media: ITMedia) {
        self.media = media
        super.init(nibName: ITPlayerViewController.className, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        initialSetup()
    }
    
    // overriding the orientation behaviour
    override func setupOrientation() {
        AppUtility.lockOrientation(.landscape, andRotateTo: .landscapeLeft)
    }

    private func initialSetup() {
        setupInitialPlayerView()
    }
    
    @IBAction func closePlayerTapped(_ sender: Any) {
        cleanupPlayer()
        ITPlayerManager.shared.closePlayer()
    }
    
    // remove AVPlayer
    private func cleanupPlayer() {
        
        // to remove the content
        player.stop()
        playerViewController.view.removeFromSuperview()
    }

    /// MARK: Player Calls
    
    private func setupInitialPlayerView() {
        if nil == player {
            player = ITFairplayPlayer()
            self.playerViewController = AVPlayerViewController()
            let playerFrame = CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
            print("**Test Player Frame = \(playerFrame)")
            print("**Test Screen Frame = \(UIScreen.main.bounds)")
            playerViewController.player = player
            playerViewController.view.bounds = playerFrame
            playerContainerView.addSubview(playerViewController.view)
            
//            let leftConstraint = NSLayoutConstraint.init(item: playerViewController.view!, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: playerContainerView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: 0)
//            let rightConstraint = NSLayoutConstraint.init(item: playerViewController.view!, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: playerContainerView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: 0)
//            let topConstraint = NSLayoutConstraint.init(item: playerViewController.view!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: playerContainerView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0)
//            let bottomConstraint = NSLayoutConstraint.init(item: playerViewController.view!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: playerContainerView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0)
//
//            playerContainerView.addConstraints([leftConstraint, rightConstraint, topConstraint, bottomConstraint])

            // load the player
            loadMedia(media: media)
        } else {
            let playerFrame = CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
            playerViewController.view.bounds = playerFrame
        }
    }
    
    private func loadMedia(media: ITMedia) {
        player.play(media)
    }
}
