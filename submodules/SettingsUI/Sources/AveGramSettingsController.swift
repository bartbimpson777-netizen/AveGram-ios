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
import PromptUI
import AlertUI

private enum AveGramToggle: Int32 {
    case saveDeletedMessages = 0
    case localPremium
    case fakeStars
    case fakeTon
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
        case .fakeTon:
            return settings.fakeTon
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
        case .fakeTon:
            settings.fakeTon = value
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
        case .fakeTon:
            return "Виртуальные граммы (TON)"
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

private enum AveGramAmount {
    case stars
    case ton
    case profileColor
}

private enum AveGramAction {
    case upgrade
    case craft
    case clearGifts
}

private enum AveGramSection: Int32 {
    case messages
    case premium
    case profile
}

private final class AveGramSettingsControllerArguments {
    let updateToggle: (AveGramToggle, Bool) -> Void
    let editAmount: (AveGramAmount) -> Void
    let runAction: (AveGramAction) -> Void

    init(updateToggle: @escaping (AveGramToggle, Bool) -> Void, editAmount: @escaping (AveGramAmount) -> Void, runAction: @escaping (AveGramAction) -> Void) {
        self.updateToggle = updateToggle
        self.editAmount = editAmount
        self.runAction = runAction
    }
}

private enum AveGramSettingsEntry: ItemListNodeEntry {
    case messagesHeader
    case toggle(AveGramToggle, Bool)
    case amount(AveGramAmount, String)
    case action(AveGramAction)
    case messagesFooter

    case premiumHeader
    case premiumFooter

    case profileHeader
    case profileFooter

    var section: ItemListSectionId {
        switch self {
        case .messagesHeader, .messagesFooter:
            return AveGramSection.messages.rawValue
        case .action:
            return AveGramSection.premium.rawValue
        case let .amount(amount, _):
            if case .profileColor = amount {
                return AveGramSection.profile.rawValue
            }
            return AveGramSection.premium.rawValue
        case .premiumHeader, .premiumFooter:
            return AveGramSection.premium.rawValue
        case .profileHeader, .profileFooter:
            return AveGramSection.profile.rawValue
        case let .toggle(toggle, _):
            switch toggle {
            case .saveDeletedMessages:
                return AveGramSection.messages.rawValue
            case .localPremium, .fakeStars, .fakeTon, .fakeGifts:
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
        case let .amount(amount, _):
            switch amount {
            case .stars:
                return 160
            case .ton:
                return 161
            case .profileColor:
                return 261
            }
        case let .action(action):
            switch action {
            case .upgrade:
                return 170
            case .craft:
                return 171
            case .clearGifts:
                return 172
            }
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
            case .localPremium, .fakeStars, .fakeTon, .fakeGifts:
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
            return ItemListTextItem(presentationData: presentationData, text: .plain("Всё это работает только на вашем устройстве и никому другому не видно. Нажмите на сумму, чтобы изменить её."), sectionId: self.section)
        case .profileHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ПРОФИЛЬ", sectionId: self.section)
        case .profileFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Оформление профиля видно только вам."), sectionId: self.section)
        case let .toggle(toggle, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: toggle.title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateToggle(toggle, value)
            })
        case let .action(action):
            let title: String
            switch action {
            case .upgrade:
                title = "Улучшить подарок до уникального"
            case .craft:
                title = "Крафт: объединить 3 уникальных подарка"
            case .clearGifts:
                title = "Удалить все локальные подарки"
            }
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: title, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.runAction(action)
            })
        case let .amount(amount, label):
            let title: String
            switch amount {
            case .stars:
                title = "Сумма звёзд"
            case .ton:
                title = "Сумма TON"
            case .profileColor:
                title = "Цвет фона профиля (0–20)"
            }
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: nil, title: title, label: label, labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.editAmount(amount)
            })
        }
    }
}

private func formatTonLabel(_ nanoTon: Int64) -> String {
    return String(format: "%.2f", Double(nanoTon) / 1_000_000_000.0)
}

private func aveGramSettingsEntries(settings: AveGramSettings) -> [AveGramSettingsEntry] {
    var entries: [AveGramSettingsEntry] = []

    entries.append(.messagesHeader)
    entries.append(.toggle(.saveDeletedMessages, settings.saveDeletedMessages))
    entries.append(.messagesFooter)

    entries.append(.premiumHeader)
    entries.append(.toggle(.localPremium, settings.localPremium))
    entries.append(.toggle(.fakeStars, settings.fakeStars))
    entries.append(.toggle(.fakeTon, settings.fakeTon))
    entries.append(.toggle(.fakeGifts, settings.fakeGifts))
    entries.append(.amount(.stars, String(settings.fakeStarsBalance)))
    entries.append(.amount(.ton, formatTonLabel(settings.fakeTonBalance)))
    entries.append(.action(.clearGifts))
    entries.append(.premiumFooter)

    entries.append(.profileHeader)
    entries.append(.toggle(.profileBackground, settings.profileBackground))
    entries.append(.toggle(.profileEffects, settings.profileEffects))
    entries.append(.toggle(.animatedAvatars, settings.animatedAvatars))
    entries.append(.toggle(.profileSound, settings.profileSound))
    entries.append(.toggle(.modBadges, settings.modBadges))
    entries.append(.amount(.profileColor, String(settings.profileColorIndex)))
    entries.append(.profileFooter)

    return entries
}

public func aveGramSettingsController(context: AccountContext) -> ViewController {
    var currentSettings = AveGramSettings.defaultSettings
    var presentImpl: ((ViewController) -> Void)?

    let arguments = AveGramSettingsControllerArguments(
        updateToggle: { toggle, value in
            let _ = updateAveGramSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                var settings = settings
                toggle.apply(value, to: &settings)
                return settings
            }).start()
        },
        editAmount: { amount in
            switch amount {
            case .stars:
                presentImpl?(promptController(
                    context: context,
                    text: "Баланс звёзд",
                    value: String(currentSettings.fakeStarsBalance),
                    placeholder: "Количество звёзд",
                    characterLimit: 12,
                    apply: { value in
                        guard let value, let stars = Int64(value.trimmingCharacters(in: .whitespacesAndNewlines)), stars >= 0 else {
                            return
                        }
                        let _ = updateAveGramSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                            var settings = settings
                            settings.fakeStarsBalance = stars
                            return settings
                        }).start()
                    }
                ))
            case .profileColor:
                presentImpl?(promptController(
                    context: context,
                    text: "Цвет фона профиля",
                    value: String(currentSettings.profileColorIndex),
                    placeholder: "Число от 0 до 20",
                    characterLimit: 2,
                    apply: { value in
                        guard let value, let index = Int32(value.trimmingCharacters(in: .whitespacesAndNewlines)), index >= 0, index <= 20 else {
                            return
                        }
                        let _ = updateAveGramSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                            var settings = settings
                            settings.profileColorIndex = index
                            return settings
                        }).start()
                    }
                ))
            case .ton:
                presentImpl?(promptController(
                    context: context,
                    text: "Баланс TON",
                    value: formatTonLabel(currentSettings.fakeTonBalance),
                    placeholder: "Количество TON, например 12.5",
                    characterLimit: 20,
                    apply: { value in
                        guard let value else {
                            return
                        }
                        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
                        guard let decimal = Decimal(string: normalized), decimal >= 0, decimal <= 1_000_000_000 else {
                            return
                        }
                        let nanoTon = NSDecimalNumber(decimal: decimal * 1_000_000_000).int64Value
                        let _ = updateAveGramSettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                            var settings = settings
                            settings.fakeTonBalance = nanoTon
                            return settings
                        }).start()
                    }
                ))
            }
        },
        runAction: { action in
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let showMessage: (String) -> Void = { text in
                presentImpl?(textAlertController(context: context, title: nil, text: text, actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})], parseMarkdown: true))
            }
            switch action {
            case .upgrade:
                let _ = (AveGramLocalGifts.shared.upgradeNewestGeneric(engine: context.engine, ownerPeerId: context.account.peerId)
                |> deliverOnMainQueue).start(next: { success in
                    showMessage(success ? "Подарок улучшен до уникального." : "Нет обычных локальных подарков, либо Telegram не дал варианты улучшения для этого подарка.")
                })
            case .craft:
                if AveGramLocalGifts.shared.craft(count: 3, ownerPeerId: context.account.peerId) {
                    showMessage("Три уникальных подарка объединены в один.")
                } else {
                    showMessage("Для крафта нужно минимум 3 уникальных локальных подарка (купите или улучшите их).")
                }
            case .clearGifts:
                AveGramLocalGifts.shared.removeAll()
                showMessage("Локальные подарки удалены.")
            }
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.aveGramSettings])
    )
    |> map { presentationData, sharedData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.aveGramSettings]?.get(AveGramSettings.self) ?? AveGramSettings.defaultSettings
        currentSettings = settings

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("AveGram"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: aveGramSettingsEntries(settings: settings), style: .blocks, animateChanges: true)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    presentImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    return controller
}
