import Foundation
import SwiftSignalKit
import TelegramCore

/// Local-only AveGram settings. Nothing here is ever sent to Telegram servers.
public struct AveGramSettings: Codable, Equatable {
    public var saveDeletedMessages: Bool
    public var localPremium: Bool
    public var fakeStars: Bool
    /// Whole Stars.
    public var fakeStarsBalance: Int64
    public var fakeTon: Bool
    /// In nanoTON (1 TON = 1_000_000_000).
    public var fakeTonBalance: Int64
    public var fakeGifts: Bool
    public var profileBackground: Bool
    /// Index into the Telegram profile colour palette (0...20).
    public var profileColorIndex: Int32
    public var profileEffects: Bool
    public var animatedAvatars: Bool
    public var profileSound: Bool
    public var modBadges: Bool
    public var ghostMode: Bool
    public var invisibleTyping: Bool

    public static var defaultSettings: AveGramSettings {
        return AveGramSettings(
            saveDeletedMessages: false,
            localPremium: false,
            fakeStars: false,
            fakeStarsBalance: 10000,
            fakeTon: false,
            fakeTonBalance: 10_000_000_000,
            fakeGifts: false,
            profileBackground: false,
            profileColorIndex: 5,
            profileEffects: false,
            animatedAvatars: false,
            profileSound: false,
            modBadges: false,
            ghostMode: false,
            invisibleTyping: false
        )
    }

    public init(
        saveDeletedMessages: Bool,
        localPremium: Bool,
        fakeStars: Bool,
        fakeStarsBalance: Int64,
        fakeTon: Bool,
        fakeTonBalance: Int64,
        fakeGifts: Bool,
        profileBackground: Bool,
        profileColorIndex: Int32,
        profileEffects: Bool,
        animatedAvatars: Bool,
        profileSound: Bool,
        modBadges: Bool,
        ghostMode: Bool,
        invisibleTyping: Bool
    ) {
        self.saveDeletedMessages = saveDeletedMessages
        self.localPremium = localPremium
        self.fakeStars = fakeStars
        self.fakeStarsBalance = fakeStarsBalance
        self.fakeTon = fakeTon
        self.fakeTonBalance = fakeTonBalance
        self.fakeGifts = fakeGifts
        self.profileBackground = profileBackground
        self.profileColorIndex = profileColorIndex
        self.profileEffects = profileEffects
        self.animatedAvatars = animatedAvatars
        self.profileSound = profileSound
        self.modBadges = modBadges
        self.ghostMode = ghostMode
        self.invisibleTyping = invisibleTyping
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        let defaults = AveGramSettings.defaultSettings

        self.saveDeletedMessages = try container.decodeIfPresent(Bool.self, forKey: "saveDeletedMessages") ?? defaults.saveDeletedMessages
        self.localPremium = try container.decodeIfPresent(Bool.self, forKey: "localPremium") ?? defaults.localPremium
        self.fakeStars = try container.decodeIfPresent(Bool.self, forKey: "fakeStars") ?? defaults.fakeStars
        self.fakeStarsBalance = try container.decodeIfPresent(Int64.self, forKey: "fakeStarsBalance") ?? defaults.fakeStarsBalance
        self.fakeTon = try container.decodeIfPresent(Bool.self, forKey: "fakeTon") ?? defaults.fakeTon
        self.fakeTonBalance = try container.decodeIfPresent(Int64.self, forKey: "fakeTonBalance") ?? defaults.fakeTonBalance
        self.fakeGifts = try container.decodeIfPresent(Bool.self, forKey: "fakeGifts") ?? defaults.fakeGifts
        self.profileBackground = try container.decodeIfPresent(Bool.self, forKey: "profileBackground") ?? defaults.profileBackground
        self.profileColorIndex = try container.decodeIfPresent(Int32.self, forKey: "profileColorIndex") ?? defaults.profileColorIndex
        self.profileEffects = try container.decodeIfPresent(Bool.self, forKey: "profileEffects") ?? defaults.profileEffects
        self.animatedAvatars = try container.decodeIfPresent(Bool.self, forKey: "animatedAvatars") ?? defaults.animatedAvatars
        self.profileSound = try container.decodeIfPresent(Bool.self, forKey: "profileSound") ?? defaults.profileSound
        self.modBadges = try container.decodeIfPresent(Bool.self, forKey: "modBadges") ?? defaults.modBadges
        self.ghostMode = try container.decodeIfPresent(Bool.self, forKey: "ghostMode") ?? defaults.ghostMode
        self.invisibleTyping = try container.decodeIfPresent(Bool.self, forKey: "invisibleTyping") ?? defaults.invisibleTyping
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode(self.saveDeletedMessages, forKey: "saveDeletedMessages")
        try container.encode(self.localPremium, forKey: "localPremium")
        try container.encode(self.fakeStars, forKey: "fakeStars")
        try container.encode(self.fakeStarsBalance, forKey: "fakeStarsBalance")
        try container.encode(self.fakeTon, forKey: "fakeTon")
        try container.encode(self.fakeTonBalance, forKey: "fakeTonBalance")
        try container.encode(self.fakeGifts, forKey: "fakeGifts")
        try container.encode(self.profileBackground, forKey: "profileBackground")
        try container.encode(self.profileColorIndex, forKey: "profileColorIndex")
        try container.encode(self.profileEffects, forKey: "profileEffects")
        try container.encode(self.animatedAvatars, forKey: "animatedAvatars")
        try container.encode(self.profileSound, forKey: "profileSound")
        try container.encode(self.modBadges, forKey: "modBadges")
        try container.encode(self.ghostMode, forKey: "ghostMode")
        try container.encode(self.invisibleTyping, forKey: "invisibleTyping")
    }
}

public func updateAveGramSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (AveGramSettings) -> AveGramSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.aveGramSettings, { entry in
            let currentSettings: AveGramSettings
            if let entry = entry?.get(AveGramSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = .defaultSettings
            }
            return SharedPreferencesEntry(f(currentSettings))
        })
    }
}
