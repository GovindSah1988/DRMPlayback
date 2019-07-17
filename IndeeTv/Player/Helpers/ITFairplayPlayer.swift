//
//  ITFairplayPlayer.swift
//  IndeeTv
//
//  Created by Govind Sah on 11/06/19.
//  Copyright © 2019 Govind Sah. All rights reserved.
//

import UIKit
import AVFoundation

class ITFairplayPlayer: AVPlayer {
    
    private var media: ITMedia!
    private let queue = DispatchQueue(label: "com.indeeTv.fairplay.queue")
    var contentKeySession: AVContentKeySession!
    var asset: AVURLAsset!
    
    func play(_ media: ITMedia) {
        
        if true == media.locally, let (_ , avAsset1) = ITDownloadManager.sharedManager.localAssetForStream(withId: media.id), let avAsset = avAsset1 {
            
            self.media = media
            self.asset = avAsset
            
            // load the downloaded FPS Key for playing the content
            loadFPSKey()
            
            // Load the asset in the player.
            let item = AVPlayerItem(asset: asset)
            
            // Set the current item in this player instance.
            replaceCurrentItem(with: item)
            
            // Start playing the item. From the moment the `play` is triggered the `resourceLoader` will
            // do the rest of the work.
            play()
        } else {
            guard let url = URL(string: media.offlineUrl) else {
                print("No URL To Play??")
                return
            }
            
            self.media = media
            asset = AVURLAsset(url: url)
            
            // Set the resource loader delegate to this class. The `resourceLoader`'s delegate will be
            // triggered when FairPlay handling is required.
            asset.resourceLoader.setDelegate(self, queue: queue)
            
            // Load the asset in the player.
            let item = AVPlayerItem(asset: asset)
            
            // Set the current item in this player instance.
            replaceCurrentItem(with: item)
            
            // Start playing the item. From the moment the `play` is triggered the `resourceLoader` will
            // do the rest of the work.
            play()

        }

    }
    
    /// For stopping the content
    func stop() {
        replaceCurrentItem(with: nil)
    }
    
    // For loading the FPS Key for playing the offline content
    func loadFPSKey() {
        contentKeySession = AVContentKeySession(keySystem: AVContentKeySystem.fairPlayStreaming)
        contentKeySession.setDelegate(self, queue: queue)
        contentKeySession.processContentKeyRequest(withIdentifier: ITConstants.ITPlayerConstants.persistentId, initializationData: nil, options: nil)
        contentKeySession.addContentKeyRecipient(asset)
    }
}

extension ITFairplayPlayer: AVContentKeySessionDelegate {
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) {
        keyRequest.respondByRequestingPersistableContentKeyRequest()
    }
    
    //used for only persistent/offline related Downloding of FPS Key
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVPersistableContentKeyRequest) {
        if media.locally {
            if let data = UserDefaults.standard.data(forKey: self.media.offlineUrl) {
                let response = AVContentKeyResponse(fairPlayStreamingKeyResponseData: data)
                keyRequest.processContentKeyResponse(response)
                return
            }
        }
    }
}

extension ITFairplayPlayer: AVAssetResourceLoaderDelegate {
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        // We first check if a url is set in the manifest.
        guard let url = loadingRequest.request.url else {
            loadingRequest.finishLoading(with: NSError(domain: "com.indeeTv.error", code: -1, userInfo: nil))
            return false
        }
        
        // Check if the content has proper contentId to make SPC request
        guard let contentId = url.host else {
            loadingRequest.finishLoading(with: NSError(domain: "com.indeeTv.error", code: -2, userInfo: nil))
            return false
        }

        // When the url is correctly found we try to load the certificate date. Watch out! For this
        // example the certificate resides inside the bundle. But it should be preferably fetched from
        // the server.
        fetchCertificateData { (data, error) in
            if nil == error, let certificateData = data {
                
                var options: [String: AnyObject]? = nil
                
                if #available(iOS 10.0, *) {
                    options = [AVAssetResourceLoadingRequestStreamingContentKeyRequestRequiresPersistentKey: true as AnyObject]
                }
                // Request the Server Playback Context.
                guard
                    let contentIdData = contentId.data(using: String.Encoding.utf8),
                    let spcData = try? loadingRequest.streamingContentKeyRequestData(forApp: certificateData, contentIdentifier: contentIdData, options: options),
                    let dataRequest = loadingRequest.dataRequest else {
                        loadingRequest.finishLoading(with: NSError(domain: "com.indeeTv.error", code: -3, userInfo: nil))
                        return
                }
                
                guard let ckcUrlString = self.media.fpSpcUrl, let ckcURL = URL(string: ckcUrlString) else {
                    print("CKC URL not available locally!!")
                    loadingRequest.finishLoading(with: NSError(domain: "com.indeeTv.error", code: -4, userInfo: nil))
                    return
                }
                
                // Request the Content Key Context from the Key Server Module.
                
                var request = URLRequest(url: ckcURL)
                request.httpMethod = "POST"
                request.httpBody = spcData
                let session = URLSession(configuration: URLSessionConfiguration.default)
                let task = session.dataTask(with: request) { data, response, error in
                    if let data = data {
                        // The CKC is correctly returned and is now send to the `AVPlayer` instance so we
                        // can continue to play the stream.
                        dataRequest.respond(with: data)
                        loadingRequest.finishLoading()
                    } else {
                        loadingRequest.finishLoading(with: NSError(domain: "com.indeeTv.error", code: -5, userInfo: nil))
                    }
                }
                task.resume()

            } else {
                // TODO: Handle error
                print("Error while getting certificate data")
            }
        }
        
        return true
    }
    
    func fetchCertificateData(completion: @escaping (_ certificateData: Data?, _ error: Error?) -> Void) {
        
        guard let certUrlString = media.certificateUrl, let certificateURL = URL(string: certUrlString) else {
            print("No Certificate URL available locally.")
            return
        }

        // Request the Certificate from Server.
        var request = URLRequest(url: certificateURL)
        request.httpMethod = "GET"
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: request) { data, _, error in
            if nil == error, let data = data {
                completion(data, nil)
            } else {
                completion(nil, error)
            }
        }
        task.resume()
    }
}

