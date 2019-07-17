//
//  ITMedia.swift
//  IndeeTv
//
//  Created by Govind Sah on 10/06/19.
//  Copyright © 2019 Govind Sah. All rights reserved.
//

import Foundation

struct OnlineContentsResponse: Decodable {
    var assets: [ITMedia]?
    
    enum OnlineContentsConstantKeys: String, CodingKey {
        case assets = "assets"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: OnlineContentsConstantKeys.self)
        self.assets = try container.decode([ITMedia].self, forKey: .assets)
    }
}

struct ITMedia {
    var title: String
    var ageRestriction: String?
    var id: String
    var offlineUrl: String
    var fpSpcUrl: String?
    var certificateUrl: String?
    var locally: Bool = false
    var assetId: String? = ITConstants.ITPlayerConstants.assetId
    
    var isDRMProtected: Bool {
        return true
    }
    
    private var genres: [String]
    var genre: String {
        if genres.count > 0 {
            return genres.joined(separator: ", ")
        }
        return ""
    }
    
    var downloadedLocationBaakmarkData: Data? {
        return UserDefaults.standard.data(forKey: self.id)
    }
    
    var downloadedState: DownloadState {
        return ITDownloadManager.sharedManager.downloadState(for: self)
    }
    
    init(id: String) {
        self.id = id
        self.ageRestriction = nil
        self.offlineUrl = ""
        self.fpSpcUrl = nil
        self.certificateUrl = nil
        self.title = ""
        self.genres = []
    }
}

extension ITMedia: Decodable {
    
    enum MediaContentsConstantKeys: String, CodingKey {
        case title = "title"
        case customData = "custom data"
        case drmData = "drm"
        case offlineUrl = "offline_ios_file"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MediaContentsConstantKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        let customData = try container.decode(CustomData.self, forKey: .customData)
        self.id = customData.customValue
        self.genres = customData.genres
        self.ageRestriction = customData.ageRestriction
        let drmData = try container.decode(DRM.self, forKey: .drmData)
        self.fpSpcUrl = drmData.fairPlay.spcUrl
        self.certificateUrl = drmData.fairPlay.certificateUrl
        self.offlineUrl = try container.decode(String.self, forKey: .offlineUrl)
    }
    
}

fileprivate struct CustomData: Decodable {
    
    var customValue: String
    var genres: [String]
    var ageRestriction: String?
    
    enum CustomDataConstantKeys: String, CodingKey {
        case customValue = "custom value"
        case ageRestriction = "ageRestriction"
        case genres = "genres"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CustomDataConstantKeys.self)
        self.customValue = try container.decode(String.self, forKey: .customValue)
        self.ageRestriction = try container.decode(String.self, forKey: .ageRestriction)
        self.genres = try container.decode([String].self, forKey: .genres)
    }
}

fileprivate struct DRM: Decodable {
    
    var fairPlay: FairPlay
    
    enum DRMConstantKeys: String, CodingKey {
        case fairplay = "fairplay"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DRMConstantKeys.self)
        self.fairPlay = try container.decode(FairPlay.self, forKey: .fairplay)
    }
}

fileprivate struct FairPlay: Decodable {
    
    var spcUrl: String
    var certificateUrl: String

    enum DRMConstantKeys: String, CodingKey {
        case spcUrl = "processSpcUrl"
        case certificateUrl = "certificateUrl"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DRMConstantKeys.self)
        self.spcUrl = try container.decode(String.self, forKey: .spcUrl)
        self.certificateUrl = try container.decode(String.self, forKey: .certificateUrl)
    }
}

/**
 Extends `ITMedia` to define a number of values to use as keys in dictionary lookups.
 */
extension ITMedia {
    struct Keys {
        /**
         Key for the ITMedia name, used for `AssetDownloadProgressNotification` and
         `AssetDownloadStateChangedNotification` Notifications as well as
         AssetListManager.
         */
        static let name = "AssetNameKey"
        
        /**
         Key for the Asset download percentage, used for
         `AssetDownloadProgressNotification` Notification.
         */
        static let percentDownloaded = "AssetPercentDownloadedKey"
        
        /**
         Key for the Asset download state, used for
         `AssetDownloadStateChangedNotification` Notification.
         */
        static let downloadState = "AssetDownloadStateKey"
        
    }
}

/**
 Extends `ITMedia` to add a simple download state enumeration used by the sample
 to track the download states of ITMedias.
 */
extension ITMedia {
    enum DownloadState: String {
        
        /// The asset is not downloaded at all.
        case notDownloaded
        
        /// The asset has a download in progress.
        case downloading
        
        /// The asset is downloaded and saved on diek.
        case downloaded
    }
}
