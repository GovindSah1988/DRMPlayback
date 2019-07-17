//
//  ITProgressView.swift
//  IndeeTv
//
//  Created by Govind Sah on 13/06/19.
//  Copyright © 2019 Govind Sah. All rights reserved.
//

import UIKit

class ITProgressView: UIView {

    var circle: UIView!
    var progressCircleLayer: CAShapeLayer!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.size.height/2.0
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 0.7
        self.backgroundColor = .clear
    }
    
    func setProgress(progress: Double) {
        
        if nil == circle {
            circle = UIView(frame: CGRect(x: 0,y: 0, width: 27, height: 27))
        }
        
        circle.layoutIfNeeded()
        
        if let progressCircleLayer = progressCircleLayer, let sublayers = circle.layer.sublayers, sublayers.contains(progressCircleLayer) {
            circle.layer.sublayers?.removeLast()
            self.progressCircleLayer = nil
        }

        let centerPoint = CGPoint (x: circle.bounds.width / 2, y: circle.bounds.width / 2)
        let circleRadius : CGFloat = circle.bounds.width / 4
        
        let circlePath = UIBezierPath(arcCenter: centerPoint, radius: circleRadius, startAngle: CGFloat(-0.5 * Double.pi), endAngle: CGFloat(1.5 * Double.pi), clockwise: true)
        
        if nil == progressCircleLayer {
            progressCircleLayer = CAShapeLayer()
        }
        progressCircleLayer.path = circlePath.cgPath
        progressCircleLayer.strokeColor = UIColor.white.cgColor
        progressCircleLayer.fillColor = UIColor.clear.cgColor
        progressCircleLayer.lineWidth = circle.bounds.width/2
        progressCircleLayer.strokeStart = 0
        progressCircleLayer.strokeEnd = CGFloat(progress)
        
        if let progressCircleLayer = progressCircleLayer, let sublayers = circle.layer.sublayers, sublayers.contains(progressCircleLayer) {
            circle.layer.sublayers?.removeLast()
        }

        circle.layer.addSublayer(progressCircleLayer)
        
        self.addSubview(circle)

    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
