//
//  ITContentTableViewCell.swift
//  IndeeTv
//
//  Created by Govind Sah on 10/06/19.
//  Copyright © 2019 Govind Sah. All rights reserved.
//

import UIKit

protocol ITContentTableViewCellDelegate: class {
    func didTapPlay(media: ITMedia)
    func didTapDownload(media: ITMedia)
    func didTapOnDeleteDownload(media: ITMedia)
    func didTapOnMoreOption()
}

class ITContentTableViewCell: UITableViewCell {

    @IBOutlet weak var placeHolderIV: UIImageView!
    @IBOutlet weak var titleLB: UILabel!
    @IBOutlet weak var descriptionLB: UILabel!
    @IBOutlet weak var downloadBT: UIButton!
    @IBOutlet weak var fileSizeLB: UILabel!
    @IBOutlet weak var downloadTopBT: UIButton!
    @IBOutlet weak var progressContainerView: UIView!
    @IBOutlet weak var moreOptionContainerView: UIView!
    @IBOutlet weak var moreActionBT: UIButton!
    
    var moreOptionView: ITMoreOptionView!
    var progressView: ITProgressView!
    
    private var media: ITMedia! {
        didSet {
            observeForDownloads()
        }
    }
    
    weak var delegate: ITContentTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.contentView.backgroundColor = .clear
        self.backgroundColor = .clear
    }
    
    private func observeForDownloads() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(handleAssetDownloadStateChanged(_:)),
                                       name: .AssetDownloadStateChanged, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleAssetDownloadProgress(_:)),
                                       name: .AssetDownloadProgress, object: nil)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if nil == moreOptionView {
            addMoreOptionView()
        }
        if nil == progressView {
            addProgressView()
        }
    }
    
    private func addMoreOptionView() {
        moreOptionView = UINib.init(nibName: ITMoreOptionView.className, bundle: nil)
            .instantiate(withOwner: self, options: nil)[0] as? ITMoreOptionView
        moreOptionView.delegate = self
        moreOptionContainerView.addSubview(moreOptionView)
    }
    
    private func addProgressView() {
        progressView = UINib(nibName: ITProgressView.className, bundle: nil).instantiate(withOwner: self, options: nil)[0] as? ITProgressView
        progressView.frame = progressContainerView.bounds
        progressContainerView.addSubview(progressView)
    }
    
    @IBAction func moreAction(_ sender: Any) {
        
        if ITMedia.DownloadState.notDownloaded != media.downloadedState {
            let isMoreOptionHidden = moreOptionContainerView.isHidden
            switch media.downloadedState {
            case .downloading:
                moreOptionContainerView.isHidden = !isMoreOptionHidden

                moreOptionView.deleteBT.isEnabled = true
                moreOptionView.deleteBT.setTitle(ITConstants.ITLocalizedStringConstants.cancel, for: UIControl.State.normal)
                
                moreOptionView.playLocallyBT.isEnabled = false
                break
            case .downloaded:
                moreOptionContainerView.isHidden = !isMoreOptionHidden
                
                moreOptionView.deleteBT.isEnabled = true
                moreOptionView.deleteBT.setTitle(ITConstants.ITLocalizedStringConstants.delete, for: UIControl.State.normal)
                
                moreOptionView.playLocallyBT.isEnabled = true
                break
            default:
                break
            }
        } else {
            print("Not Downloaded Yet!!")
            delegate?.didTapOnMoreOption()
        }
    }
    
    @IBAction func download(_ sender: Any) {
        //TODO: Network Connection Check
        if ITMedia.DownloadState.notDownloaded == media.downloadedState {
            self.delegate?.didTapDownload(media: media)
        }
    }
    
    @IBAction func play(_ sender: Any) {
        //TODO: Network Connection Check
        media.locally = false
        self.delegate?.didTapPlay(media: media)
    }
    
    func configure(media: ITMedia) {
        self.media = media
        self.titleLB.text = media.title
        self.descriptionLB.text = media.genre.appendNextWord(media.ageRestriction, delimiter: " | ")
        setDownloadButtonProgress()
    }
    
    func setDownloadButtonProgress() {
        switch media.downloadedState {
        case .downloading:
            self.progressContainerView.isHidden = false
            self.downloadTopBT.isHidden = true
            self.downloadBT.setImage(nil, for: .normal)
        case .downloaded:
            if nil != progressView {
                progressView.setProgress(progress: 0)
            }
            self.progressContainerView.isHidden = true
            self.downloadTopBT.isHidden = false
            self.downloadBT.setImage(nil, for: .normal)
            break
        case .notDownloaded:
            if nil != progressView {
                progressView.setProgress(progress: 0)
            }
            self.progressContainerView.isHidden = true
            self.downloadTopBT.isHidden = true
            self.downloadBT.setImage(#imageLiteral(resourceName: "DownloadArrow"), for: .normal)
            break
        }
    }
    
    override func prepareForReuse() {
        setDownloadButtonProgress()
        moreOptionContainerView.isHidden = true
    }
}

extension ITContentTableViewCell: ITMoreOptionViewDelegate {
    func didTapDelete() {
        self.delegate?.didTapOnDeleteDownload(media: media)
        moreOptionContainerView.isHidden = true
        
        // changing the image of the download button after some delay
        // as the download cancel action takes some time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.setDownloadButtonProgress()
        }
    }
    
    func didTapPlayLocally() {
        media.locally = true
        self.delegate?.didTapPlay(media: media)
        moreOptionContainerView.isHidden = true
    }
}

extension ITContentTableViewCell {
    @objc
    func handleAssetDownloadStateChanged(_ notification: Notification) {
        guard let assetStreamName = notification.userInfo![ITMedia.Keys.name] as? String,
            let asset = media, media.id == assetStreamName else { return }
        DispatchQueue.main.async {
            if asset.id == self.media.id {
                self.setDownloadButtonProgress()
            }
        }
    }
    
    @objc
    func handleAssetDownloadProgress(_ notification: NSNotification) {
        guard let assetStreamName = notification.userInfo![ITMedia.Keys.name] as? String,
            let asset = media, media.id == assetStreamName else { return }
        guard let progress = notification.userInfo![ITMedia.Keys.percentDownloaded] as? Double else { return }
        DispatchQueue.main.async {
            if asset.id == self.media.id {
                self.setDownloadButtonProgress()
                self.progressView.setProgress(progress: progress)
            }
        }
    }

}

extension ITContentTableViewCell {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        // to dismiss the more Options view in case it is visible and the user taps any where on the screen.
        if let view = view {
            if false == moreOptionContainerView.isHidden, moreOptionView != view && !moreOptionView.subviews.contains(view) && view != self.moreActionBT {
                moreOptionContainerView.isHidden = true
            }
        }
        return view
    }
}
