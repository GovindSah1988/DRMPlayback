//
//  ITBaseViewController.swift
//  IndeeTv
//
//  Created by Govind Sah on 11/06/19.
//  Copyright © 2019 Govind Sah. All rights reserved.
//

import UIKit

class ITBaseViewController: UIViewController {

    var previousOrientationLock: UIInterfaceOrientationMask! = .all
    var previousRotateOrientation: UIInterfaceOrientation! = .portrait

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            previousRotateOrientation = delegate.rotateOrientation
            previousOrientationLock = delegate.orientationLock
        }
        setupOrientation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetOrientation()
    }
    
    public func setupOrientation() {
        AppUtility.lockOrientation(.portrait)
    }
    
    public func resetOrientation() {
        AppUtility.lockOrientation(previousOrientationLock, andRotateTo: previousRotateOrientation)
    }
    
    /// For hiding the status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
