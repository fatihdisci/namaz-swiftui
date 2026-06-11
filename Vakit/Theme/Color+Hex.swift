import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255
        let blue = Double(rgbValue & 0x0000FF) / 255

        self.init(UIColor(red: red, green: green, blue: blue, alpha: 1.0))
    }
}
