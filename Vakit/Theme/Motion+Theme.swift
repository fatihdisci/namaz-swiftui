import SwiftUI

extension Animation {
    /// Aurora renk geçişi, büyük layout değişiklikleri — 1.5s
    static let vakitSlow = Animation.easeInOut(duration: 1.5)
    /// Onboarding step geçişi, sheet present — 0.35s
    static let vakitMedium = Animation.easeInOut(duration: 0.35)
    /// Mikro etkileşim: buton hover, selection — 0.2s
    static let vakitFast = Animation.easeInOut(duration: 0.2)
}

/// reduceMotion açıksa animasyonu iptal eder (nil), kapalıysa verilen animasyonu döndürür.
func vakitAnimation(_ animation: Animation, reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : animation
}
