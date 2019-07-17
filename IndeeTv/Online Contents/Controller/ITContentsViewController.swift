//
//  ITContentsViewController.swift
//  IndeeTv
//
//  Created by Govind Sah on 10/06/19.
//  Copyright © 2019 Govind Sah. All rights reserved.
//

import UIKit

class ITContentsViewController: ITBaseHeaderViewController {

    var contentsInteractor: ITContentsInteractor?
    @IBOutlet weak var tableView: UITableView!
    
    private var medias: [ITMedia]! {
        didSet {
            if nil != self.medias {
                reloadData()
            }
        }
    }
    
    class func contentsVC() -> ITContentsViewController {
        let storyboard = UIStoryboard.mainStoryboard()
        let contentsVC = storyboard.instantiateViewController(withIdentifier: ITConstants.ITViewIdentifiers.contentsVC) as! ITContentsViewController
        return contentsVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetup()
    }

    private func initialSetup() {
        
        // hiding tableView
        self.tableView.isHidden = true
        
        // registering cells
        registerCells()
        
        // any other inital setup goes here
        contentsInteractor = ITContentsInteractor(delegate: self)
        fetchContents()
    }
    
    private func registerCells() {
        self.tableView.register(UINib(nibName: ITContentTableViewCell.className, bundle: nil), forCellReuseIdentifier: ITContentTableViewCell.className)
    }

    private func fetchContents() {
        contentsInteractor?.fetchContents()
    }
    
    private func reloadData() {
        self.tableView.isHidden = false
        self.tableView.reloadData()
    }
}

extension ITContentsViewController: ITContentsInteractorOutput {
    func contents(_ contents: [ITMedia]?, error: ITError?) {
        if nil != error {
            //TODO: Show appropriate error
        } else {
            self.medias = contents
        }
    }
}

// MARK: - Table view data source

extension ITContentsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return medias.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ITContentTableViewCell.className, for: indexPath) as! ITContentTableViewCell
        cell.delegate = self
        cell.configure(media: medias[indexPath.row])
        return cell
    }
}

extension ITContentsViewController: ITContentTableViewCellDelegate {
    func didTapOnDeleteDownload(media: ITMedia) {
        // Delete Downloaded Video
        if ITMedia.DownloadState.downloaded == media.downloadedState {
            ITDownloadManager.sharedManager.deleteAsset(media: media)
        } else if ITMedia.DownloadState.downloading == media.downloadedState {
            ITDownloadManager.sharedManager.cancelDownload(for: media)
        } else {
            print("Wrong download Status")
        }
    }
    
    
    func didTapPlay(media: ITMedia) {
        ITPlayerManager.shared.playVideo(source: media)
    }
    
    func didTapDownload(media: ITMedia) {
        ITDownloadManager.sharedManager.downloadStream(for: media)
    }
    
    func didTapOnMoreOption() {
        let alertController = UIAlertController(title: nil, message: ITConstants.ITLocalizedStringConstants.notDownloadedInfo, preferredStyle: .alert)
        let okAction = UIAlertAction(title: ITConstants.ITLocalizedStringConstants.alertOk, style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
