//
//  ITBaseHeaderViewController.swift
//  IndeeTv
//
//  Created by Govind Sah on 11/06/19.
//  Copyright © 2019 Govind Sah. All rights reserved.
//

import UIKit

class ITBaseHeaderViewController: ITBaseViewController {

    @IBOutlet weak var navigationHeaderView: UIView!
    
    private var headerView: ITHeaderView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialSetup()
    }
        
    private func initialSetup() {
        addHeaderView()
    }
    
    private func addHeaderView() {
        let headerView = UINib.init(nibName: ITHeaderView.className, bundle: nil)
                                .instantiate(withOwner: self, options: nil)[0]
                                as! ITHeaderView
        self.headerView = headerView
        self.navigationHeaderView.addSubview(headerView)
    }

    func setupHeader(title: String) {
        self.headerView?.titleLB.text = title
    }
    
}
