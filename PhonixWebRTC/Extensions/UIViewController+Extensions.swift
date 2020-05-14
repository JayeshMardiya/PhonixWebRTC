//
//  UIViewController+Extensions.swift
//  VoW
//
//  Created by Jayesh Mardiya on 27/09/19.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import UIKit

extension UIViewController {

    func resetSubViews() {
        for view in self.view.subviews {
            view.layoutIfNeeded()
        }
    }

    private func gradientWithFrametoImage(frame: CGRect, colors: [CGColor]) -> UIImage? {

        let gradient: CAGradientLayer  = CAGradientLayer(layer: self.view.layer)
        gradient.frame = frame
        gradient.colors = colors
        UIGraphicsBeginImageContext(frame.size)
        gradient.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// Set Gradient
    func setGradient(for view: UIView, with cornerRadius: CGFloat) {

        let image = self.gradientWithFrametoImage(frame: view.frame,
                                                  colors: [UIColor(red: 48.0/255.0,
                                                                   green: 117.0/255.0,
                                                                   blue: 155.0/255.0,
                                                                   alpha: 0.5).cgColor,
                                                           UIColor(red: 9.0/255.0,
                                                                   green: 25.0/255.0,
                                                                   blue: 38.0/255.0,
                                                                   alpha: 0.5).cgColor])!
        view.layer.cornerRadius = cornerRadius
        view.backgroundColor = UIColor(patternImage: image)
    }

    func formatTime(sec: UInt) -> String {

        let null: Int = 0
        let hour: UInt = sec / 3600
        let minutes: UInt = (sec / 60) % 60
        let seconds: UInt = sec % 60

        var formattedTime: String = ""

        formattedTime = String(format: "%lu:%02lu:%02lu", hour, minutes, seconds)
        if hour < 10 {
            formattedTime = String(format: "%i%lu:%02lu:%02lu", null, hour, minutes, seconds)
        }

        return formattedTime
    }
}
