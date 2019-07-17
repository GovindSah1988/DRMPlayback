//
//  ITCommonExtensions.swift
//  IndeeTv
//
//  Created by Govind Sah on 10/06/19.
//  Copyright © 2019 Govind Sah. All rights reserved.
//

import UIKit

extension UIStoryboard {
    /// returns main story board
    class func mainStoryboard() -> UIStoryboard {
        return UIStoryboard(name: ITConstants.ITStoryboardConstants.main, bundle: nil)
    }
}

extension NSObject {
    
    /// Returns class name string
    var className: String {
        return String(describing: type(of: self))
    }
    
    class var className: String {
        return String(describing: self)
    }
}

extension String {
    
    /// append next word to the existing word
    /// with delimiter in between
    func appendNextWord(_ nextWord: String?, delimiter: String) -> String {
        
        // return self in case next word is not there
        guard let nextWord = nextWord, 0 != nextWord.count else {
            return self
        }
        
        var finalWord = self
        
        // in case the first word is empty or nil
        // the final word is the next word itself
        if self.count == 0 {
            finalWord = nextWord
        } else {
            // else append next word to existing word
            finalWord = self + delimiter + nextWord
        }
        return finalWord
    }
}

extension Notification.Name {
    /// Notification for when download progress has changed.
    static let AssetDownloadProgress = Notification.Name(rawValue: "AssetDownloadProgressNotification")
    
    /// Notification for when the download state of an Asset has changed.
    static let AssetDownloadStateChanged = Notification.Name(rawValue: "AssetDownloadStateChangedNotification")
}
