//
//  ITPlayerManager.swift
//  IndeeTv
//
//  Created by Govind Sah on 11/06/19.
//  Copyright © 2019 Govind Sah. All rights reserved.
//

import UIKit
import AVFoundation

class ITPlayerManager: NSObject {
    
    static let shared = ITPlayerManager()
    
    var playerVC: ITPlayerViewController?
    
    override init() {
        super.init()
        do {
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)), mode: AVAudioSession.Mode.default)
            } else {
                // Fallback on earlier versions
            }
        } catch {}
    }

    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
        return input.rawValue
    }
    
    func playVideo(source: ITMedia) {
        self.initializeWatchPageViewController(source: source)
        self.addWatchPageToWindow()
    }

    func closePlayer() {
        
        playerVC?.didMove(toParent: nil)
        
        // cleanup Player related stuff        
        playerVC?.view.removeFromSuperview()
        
        playerVC = nil
    }
    
    /// Helper Methods
    
    private func addWatchPageToWindow() {
        guard let appDel = UIApplication.shared.delegate as? AppDelegate, let window = appDel.window, let rootViewController = window.rootViewController, let playerVC = playerVC else { return }
        rootViewController.view.addSubview(playerVC.view)
        playerVC.didMove(toParent: rootViewController)
    }
    
    private func initializeWatchPageViewController(source: ITMedia) {
        playerVC = ITPlayerViewController(media: source)
        playerVC?.view.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: playerSize())
    }
    
    private func playerSize() -> CGSize {
        let size = CGSize(width: UIScreen.main.bounds.size.height, height: UIScreen.main.bounds.size.width)
        return size
    }

}
