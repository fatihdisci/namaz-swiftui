import AVFoundation
import Foundation
import Observation

/// Keşfet ayet kartındaki tilavet oynatma denetleyicisi.
///
/// - Aynı anda yalnızca bir ayet çalar; yeni bir ayet başlayınca öncekini durdurur.
/// - Ayet aralıkları (örn. 94:5-6) `AVQueuePlayer` ile sırayla çalınır.
/// - Yükleme/buffer durumu UI'da spinner ile gösterilir (`isLoading`).
/// - Ağ yoksa / CDN hatasında `failedVerseID` set edilir; UI localized mesaj gösterir.
/// - Ses oturumu `.playback` kategorisinde — sessiz modda da duyulur. Background audio
///   capability eklenmez: kullanıcı uygulamadan çıkınca kısa ayet sesinin durması kabul.
@MainActor
@Observable
final class AyahAudioPlayer {
    enum Status: Equatable {
        case idle
        case loading
        case playing
    }

    /// Aktif (yükleniyor veya çalıyor) ayetin id'si; hiçbiri yoksa nil.
    private(set) var activeVerseID: String?
    private(set) var status: Status = .idle
    /// Son başarısız olan ayetin id'si — UI hata mesajını bununla eşler.
    private(set) var failedVerseID: String?

    private var player: AVQueuePlayer?
    private var timeControlObservation: NSKeyValueObservation?
    private var statusObservations: [NSKeyValueObservation] = []
    private var endObserver: NSObjectProtocol?

    // MARK: - UI sorguları

    func isPlaying(_ verse: Verse) -> Bool { activeVerseID == verse.id && status == .playing }
    func isLoading(_ verse: Verse) -> Bool { activeVerseID == verse.id && status == .loading }
    func isActive(_ verse: Verse) -> Bool { activeVerseID == verse.id }
    func didFail(_ verse: Verse) -> Bool { failedVerseID == verse.id }

    // MARK: - Kontrol

    func toggle(_ verse: Verse) {
        if activeVerseID == verse.id {
            stop()
        } else {
            play(verse)
        }
    }

    func play(_ verse: Verse) {
        stop()

        let numbers = verse.audioAyahNumbers
        guard !numbers.isEmpty else {
            failedVerseID = verse.id
            return
        }

        failedVerseID = nil
        activeVerseID = verse.id
        status = .loading
        configureSession()

        let items = numbers.map { QuranAudioService.shared.makePlayerItem(globalAyahNumber: $0) }
        let queue = AVQueuePlayer(items: items)
        queue.actionAtItemEnd = .advance
        player = queue

        observe(queue: queue, items: items, verseID: verse.id)
        queue.play()
    }

    func stop() {
        let hadPlayer = player != nil
        player?.pause()
        timeControlObservation?.invalidate()
        timeControlObservation = nil
        statusObservations.forEach { $0.invalidate() }
        statusObservations = []
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
        player = nil
        activeVerseID = nil
        status = .idle
        if hadPlayer {
            // Ses oturumunu bırak ki arka plandaki müzik vb. kaldığı yerden devam etsin.
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    // MARK: - Gözlem

    private func observe(queue: AVQueuePlayer, items: [AVPlayerItem], verseID: String) {
        timeControlObservation = queue.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] player, _ in
            let control = player.timeControlStatus
            Task { @MainActor in self?.handleTimeControl(control, verseID: verseID) }
        }

        for item in items {
            let observation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
                let itemStatus = item.status
                Task { @MainActor in self?.handleItemStatus(itemStatus, verseID: verseID) }
            }
            statusObservations.append(observation)
        }

        // Son ayet bittiğinde oynatma tamamlanır.
        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: items.last,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.handleFinished(verseID: verseID) }
        }
    }

    private func handleTimeControl(_ control: AVPlayer.TimeControlStatus, verseID: String) {
        guard activeVerseID == verseID else { return }
        switch control {
        case .playing:
            status = .playing
        case .waitingToPlayAtSpecifiedRate:
            status = .loading
        case .paused:
            break // Doğal bitiş veya stop() tarafından yönetilir.
        @unknown default:
            break
        }
    }

    private func handleItemStatus(_ itemStatus: AVPlayerItem.Status, verseID: String) {
        guard activeVerseID == verseID, itemStatus == .failed else { return }
        stop()
        failedVerseID = verseID
    }

    private func handleFinished(verseID: String) {
        guard activeVerseID == verseID else { return }
        stop()
    }

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Ses oturumu kurulamazsa yine de oynatmayı dene.
        }
    }
}
