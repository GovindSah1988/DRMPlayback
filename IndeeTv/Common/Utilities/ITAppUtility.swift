//
//  ITAppUtility.swift
//  IndeeTv
//
//  Created by Govind Sah on 11/06/19.
//  Copyright © 2019 Govind Sah. All rights reserved.
//

import UIKit

struct AppUtility {
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }
    
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
        self.lockOrientation(orientation)
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.rotateOrientation = rotateOrientation
        }
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
    }
}
