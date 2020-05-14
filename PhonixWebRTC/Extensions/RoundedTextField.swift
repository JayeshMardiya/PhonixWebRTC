//
//  RoundedTextField.swift
//  popguide
//
//  Created by Sumit Anantwar on 22/12/2018.
//  Copyright © 2019 Populi Ltd. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedTextField: UITextField {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialize()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.initialize()
    }

    func initialize() {
        self.clipsToBounds = true
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return insetRectFor(bounds)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return insetRectFor(bounds)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return insetRectFor(bounds)
    }

    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            self.borderStyle = .none
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

    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }

    @IBInspectable var placeHolderColor: UIColor {
        get {
            return self.attributedPlaceholder?.attribute(.foregroundColor,
                                                         at: 0,
                                                         effectiveRange: nil) as? UIColor ?? .lightText
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string: self.placeholder ?? "",
                                                            attributes: [NSAttributedString.Key.font:
                                                                UIFont(name: "Roboto-Italic", size: 18.0)!,
                                                                         .foregroundColor: newValue])
        }
    }

    @IBInspectable var shadowOpacity: Float = 0 {
        didSet {
            layer.shadowOpacity = shadowOpacity
        }
    }

    @IBInspectable var shadowRadius: CGFloat = 0 {
        didSet {
            layer.shadowRadius = shadowRadius
        }
    }

    @IBInspectable var shadowOffset: CGSize = CGSize(width: 0.0, height: 0.0) {
        didSet {
            layer.shadowOffset = shadowOffset
        }
    }

    @IBInspectable var shadowColor: UIColor? = UIColor(red: 157/255, green: 157/255, blue: 157/255, alpha: 1.0) {
        didSet {
            layer.shadowColor = shadowColor?.cgColor
        }
    }
}

extension RoundedTextField {

    func insetRectFor(_ bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15))
    }
}
