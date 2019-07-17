//
//  ITContentsInteractor.swift
//  IndeeTv
//
//  Created by Govind Sah on 10/06/19.
//  Copyright © 2019 Govind Sah. All rights reserved.
//

import Foundation

typealias ITContentResponse = ([ITMedia]?, Error?) -> Void

protocol ITContentsInteractorOutput: class {
    func contents(_ contents: [ITMedia]?, error: ITError?)
}

protocol ITContentsInteractorInput: class {
    func fetchContents()
}

class ITContentsInteractor: NSObject {
    
    // weak can never be let as the ARC can set nil to this variable whenever it needs to
    weak private var output: ITContentsInteractorOutput?

    private var contents: [ITMedia]?
    
    init(delegate: ITContentsInteractorOutput) {
        output = delegate
    }

}

extension ITContentsInteractor: ITContentsInteractorInput {
    
    func fetchContents() {
        self.fetchData { (contents, error) in
            if nil == error, let contents = contents {
                self.output?.contents(contents, error: nil)
            } else {
                self.output?.contents(contents, error: ITError.contentFetchingError)
            }
        }
    }
    
    // Reading from locally stored contents.json file
    private func fetchData(completion: ITContentResponse?) {
        
        if let path = Bundle.main.path(forResource: "contents", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                do {
                    do {
                        let response = try JSONDecoder().decode(OnlineContentsResponse.self, from: data)
                        completion?(response.assets, nil)
                    } catch {
                        throw error
                    }
                } catch {
                    completion?(nil, error)
                }
                
            } catch let error {
                print(error.localizedDescription)
                completion?(contents, error)
            }
        } else {
            print("Invalid filename/path.")
        }
        
    }

}
