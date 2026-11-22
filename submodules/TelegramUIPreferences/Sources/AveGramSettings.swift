import Foundation
import SwiftSignalKit
import TelegramCore

/// Local-only AveGram settings. Nothing here is ever sent to Telegram servers.
public struct AveGramSettings: Codable, Equatable {
    public var saveDeletedMessages: Bool
    public var localPremium: Bool
    public var fakeStars: Bool
    public var fakeStarsBalance: Int64
    public var fakeGifts: Bool
    public var profileBackground: Bool
    public var profileEffects: Bool
    public var animatedAvatars: Bool
    public var profileSound: Bool
    public var modBadges: Bool

    public static var defaultSettings: AveGramSettings {
        return AveGramSettings(
            saveDeletedMessages: false,
            localPremium: false,
            fakeStars: false,
            fakeStarsBalance: 10000,
            fakeGifts: false,
            profileBackground: false,
            profileEffects: false,
            animatedAvatars: false,
            profileSound: false,
            modBadges: false
        )
    }

    public init(
        saveDeletedMessages: Bool,
        localPremium: Bool,
        fakeStars: Bool,
        fakeStarsBalance: Int64,
        fakeGifts: Bool,
        profileBackground: Bool,
        profileEffects: Bool,
        animatedAvatars: Bool,
        profileSound: Bool,
        modBadges: Bool
    ) {
        self.saveDeletedMessages = saveDeletedMessages
        self.localPremium = localPremium
        self.fakeStars = fakeStars
        self.fakeStarsBalance = fakeStarsBalance
        self.fakeGifts = fakeGifts
        self.profileBackground = profileBackground
        self.profileEffects = profileEffects
        self.animatedAvatars = animatedAvatars
        self.profileSound = profileSound
        self.modBadges = modBadges
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        let defaults = AveGramSettings.defaultSettings

        self.saveDeletedMessages = try container.decodeIfPresent(Bool.self, forKey: "saveDeletedMessages") ?? defaults.saveDeletedMessages
        self.localPremium = try container.decodeIfPresent(Bool.self, forKey: "localPremium") ?? defaults.localPremium
        self.fakeStars = try container.decodeIfPresent(Bool.self, forKey: "fakeStars") ?? defaults.fakeStars
        self.fakeStarsBalance = try container.decodeIfPresent(Int64.self, forKey: "fakeStarsBalance") ?? defaults.fakeStarsBalance
        self.fakeGifts = try container.decodeIfPresent(Bool.self, forKey: "fakeGifts") ?? defaults.fakeGifts
        self.profileBackground = try container.decodeIfPresent(Bool.self, forKey: "profileBackground") ?? defaults.profileBackground
        self.profileEffects = try container.decodeIfPresent(Bool.self, forKey: "profileEffects") ?? defaults.profileEffects
        self.animatedAvatars = try container.decodeIfPresent(Bool.self, forKey: "animatedAvatars") ?? defaults.animatedAvatars
        self.profileSound = try container.decodeIfPresent(Bool.self, forKey: "profileSound") ?? defaults.profileSound
        self.modBadges = try container.decodeIfPresent(Bool.self, forKey: "modBadges") ?? defaults.modBadges
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode(self.saveDeletedMessages, forKey: "saveDeletedMessages")
        try container.encode(self.localPremium, forKey: "localPremium")
        try container.encode(self.fakeStars, forKey: "fakeStars")
        try container.encode(self.fakeStarsBalance, forKey: "fakeStarsBalance")
        try container.encode(self.fakeGifts, forKey: "fakeGifts")
        try container.encode(self.profileBackground, forKey: "profileBackground")
        try container.encode(self.profileEffects, forKey: "profileEffects")
        try container.encode(self.animatedAvatars, forKey: "animatedAvatars")
        try container.encode(self.profileSound, forKey: "profileSound")
        try container.encode(self.modBadges, forKey: "modBadges")
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
