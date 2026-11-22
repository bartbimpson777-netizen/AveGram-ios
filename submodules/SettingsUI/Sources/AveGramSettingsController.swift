import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import AccountContext

private enum AveGramToggle: Int32 {
    case saveDeletedMessages = 0
    case localPremium
    case fakeStars
    case fakeGifts
    case profileBackground
    case profileEffects
    case animatedAvatars
    case profileSound
    case modBadges

    func value(in settings: AveGramSettings) -> Bool {
        switch self {
        case .saveDeletedMessages:
            return settings.saveDeletedMessages
        case .localPremium:
            return settings.localPremium
        case .fakeStars:
            return settings.fakeStars
        case .fakeGifts:
            return settings.fakeGifts
        case .profileBackground:
            return settings.profileBackground
        case .profileEffects:
            return settings.profileEffects
        case .animatedAvatars:
            return settings.animatedAvatars
        case .profileSound:
            return settings.profileSound
        case .modBadges:
            return settings.modBadges
        }
    }

    func apply(_ value: Bool, to settings: inout AveGramSettings) {
        switch self {
        case .saveDeletedMessages:
            settings.saveDeletedMessages = value
        case .localPremium:
            settings.localPremium = value
        case .fakeStars:
            settings.fakeStars = value
        case .fakeGifts:
            settings.fakeGifts = value
        case .profileBackground:
            settings.profileBackground = value
        case .profileEffects:
            settings.profileEffects = value
        case .animatedAvatars:
            settings.animatedAvatars = value
        case .profileSound:
            settings.profileSound = value
        case .modBadges:
            settings.modBadges = value
        }
    }

    var title: String {
        switch self {
        case .saveDeletedMessages:
            return "Сохранять удалённые сообщения"
        case .localPremium:
            return "Локальный Premium"
        case .fakeStars:
            return "Виртуальные звёзды"
        case .fakeGifts:
            return "Виртуальные подарки"
        case .profileBackground:
            return "Фон профиля"
        case .profileEffects:
            return "Эффекты профиля"
        case .animatedAvatars:
            return "Анимированные аватарки"
        case .profileSound:
            return "Звук при открытии профиля"
        case .modBadges:
            return "Бейджи AveGram"
        }
    }
}

private enum AveGramSection: Int32 {
    case messages
    case premium
    case profile
}

private final class AveGramSettingsControllerArguments {
    let updateToggle: (AveGramToggle, Bool) -> Void

    init(updateToggle: @escaping (AveGramToggle, Bool) -> Void) {
        self.updateToggle = updateToggle
    }
}

private enum AveGramSettingsEntry: ItemListNodeEntry {
    case messagesHeader
    case toggle(AveGramToggle, Bool)
    case messagesFooter

    case premiumHeader
    case premiumFooter

    case profileHeader
    case profileFooter

    var section: ItemListSectionId {
        switch self {
        case .messagesHeader, .messagesFooter:
            return AveGramSection.messages.rawValue
        case .premiumHeader, .premiumFooter:
            return AveGramSection.premium.rawValue
        case .profileHeader, .profileFooter:
            return AveGramSection.profile.rawValue
        case let .toggle(toggle, _):
            switch toggle {
            case .saveDeletedMessages:
                return AveGramSection.messages.rawValue
            case .localPremium, .fakeStars, .fakeGifts:
                return AveGramSection.premium.rawValue
            case .profileBackground, .profileEffects, .animatedAvatars, .profileSound, .modBadges:
                return AveGramSection.profile.rawValue
            }
        }
    }

    var stableId: Int32 {
        switch self {
        case .messagesHeader:
            return 0
        case .messagesFooter:
            return 99
        case .premiumHeader:
            return 100
        case .premiumFooter:
            return 199
        case .profileHeader:
            return 200
        case .profileFooter:
            return 299
        case let .toggle(toggle, _):
            switch toggle {
            case .saveDeletedMessages:
                return 1
            case .localPremium, .fakeStars, .fakeGifts:
                return 101 + toggle.rawValue
            case .profileBackground, .profileEffects, .animatedAvatars, .profileSound, .modBadges:
                return 201 + toggle.rawValue
            }
        }
    }

    static func <(lhs: AveGramSettingsEntry, rhs: AveGramSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AveGramSettingsControllerArguments
        switch self {
        case .messagesHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "СООБЩЕНИЯ", sectionId: self.section)
        case .messagesFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Удалённые собеседником сообщения останутся у вас в чате."), sectionId: self.section)
        case .premiumHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "PREMIUM, ЗВЁЗДЫ И ПОДАРКИ", sectionId: self.section)
        case .premiumFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Всё это работает только на вашем устройстве и никому другому не видно."), sectionId: self.section)
        case .profileHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ПРОФИЛЬ", sectionId: self.section)
        case .profileFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Оформление профиля видно только вам."), sectionId: self.section)
        case let .toggle(toggle, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: toggle.title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateToggle(toggle, value)
            })
        }
    }
}

private func aveGramSettingsEntries(settings: AveGramSettings) -> [AveGramSettingsEntry] {
    var entries: [AveGramSettingsEntry] = []

    entries.append(.messagesHeader)
    entries.append(.toggle(.saveDeletedMessages, settings.saveDeletedMessages))
    entries.append(.messagesFooter)

    entries.append(.premiumHeader)
    entries.append(.toggle(.localPremium, settings.localPremium))
    entries.append(.toggle(.fakeStars, settings.fakeStars))
    entries.append(.toggle(.fakeGifts, settings.fakeGifts))
    entries.append(.premiumFooter)

    entries.append(.profileHeader)
    entries.append(.toggle(.profileBackground, settings.profileBackground))
    entries.append(.toggle(.profileEffects, settings.profileEffects))
    entries.append(.toggle(.animatedAvatars, settings.animatedAvatars))
    entries.append(.toggle(.profileSound, settings.profileSound))
    entries.append(.toggle(.modBadges, settings.modBadges))
    entries.append(.profileFooter)

    return entries
}

public func aveGramSettingsController(context: AccountContext) -> ViewController {
    let arguments = AveGramSettingsControllerArguments(
        updateToggle: { toggle, value in
            let _ = updateAveGramSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                var settings = settings
                toggle.apply(value, to: &settings)
                return settings
            }).start()
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.aveGramSettings])
    )
    |> map { presentationData, sharedData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.aveGramSettings]?.get(AveGramSettings.self) ?? AveGramSettings.defaultSettings

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("AveGram"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: aveGramSettingsEntries(settings: settings), style: .blocks, animateChanges: true)

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
