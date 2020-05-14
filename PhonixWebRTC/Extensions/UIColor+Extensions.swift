//
//  UIColor+Extensions.swift
//  popguide
//
//  Created by Sumit Anantwar on 10/01/2018.
//  Copyright © 2019 Populi Ltd. All rights reserved.
//

import UIKit

// MARK: - Color Builders
public extension UIColor {

    static let enableColor = UIColor(red: 0.0/255.0, green: 60.0/255.0, blue: 80.0/255.0, alpha: 1.0)
    static let disableColor = UIColor(red: 0.0/255.0, green: 60.0/255.0, blue: 80.0/255.0, alpha: 0.5)

    /// Constructing color from hex string
    ///
    /// - Parameter hex: A hex string, can either contain # or not
    convenience init(hex string: String?) {

        /// Check for string
        guard let string = string else {
            /// Return clear color
            self.init(white: 1, alpha: 0)
            return
        }

        var hex = string.hasPrefix("#")
            ? String(string.dropFirst())
            : string
        guard hex.count == 3 || hex.count == 6
            else {
                self.init(white: 1.0, alpha: 0.0)
                return
        }
        if hex.count == 3 {
            for (index, char) in hex.enumerated() {
                hex.insert(char, at: hex.index(hex.startIndex, offsetBy: index * 2))
            }
        }

        self.init(
            red: CGFloat((Int(hex, radix: 16)! >> 16) & 0xFF) / 255.0,
            green: CGFloat((Int(hex, radix: 16)! >> 8) & 0xFF) / 255.0,
            blue: CGFloat((Int(hex, radix: 16)!) & 0xFF) / 255.0, alpha: 1.0)
    }

    /// Constructing color from RGB values
    class func rgb(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: alpha)
    }

    /// Adjust color based on saturation
    ///
    /// - Parameter minSaturation: The minimun saturation value
    /// - Returns: The adjusted color
    func color(minSaturation: CGFloat) -> UIColor {
        var (hue, saturation, brightness, alpha): (CGFloat, CGFloat, CGFloat, CGFloat) = (0.0, 0.0, 0.0, 0.0)
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        return saturation < minSaturation
            ? UIColor(hue: hue, saturation: minSaturation, brightness: brightness, alpha: alpha)
            : self
    }

    /// Convenient method to change alpha value
    ///
    /// - Parameter value: The alpha value
    /// - Returns: The alpha adjusted color
    func alpha(_ value: CGFloat) -> UIColor {
        return withAlphaComponent(value)
    }

    /// Generate random color
    class var randomColor: UIColor {
        let hue: CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
        let saturation: CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
        let brightness: CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black

        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
}

// MARK: - Helpers
public extension UIColor {

    func hex(hashPrefix: Bool = true) -> String {
        var (red, green, blue, alpha): (CGFloat, CGFloat, CGFloat, CGFloat) = (0.0, 0.0, 0.0, 0.0)
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let prefix = hashPrefix ? "#" : ""

        return String(format: "\(prefix)%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }

    internal func rgbComponents() -> [CGFloat] {
        var (red, green, blue, alpha): (CGFloat, CGFloat, CGFloat, CGFloat) = (0.0, 0.0, 0.0, 0.0)
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return [red, green, blue]
    }

    var isDark: Bool {
        let RGB = rgbComponents()
        return (0.2126 * RGB[0] + 0.7152 * RGB[1] + 0.0722 * RGB[2]) < 0.5
    }

    var isBlackOrWhite: Bool {
        let RGB = rgbComponents()
        return (RGB[0] > 0.91 && RGB[1] > 0.91 && RGB[2] > 0.91) || (RGB[0] < 0.09 && RGB[1] < 0.09 && RGB[2] < 0.09)
    }

    var isBlack: Bool {
        let RGB = rgbComponents()
        return (RGB[0] < 0.09 && RGB[1] < 0.09 && RGB[2] < 0.09)
    }

    var isWhite: Bool {
        let RGB = rgbComponents()
        return (RGB[0] > 0.91 && RGB[1] > 0.91 && RGB[2] > 0.91)
    }

    func isDistinct(from color: UIColor) -> Bool {
        let bgColor = rgbComponents()
        let fgColor = color.rgbComponents()
        let threshold: CGFloat = 0.25
        var result = false

        if abs(bgColor[0] - fgColor[0]) > threshold ||
            abs(bgColor[1] - fgColor[1]) > threshold ||
            abs(bgColor[2] - fgColor[2]) > threshold {
            if abs(bgColor[0] - bgColor[1]) < 0.03 && abs(bgColor[0] - bgColor[2]) < 0.03 {
                if abs(fgColor[0] - fgColor[1]) < 0.03 && abs(fgColor[0] - fgColor[2]) < 0.03 {
                    result = false
                }
            }
            result = true
        }

        return result
    }

    func isContrasting(with color: UIColor) -> Bool {
        let bgColor = rgbComponents()
        let fgColor = color.rgbComponents()

        let bgLum = 0.2126 * bgColor[0] + 0.7152 * bgColor[1] + 0.0722 * bgColor[2]
        let fgLum = 0.2126 * fgColor[0] + 0.7152 * fgColor[1] + 0.0722 * fgColor[2]
        let contrast = bgLum > fgLum
            ? (bgLum + 0.05) / (fgLum + 0.05)
            : (fgLum + 0.05) / (bgLum + 0.05)

        return 1.6 < contrast
    }

}

// MARK: - Gradient
public extension Array where Element: UIColor {

    func gradient(_ transform: ((_ gradient: inout CAGradientLayer) -> CAGradientLayer)? = nil) -> CAGradientLayer {
        var gradient = CAGradientLayer()
        gradient.colors = self.map { $0.cgColor }

        if let transform = transform {
            gradient = transform(&gradient)
        }

        return gradient
    }
}

// MARK: - Components
public extension UIColor {

    var redComponent: CGFloat {
        var red: CGFloat = 0
        self.getRed(&red, green: nil, blue: nil, alpha: nil)
        return red
    }

    var greenComponent: CGFloat {
        var green: CGFloat = 0
        self.getRed(nil, green: &green, blue: nil, alpha: nil)
        return green
    }

    var blueComponent: CGFloat {
        var blue: CGFloat = 0
        self.getRed(nil, green: nil, blue: &blue, alpha: nil)
        return blue
    }

    var alphaComponent: CGFloat {
        var alpha: CGFloat = 0
        self.getRed(nil, green: nil, blue: nil, alpha: &alpha)
        return alpha
    }

    var hueComponent: CGFloat {
        var hue: CGFloat = 0
        getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
        return hue
    }

    var saturationComponent: CGFloat {
        var saturation: CGFloat = 0
        getHue(nil, saturation: &saturation, brightness: nil, alpha: nil)
        return saturation
    }

    var brightnessComponent: CGFloat {
        var brightness: CGFloat = 0
        getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)
        return brightness
    }
}

// MARK: - Blending

public extension UIColor {

    /**adds hue, saturation, and brightness to the HSB components of this color (self)*/
    func add(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) -> UIColor {
        var (oldHue, oldSat, oldBright, oldAlpha) : (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        getHue(&oldHue, saturation: &oldSat, brightness: &oldBright, alpha: &oldAlpha)

        // make sure new values doesn't overflow
        var newHue = oldHue + hue
        while newHue < 0.0 { newHue += 1.0 }
        while newHue > 1.0 { newHue -= 1.0 }

        let newBright: CGFloat = max(min(oldBright + brightness, 1.0), 0)
        let newSat: CGFloat = max(min(oldSat + saturation, 1.0), 0)
        let newAlpha: CGFloat = max(min(oldAlpha + alpha, 1.0), 0)

        return UIColor(hue: newHue, saturation: newSat, brightness: newBright, alpha: newAlpha)
    }

    /**adds red, green, and blue to the RGB components of this color (self)*/
    func add(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIColor {
        var (oldRed, oldGreen, oldBlue, oldAlpha) : (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        getRed(&oldRed, green: &oldGreen, blue: &oldBlue, alpha: &oldAlpha)
        // make sure new values doesn't overflow
        let newRed: CGFloat = max(min(oldRed + red, 1.0), 0)
        let newGreen: CGFloat = max(min(oldGreen + green, 1.0), 0)
        let newBlue: CGFloat = max(min(oldBlue + blue, 1.0), 0)
        let newAlpha: CGFloat = max(min(oldAlpha + alpha, 1.0), 0)
        return UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: newAlpha)
    }

    func add(hsb color: UIColor) -> UIColor {
        var (hue, saturation, brightness, alpha) : (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return self.add(hue: hue, saturation: saturation, brightness: brightness, alpha: 0)
    }

    func add(rgb color: UIColor) -> UIColor {
        return self.add(red: color.redComponent, green: color.greenComponent, blue: color.blueComponent, alpha: 0)
    }

    func add(hsba color: UIColor) -> UIColor {
        var (hue, saturation, brightness, alpha) : (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return self.add(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }

    /**adds the rgb components of two colors*/
    func add(rgba color: UIColor) -> UIColor {
        return self.add(red: color.redComponent,
                        green: color.greenComponent,
                        blue: color.blueComponent,
                        alpha: color.alphaComponent)
    }
}
