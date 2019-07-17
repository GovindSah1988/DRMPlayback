//
//  ITDownloadManager.swift
//  IndeeTv
//
//  Created by Govind Sah on 11/06/19.
//  Copyright © 2019 Govind Sah. All rights reserved.
//

import UIKit
import AVFoundation

class ITDownloadManager: NSObject {
    // MARK: Properties
    
    /// Singleton for ITDownloadManager.
    static let sharedManager = ITDownloadManager()
    
    /// The AVAssetDownloadURLSession to use for managing AVAssetDownloadTasks.
    fileprivate var assetDownloadURLSession: AVAssetDownloadURLSession!
    
    /// Internal map of AVAggregateAssetDownloadTask to its corresponding Asset.
    /// to find the dowloading status of the active downloading contents
    fileprivate var activeDownloadsMap = [AVAggregateAssetDownloadTask: ITMedia]()
    
    /// Internal map of AVAggregateAssetDownloadTask to download URL.
    /// to save the local URL path for the downloading content.
    fileprivate var willDownloadToUrlMap = [AVAggregateAssetDownloadTask: URL]()
    
    private let queue = DispatchQueue(label: "com.indeeTv.fairplay.download.queue")
        
    // MARK: Intialization
    
    override private init() {
        
        super.init()
        
        // Create the configuration for the AVAssetDownloadURLSession.
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "com.indeeTv.Background.Identifier")
        
        // Create the AVAssetDownloadURLSession using the configuration.
        assetDownloadURLSession =
            AVAssetDownloadURLSession(configuration: backgroundConfiguration,
                                      assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
    }
    
    /// Triggers the initial AVAssetDownloadTask for a given Asset.
    /// - Tag: DownloadStream
    func downloadStream(for media: ITMedia) {
        
        guard let url = URL(string: media.offlineUrl) else {
            print("No URL To Download??")
            return
        }
        let asset = AVURLAsset(url: url)

        // For Downloading the FPS Key
        downloadFPSKey(content: media)
        
        // Get the default media selections for the asset's media selection groups.
        let preferredMediaSelection = asset.preferredMediaSelection
        
        /*
         Creates and initializes an AVAggregateAssetDownloadTask to download multiple AVMediaSelections
         on an AVURLAsset.
         
         For the initial download, we ask the URLSession for an AVAssetDownloadTask with a minimum bitrate
         corresponding with one of the lower bitrate variants in the asset.
         */
        guard let task =
            assetDownloadURLSession.aggregateAssetDownloadTask(with: asset,
                                                               mediaSelections: [preferredMediaSelection],
                                                               assetTitle: media.id,
                                                               assetArtworkData: nil,
                                                               options:
                [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000]) else { return }
        
        // To better track the AVAssetDownloadTask, set the taskDescription to something unique for the sample.
        task.taskDescription = media.id
        
        activeDownloadsMap[task] = media
        
        task.resume()
        
        var userInfo = [String: Any]()
        userInfo[ITMedia.Keys.name] = media.id
        userInfo[ITMedia.Keys.downloadState] = ITMedia.DownloadState.downloading.rawValue
        
        NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
    }
    
    /// Returns an Asset pointing to a file on disk if it exists.
    func localAssetForStream(withId id: String) -> (ITMedia?, AVURLAsset?)? {
        let userDefaults = UserDefaults.standard
        guard let localFileLocation = userDefaults.value(forKey: id) as? Data else { return nil }
        var asset: ITMedia?
        var bookmarkDataIsStale = false
        do {
            let url = try URL(resolvingBookmarkData: localFileLocation,
                              bookmarkDataIsStale: &bookmarkDataIsStale)
            
            if bookmarkDataIsStale {
                fatalError("Bookmark data is stale!")
            }
            
            let urlAsset = AVURLAsset(url: url)
            print("localFileLocation = ", localFileLocation, urlAsset.url)
            asset = ITMedia(id: id)
            return (asset, urlAsset)
        } catch {
            fatalError("Failed to create URL from bookmark with error: \(error)")
        }
    }
    
    /// Returns the current download state for a given Asset.
    func downloadState(for media: ITMedia) -> ITMedia.DownloadState {
        // Check if there is a file URL stored for this asset.
        if let (_, urlAsset) = localAssetForStream(withId: media.id), let localFileLocation = urlAsset?.url {
            // Check if the file exists on disk
            if FileManager.default.fileExists(atPath: localFileLocation.path) {
                return .downloaded
            }
        }
        
        // Check if there are any active downloads in flight.
        for (_, assetValue) in activeDownloadsMap where media.id == assetValue.id {
            return .downloading
        }
        
        return .notDownloaded
    }
    
    /// Deletes an Asset on disk if possible.
    /// - Tag: RemoveDownload
    func deleteAsset(media: ITMedia) {
        let userDefaults = UserDefaults.standard
        
        do {
            if let (_, urlAsset) = localAssetForStream(withId: media.id), let localFileLocation = urlAsset?.url {
                try FileManager.default.removeItem(at: localFileLocation)
                
                userDefaults.removeObject(forKey: media.offlineUrl)
                userDefaults.removeObject(forKey: media.id)
                
                var userInfo = [String: Any]()
                userInfo[ITMedia.Keys.name] = media.id
                userInfo[ITMedia.Keys.downloadState] = ITMedia.DownloadState.notDownloaded.rawValue
                
                NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil,
                                                userInfo: userInfo)
            }
        } catch {
            print("An error occured deleting the file: \(error)")
        }
    }
    
    /// Cancels an AVAssetDownloadTask given an Asset.
    /// - Tag: CancelDownload
    func cancelDownload(for media: ITMedia) {
        var task: AVAggregateAssetDownloadTask?
        
        for (taskKey, assetVal) in activeDownloadsMap where media.id == assetVal.id {
            task = taskKey
            break
        }
        
        task?.cancel()
    }
    
    /// For downloding the FPS Key and storing it locally
    private func downloadFPSKey(content: ITMedia) {
        let contentKeySession = AVContentKeySession(keySystem: AVContentKeySystem.fairPlayStreaming)
        if let licenseHandler = FPSLicenseHelper(media: content, certificateData: nil, contentKeySession: contentKeySession, queue: queue) {
            licenseHandler.handleLicenseRequest { (error) in
                if nil != error {
                    print("Error")
                }
            }
        }
    }
}

/**
 Extend `ITDownloadManager` to conform to the `AVAssetDownloadDelegate` protocol.
 */
extension ITDownloadManager: AVAssetDownloadDelegate {
    
    /// Tells the delegate that the task finished transferring data.
    /// Method 4
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let userDefaults = UserDefaults.standard
        
        print("task delegate didCompleteWithError")
        /*
         This is the ideal place to begin downloading additional media selections
         once the asset itself has finished downloading.
         */
        guard let task = task as? AVAggregateAssetDownloadTask,
            let asset = activeDownloadsMap.removeValue(forKey: task) else { return }
        
        guard let downloadURL = willDownloadToUrlMap.removeValue(forKey: task) else { return }
        
        // Prepare the basic userInfo dictionary that will be posted as part of our notification.
        var userInfo = [String: Any]()
        userInfo[ITMedia.Keys.name] = asset.id
        
        if let error = error as NSError? {
            switch (error.domain, error.code) {
            case (NSURLErrorDomain, NSURLErrorCancelled):
                /*
                 This task was canceled, you should perform cleanup using the
                 URL saved from AVAssetDownloadDelegate.urlSession(_:assetDownloadTask:didFinishDownloadingTo:).
                 */
                guard let (_, urlAsset) = localAssetForStream(withId: asset.id), let localFileLocation = urlAsset?.url else { return }
                
                do {
                    try FileManager.default.removeItem(at: localFileLocation)
                    
                    userDefaults.removeObject(forKey: asset.id)
                } catch {
                    print("An error occured trying to delete the contents on disk for \(asset.id): \(error)")
                }
                
                userInfo[ITMedia.Keys.downloadState] = ITMedia.DownloadState.notDownloaded.rawValue
                
            case (NSURLErrorDomain, NSURLErrorUnknown):
                fatalError("Downloading HLS streams is not supported in the simulator.")
                
            default:
                fatalError("An unexpected error occured \(error.domain)")
            }
        } else {
            do {
                let bookmark = try downloadURL.bookmarkData()
                
                userDefaults.set(bookmark, forKey: asset.id)
            } catch {
                print("Failed to create bookmarkData for download URL.")
            }
            
            userInfo[ITMedia.Keys.downloadState] = ITMedia.DownloadState.downloaded.rawValue
        }
        
        NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
    }
    
    /// Method called when the an aggregate download task determines the location this asset will be downloaded to.
    /// Method 1
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                    willDownloadTo location: URL) {
        
        print("task delegate aggregateAssetDownloadTask willDownloadTo")

        /*
         This delegate callback should only be used to save the location URL
         somewhere in your application. Any additional work should be done in
         `URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:)`.
         */
        
        willDownloadToUrlMap[aggregateAssetDownloadTask] = location
    }
    
    /// Method called when a child AVAssetDownloadTask completes.
    /// Method 3
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                    didCompleteFor mediaSelection: AVMediaSelection) {
        
        print("task delegate aggregateAssetDownloadTask didCompleteFor")

        /*
         This delegate callback provides an AVMediaSelection object which is now fully available for
         offline use. You can perform any additional processing with the object here.
         */
        
        guard let asset = activeDownloadsMap[aggregateAssetDownloadTask] else { return }
        
        // Prepare the basic userInfo dictionary that will be posted as part of our notification.
        var userInfo = [String: Any]()
        userInfo[ITMedia.Keys.name] = asset.id
        
        aggregateAssetDownloadTask.taskDescription = asset.id
        
        aggregateAssetDownloadTask.resume()
        
        userInfo[ITMedia.Keys.downloadState] = ITMedia.DownloadState.downloading.rawValue
        
        NotificationCenter.default.post(name: .AssetDownloadStateChanged, object: nil, userInfo: userInfo)
    }
    
    /// Method to adopt to subscribe to progress updates of an AVAggregateAssetDownloadTask.
    /// Method 2
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                    didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                    timeRangeExpectedToLoad: CMTimeRange, for mediaSelection: AVMediaSelection) {
        
        print("task delegate aggregateAssetDownloadTask didLoad timeRange: CMTimeRange, totalTimeRangesLoaded")

        // This delegate callback should be used to provide download progress for your AVAssetDownloadTask.
        guard let asset = activeDownloadsMap[aggregateAssetDownloadTask] else { return }
        
        var percentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange: CMTimeRange = value.timeRangeValue
            percentComplete +=
                loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
            print("Percentage completed = \(percentComplete)")
        }
        
        var userInfo = [String: Any]()
        userInfo[ITMedia.Keys.name] = asset.id
        userInfo[ITMedia.Keys.percentDownloaded] = percentComplete
        
        NotificationCenter.default.post(name: .AssetDownloadProgress, object: nil, userInfo: userInfo)
    }
}
