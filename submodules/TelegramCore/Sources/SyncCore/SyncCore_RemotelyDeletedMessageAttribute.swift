import Foundation
import Postbox
import SwiftSignalKit

/// Set on an incoming message that the sender deleted on the server, when the AveGram
/// "save deleted messages" option kept it in the local history.
public class RemotelyDeletedMessageAttribute: MessageAttribute {
    /// Unix time at which the deletion was received.
    public let date: Int32

    public init(date: Int32) {
        self.date = date
    }

    required public init(decoder: PostboxDecoder) {
        self.date = decoder.decodeInt32ForKey("d", orElse: 0)
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.date, forKey: "d")
    }
}

public extension Message {
    var isRemotelyDeleted: Bool {
        for attribute in self.attributes {
            if attribute is RemotelyDeletedMessageAttribute {
                return true
            }
        }
        return false
    }
}

public extension EngineMessage {
    var isRemotelyDeleted: Bool {
        for attribute in self.attributes {
            if attribute is RemotelyDeletedMessageAttribute {
                return true
            }
        }
        return false
    }
}

/// Process-wide switches for the AveGram mod. They are plain atomics so TelegramCore does not
/// depend on the UI preferences module; the app keeps them in sync with the stored settings.
public enum AveGramRuntime {
    private static let saveDeletedMessagesValue = Atomic<Bool>(value: false)

    private static let modBadgesValue = Atomic<Bool>(value: false)

    public static var saveDeletedMessages: Bool {
        get {
            return saveDeletedMessagesValue.with { $0 }
        }
        set {
            let _ = saveDeletedMessagesValue.modify { _ in newValue }
        }
    }

    public static var modBadges: Bool {
        get {
            return modBadgesValue.with { $0 }
        }
        set {
            let _ = modBadgesValue.modify { _ in newValue }
        }
    }
}
