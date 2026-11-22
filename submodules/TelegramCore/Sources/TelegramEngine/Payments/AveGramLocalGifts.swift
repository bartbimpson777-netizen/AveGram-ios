import Foundation
import SwiftSignalKit

/// AveGram: gifts "bought" locally for the own profile. They never reach the server and are only
/// merged into the own profile's gift list on this device.
public final class AveGramLocalGifts {
    public static let shared = AveGramLocalGifts()

    private static let storageKey = "avegram.localGifts.v1"

    private let gifts = Atomic<[ProfileGiftsContext.State.StarGift]>(value: [])
    private let loaded = Atomic<Bool>(value: false)
    private let updatedPipe = ValuePipe<Void>()

    public var updated: Signal<Void, NoError> {
        return self.updatedPipe.signal()
    }

    public var current: [ProfileGiftsContext.State.StarGift] {
        self.loadIfNeeded()
        return self.gifts.with { $0 }
    }

    private func loadIfNeeded() {
        let alreadyLoaded = self.loaded.swap(true)
        if alreadyLoaded {
            return
        }
        guard let data = UserDefaults.standard.data(forKey: AveGramLocalGifts.storageKey), let decoded = try? JSONDecoder().decode([ProfileGiftsContext.State.StarGift].self, from: data) else {
            return
        }
        let _ = self.gifts.modify { _ in decoded }
    }

    private func persist(_ gifts: [ProfileGiftsContext.State.StarGift]) {
        if let data = try? JSONEncoder().encode(gifts) {
            UserDefaults.standard.set(data, forKey: AveGramLocalGifts.storageKey)
        }
    }

    /// Adds a gift as if it had just been received, newest first.
    public func add(gift: StarGift, convertStars: Int64?) {
        self.loadIfNeeded()
        let date = Int32(Date().timeIntervalSince1970)
        let entry = ProfileGiftsContext.State.StarGift(
            gift: gift,
            reference: nil,
            fromPeer: nil,
            date: date,
            text: nil,
            entities: nil,
            nameHidden: false,
            savedToProfile: true,
            pinnedToTop: false,
            convertStars: convertStars,
            canUpgrade: false,
            canExportDate: nil,
            upgradeStars: nil,
            transferStars: nil,
            canTransferDate: nil,
            canResaleDate: nil,
            collectionIds: nil,
            prepaidUpgradeHash: nil,
            upgradeSeparate: false,
            dropOriginalDetailsStars: nil,
            number: nil,
            isRefunded: false,
            canCraftAt: nil
        )
        let updated = self.gifts.modify { current in
            return [entry] + current
        }
        self.persist(updated)
        self.updatedPipe.putNext(Void())
    }

    public func removeAll() {
        self.loadIfNeeded()
        let _ = self.gifts.modify { _ in [] }
        self.persist([])
        self.updatedPipe.putNext(Void())
    }
}
