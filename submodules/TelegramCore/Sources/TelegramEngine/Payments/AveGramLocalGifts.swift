import Foundation
import SwiftSignalKit

/// AveGram: gifts "bought" locally for the own profile. They never reach the server and are only
/// merged into the own profile's gift list on this device.
public final class AveGramLocalGifts {
    public static let shared = AveGramLocalGifts()

    private static let storageKey = "avegram.localGifts.v1"

    private typealias Entry = ProfileGiftsContext.State.StarGift

    private let gifts = Atomic<[Entry]>(value: [])
    private let loaded = Atomic<Bool>(value: false)
    private let updatedPipe = ValuePipe<Void>()

    public var updated: Signal<Void, NoError> {
        return self.updatedPipe.signal()
    }

    public var current: [ProfileGiftsContext.State.StarGift] {
        self.loadIfNeeded()
        return self.gifts.with { $0 }
    }

    public var genericCount: Int {
        return self.current.filter { entry in
            if case .generic = entry.gift {
                return true
            }
            return false
        }.count
    }

    public var uniqueCount: Int {
        return self.current.filter { entry in
            if case .unique = entry.gift {
                return true
            }
            return false
        }.count
    }

    private func loadIfNeeded() {
        let alreadyLoaded = self.loaded.swap(true)
        if alreadyLoaded {
            return
        }
        guard let data = UserDefaults.standard.data(forKey: AveGramLocalGifts.storageKey), let decoded = try? JSONDecoder().decode([Entry].self, from: data) else {
            return
        }
        let _ = self.gifts.modify { _ in decoded }
    }

    private func apply(_ f: @escaping ([Entry]) -> [Entry]) {
        self.loadIfNeeded()
        let updated = self.gifts.modify { current in
            return f(current)
        }
        if let data = try? JSONEncoder().encode(updated) {
            UserDefaults.standard.set(data, forKey: AveGramLocalGifts.storageKey)
        }
        self.updatedPipe.putNext(Void())
    }

    private static func makeEntry(gift: StarGift, convertStars: Int64?) -> Entry {
        return ProfileGiftsContext.State.StarGift(
            gift: gift,
            reference: nil,
            fromPeer: nil,
            date: Int32(Date().timeIntervalSince1970),
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
    }

    private static func makeUniqueGift(base: StarGift.UniqueGift?, giftId: Int64, title: String, attributes: [StarGift.UniqueGift.Attribute], ownerPeerId: EnginePeer.Id) -> StarGift.UniqueGift {
        let number = Int32.random(in: 1 ... 9000)
        return StarGift.UniqueGift(
            id: Int64.random(in: 1 ... Int64.max / 2),
            giftId: giftId,
            title: title,
            number: number,
            slug: "avegram-\(giftId)-\(number)",
            owner: .peerId(ownerPeerId),
            attributes: attributes,
            availability: StarGift.UniqueGift.Availability(issued: number, total: max(number, 10000)),
            giftAddress: nil,
            resellAmounts: nil,
            resellForTonOnly: false,
            releasedBy: nil,
            valueAmount: nil,
            valueCurrency: nil,
            valueUsdAmount: nil,
            flags: [],
            themePeerId: nil,
            peerColor: nil,
            hostPeerId: nil,
            minOfferStars: nil,
            craftChancePermille: nil
        )
    }

    /// Adds a gift as if it had just been received, newest first.
    public func add(gift: StarGift, convertStars: Int64?) {
        let entry = AveGramLocalGifts.makeEntry(gift: gift, convertStars: convertStars)
        self.apply { current in
            return [entry] + current
        }
    }

    public func removeAll() {
        self.apply { _ in [] }
    }

    /// Turns the newest ordinary local gift into a unique one, using sample attributes that Telegram
    /// offers for the upgrade preview of that gift. Completes with `false` when there is nothing to
    /// upgrade or the preview is not available.
    public func upgradeNewestGeneric(engine: TelegramEngine, ownerPeerId: EnginePeer.Id) -> Signal<Bool, NoError> {
        let list = self.current
        var baseGift: StarGift.Gift?
        for entry in list {
            if case let .generic(gift) = entry.gift {
                baseGift = gift
                break
            }
        }
        guard let baseGift else {
            return .single(false)
        }
        return engine.payments.starGiftUpgradePreview(giftId: baseGift.id)
        |> take(1)
        |> map { [weak self] preview -> Bool in
            guard let self, let preview else {
                return false
            }
            var models: [StarGift.UniqueGift.Attribute] = []
            var patterns: [StarGift.UniqueGift.Attribute] = []
            var backdrops: [StarGift.UniqueGift.Attribute] = []
            for attribute in preview.attributes {
                switch attribute {
                case .model:
                    models.append(attribute)
                case .pattern:
                    patterns.append(attribute)
                case .backdrop:
                    backdrops.append(attribute)
                default:
                    break
                }
            }
            guard let model = models.randomElement(), let pattern = patterns.randomElement(), let backdrop = backdrops.randomElement() else {
                return false
            }
            let unique = AveGramLocalGifts.makeUniqueGift(base: nil, giftId: baseGift.id, title: baseGift.title ?? "Gift", attributes: [model, pattern, backdrop], ownerPeerId: ownerPeerId)
            let baseId = baseGift.id
            self.apply { current in
                var current = current
                if let index = current.firstIndex(where: { entry in
                    if case let .generic(gift) = entry.gift {
                        return gift.id == baseId
                    }
                    return false
                }) {
                    current[index] = AveGramLocalGifts.makeEntry(gift: .unique(unique), convertStars: nil)
                }
                return current
            }
            return true
        }
    }

    /// Combines the `count` newest unique local gifts into one new unique gift whose model, pattern and
    /// backdrop are picked from the inputs. The result is marked as crafted. Returns `false` when there
    /// are not enough unique gifts.
    public func craft(count: Int, ownerPeerId: EnginePeer.Id) -> Bool {
        let list = self.current
        var inputIndices: [Int] = []
        var inputs: [StarGift.UniqueGift] = []
        for (index, entry) in list.enumerated() {
            if case let .unique(gift) = entry.gift {
                inputIndices.append(index)
                inputs.append(gift)
                if inputs.count == count {
                    break
                }
            }
        }
        guard count >= 2, inputs.count == count else {
            return false
        }

        func pick(_ matches: (StarGift.UniqueGift.Attribute) -> Bool) -> StarGift.UniqueGift.Attribute? {
            var candidates: [StarGift.UniqueGift.Attribute] = []
            for input in inputs {
                for attribute in input.attributes where matches(attribute) {
                    candidates.append(attribute)
                }
            }
            return candidates.randomElement()
        }

        guard
            let model = pick({ if case .model = $0 { return true } else { return false } }),
            let pattern = pick({ if case .pattern = $0 { return true } else { return false } }),
            let backdrop = pick({ if case .backdrop = $0 { return true } else { return false } })
        else {
            return false
        }

        var craftedModel = model
        if case let .model(name, file, rarity, _) = model {
            craftedModel = .model(name: name, file: file, rarity: rarity, crafted: true)
        }

        guard let source = inputs.randomElement() else {
            return false
        }
        let unique = AveGramLocalGifts.makeUniqueGift(base: source, giftId: source.giftId, title: source.title, attributes: [craftedModel, pattern, backdrop], ownerPeerId: ownerPeerId)
        let removed = Set(inputIndices)
        self.apply { current in
            var result: [Entry] = [AveGramLocalGifts.makeEntry(gift: .unique(unique), convertStars: nil)]
            for (index, entry) in current.enumerated() where !removed.contains(index) {
                result.append(entry)
            }
            return result
        }
        return true
    }
}
