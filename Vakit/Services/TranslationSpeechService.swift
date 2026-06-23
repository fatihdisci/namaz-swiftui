import AVFoundation
import Foundation
import Observation

extension Notification.Name {
    /// Bir ses kaynağı (ayet tilaveti veya meal TTS) başladığında yayınlanır.
    /// Diğer kaynaklar bunu dinleyip durur — aynı anda iki ses çalmaz.
    static let vakitAudioPlaybackStarted = Notification.Name("vakitAudioPlaybackStarted")
}

/// Dua ve hadis **meallerini** kullanıcının seçili diline göre (TR/EN) cihazın yerleşik
/// `AVSpeechSynthesizer`'ı ile sesli okur. Bu Kur'an tilaveti DEĞİL, düz çeviri metnin
/// seslendirilmesidir; o yüzden native TTS uygundur (ayet Arapçası için kullanılmaz).
///
/// - Aynı anda tek öğe konuşur; yeni öğe öncekini durdurur.
/// - Ayet tilaveti ([[AyahAudioPlayer]]) ile karşılıklı dışlama: biri başlayınca diğeri susar.
@MainActor
@Observable
final class TranslationSpeechService {
    static let shared = TranslationSpeechService()

    /// Şu an seslendirilen öğenin id'si; yoksa nil.
    private(set) var speakingID: String?

    private let synthesizer = AVSpeechSynthesizer()
    private let coordinator = SpeechCoordinator()

    private init() {
        synthesizer.delegate = coordinator
        coordinator.onFinish = { [weak self] in self?.speakingID = nil }
        NotificationCenter.default.addObserver(
            forName: .vakitAudioPlaybackStarted, object: nil, queue: .main
        ) { [weak self] note in
            guard let self, (note.object as AnyObject?) !== self else { return }
            MainActor.assumeIsolated { self.stop() }
        }
    }

    func isSpeaking(_ id: String) -> Bool { speakingID == id }

    func toggle(id: String, text: String, language: String) {
        if speakingID == id {
            stop()
        } else {
            speak(id: id, text: text, language: language)
        }
    }

    func speak(id: String, text: String, language: String) {
        stop()
        // Diğer ses kaynaklarını (ayet tilaveti) durdur.
        NotificationCenter.default.post(name: .vakitAudioPlaybackStarted, object: self)
        configureSession()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language == "tr" ? "tr-TR" : "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.96
        speakingID = id
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let wasSpeaking = speakingID != nil
        speakingID = nil
        if wasSpeaking {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Oturum kurulamazsa yine de okumayı dene.
        }
    }
}

/// `AVSpeechSynthesizerDelegate` NSObject gerektirir; @Observable servisi temiz tutmak için ayrı.
private final class SpeechCoordinator: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: (() -> Void)?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in onFinish?() }
    }
}
