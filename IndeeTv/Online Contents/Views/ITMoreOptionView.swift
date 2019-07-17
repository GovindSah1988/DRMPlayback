//
//  ITMoreOptionView.swift
//  IndeeTv
//
//  Created by Govind Sah on 11/06/19.
//  Copyright © 2019 Govind Sah. All rights reserved.
//

import UIKit

protocol ITMoreOptionViewDelegate: class {
    func didTapDelete()
    func didTapPlayLocally()
}

class ITMoreOptionView: UIView {

    weak var delegate: ITMoreOptionViewDelegate?
    @IBOutlet weak var playLocallyBT: UIButton!
    @IBOutlet weak var deleteBT: UIButton!
    
    @IBAction func deleteTapped(_ sender: Any) {
        delegate?.didTapDelete()
    }
    
    @IBAction func playLocallyTapped(_ sender: Any) {
        delegate?.didTapPlayLocally()
    }
}
