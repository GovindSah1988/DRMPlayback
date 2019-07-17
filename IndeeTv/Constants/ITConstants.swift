//
//  ITConstants.swift
//  IndeeTv
//
//  Created by Govind Sah on 10/06/19.
//  Copyright © 2019 Govind Sah. All rights reserved.
//

import Foundation

struct ITConstants {
    
    /// add all the localized constant here
    struct ITLocalizedStringConstants {
        static let alertOk = "OK"
        static let notDownloadedInfo = "Please first start downloading the content."
        static let cancel = "Cancel"
        static let delete = "Delete"
    }

    /// add all the view identifiers here
    struct ITViewIdentifiers {
        static let contentsVC = "ITContentsViewController"
    }

    /// add all the storyboard name here
    struct ITStoryboardConstants {
        static let main = "Main"
    }

    struct ITPlayerConstants {
        static let persistentId = "skd://fps.ezdrm.com"
        static let assetId = "fps.ezdrm.com"
    }
}

enum ITError: Error {
    case unknown
    case contentFetchingError
}
