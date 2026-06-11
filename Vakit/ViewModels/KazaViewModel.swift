import Foundation
import Observation

@MainActor
@Observable
final class KazaViewModel {
    static let prayers: [Prayer] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

    private(set) var counts: KazaCounts

    @ObservationIgnored private let storage: StorageService

    init(storage: StorageService = .shared) {
        self.storage = storage
        self.counts = storage.kazaCounts
    }

    var totalCount: Int {
        counts.total
    }

    func count(for prayer: Prayer) -> Int {
        counts[prayer]
    }

    func increment(_ prayer: Prayer) {
        counts[prayer] += 1
        save()
    }

    func decrement(_ prayer: Prayer) {
        counts[prayer] -= 1
        save()
    }

    private func save() {
        storage.kazaCounts = counts
    }
}
