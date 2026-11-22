import Foundation
import Postbox

/// AveGram "save deleted messages".
///
/// Called where a deletion received from the server is about to be applied. For every stored incoming
/// cloud message it marks the message with `RemotelyDeletedMessageAttribute` instead of letting it be
/// deleted, and returns only the ids that must still be deleted as usual. With the option off it returns
/// `ids` unchanged. Outgoing messages and everything outside the cloud namespace are deleted as before.
func aveGramPreserveRemotelyDeleted(transaction: Transaction, ids: [MessageId]) -> [MessageId] {
    guard AveGramRuntime.saveDeletedMessages, !ids.isEmpty else {
        return ids
    }
    let now = Int32(Date().timeIntervalSince1970)
    var remaining: [MessageId] = []
    for id in ids {
        guard id.namespace == Namespaces.Message.Cloud, let message = transaction.getMessage(id), message.flags.contains(.Incoming) else {
            remaining.append(id)
            continue
        }
        if message.attributes.contains(where: { $0 is RemotelyDeletedMessageAttribute }) {
            continue
        }
        transaction.updateMessage(id, update: { currentMessage in
            var attributes = currentMessage.attributes
            attributes.append(RemotelyDeletedMessageAttribute(date: now))
            return .update(StoreMessage(updating: currentMessage, attributes: attributes, tags: currentMessage.tags))
        })
    }
    return remaining
}

/// The global-id flavour used by private chats and basic groups. Returns the global ids that must still
/// be deleted.
func aveGramPreserveRemotelyDeleted(transaction: Transaction, globalIds: [Int32]) -> [Int32] {
    guard AveGramRuntime.saveDeletedMessages, !globalIds.isEmpty else {
        return globalIds
    }
    var remaining: [Int32] = []
    for globalId in globalIds {
        let messageIds = transaction.messageIdsForGlobalIds([globalId])
        if messageIds.isEmpty {
            remaining.append(globalId)
            continue
        }
        if !aveGramPreserveRemotelyDeleted(transaction: transaction, ids: messageIds).isEmpty {
            remaining.append(globalId)
        }
    }
    return remaining
}
