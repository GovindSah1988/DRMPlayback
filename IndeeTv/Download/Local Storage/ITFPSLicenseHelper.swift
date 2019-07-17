//
//  ITFPSLicenseHelper.swift
//  IndeeTv
//
//  Created by Govind Sah on 12/06/19.
//  Copyright © 2019 Govind Sah. All rights reserved.
//

import Foundation
import AVFoundation

class FPSLicenseHelper: NSObject {
    
    let media: ITMedia
    var certificateData: Data?
    let contentKeySession: AVContentKeySession
    let queue: DispatchQueue
    
    // to tell when it has completed fetching the FPS Key
    var doneCallback: ((Error?) -> Void)?
    
    // Online play, offline play, download
    init?(media: ITMedia, certificateData: Data?, contentKeySession: AVContentKeySession, queue: DispatchQueue) {
        self.certificateData = certificateData
        self.media = media
        self.contentKeySession = contentKeySession
        self.queue = queue
    }
    
    func fetchCertificateData(completion: @escaping (_ certificateData: Data?, _ error: Error?) -> Void) {
    
        guard let certUrlString = media.certificateUrl, let certificateURL = URL(string: certUrlString) else {
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
    
    func handleLicenseRequest(done callback: @escaping (Error?) -> Void) {
        self.doneCallback = callback
        contentKeySession.setDelegate(self, queue: queue)
        contentKeySession.processContentKeyRequest(withIdentifier: ITConstants.ITPlayerConstants.persistentId, initializationData: nil, options: nil)
    }
}

extension FPSLicenseHelper: AVContentKeySessionDelegate {
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) {
        keyRequest.respondByRequestingPersistableContentKeyRequest()
    }
    
    //used for only persistent/offline related Downloding of FPS Key
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVPersistableContentKeyRequest) {
        
        // Check if the content has proper contentId to make SPC request
        guard let contentId = media.assetId else {
            return
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
                guard let contentIdData = contentId.data(using: String.Encoding.utf8) else {
                    return
                }
                
                keyRequest.makeStreamingContentKeyRequestData(forApp: certificateData, contentIdentifier: contentIdData, options: options, completionHandler: { (spcData, error) in
                    
                    guard let ckcUrlString = self.media.fpSpcUrl, let ckcURL = URL(string: ckcUrlString) else {
                        print("CKC URL not available locally!!")
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
                            
                            // Required only while downloading the license for later offline playback
                            // NOT required while playing online or offline DRM content
                            do {
                                let pkc = try keyRequest.persistableContentKey(fromKeyVendorResponse: data, options: nil)
                                UserDefaults.standard.set(pkc, forKey: self.media.offlineUrl)
                                self.doneCallback?(nil)
                            } catch {
                                print("Error")
                            }
                            
                        } else {
                            print("Unable to fetch the CKC.")
                        }
                    }
                    task.resume()
                    
                })
            }
        }
    }
}
