//
//  RoundedButton.swift
//  popguide
//
//  Created by Sumit Anantwar on 22/12/2018.
//  Copyright © 2019 Populi Ltd. All rights reserved.
//

import UIKit

@IBDesignable
open class RoundedButton: UIButton {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialize()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.initialize()
    }

    func initialize() {
        self.imageView?.contentMode = .scaleAspectFit
    }

    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }

    @IBInspectable
    /// Border width of view; also inspectable from Storyboard.
    public var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
}
