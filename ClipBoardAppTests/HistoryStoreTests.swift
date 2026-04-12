import Testing
import Foundation
@testable import ClipBoardApp

/// HistoryStore のユニットテスト
/// 対象: 追加・重複排除・最大30件上限・先頭移動・クリア
@MainActor
struct HistoryStoreTests {

    // MARK: - add

    /// テキストアイテムを追加できる
    @Test func addTextItem() {
        let store = HistoryStore()
        store.add(ClipboardItem(text: "hello"))
        #expect(store.items.count == 1)
        #expect(store.items.first?.text == "hello")
    }

    /// 新しいアイテムが先頭に追加される
    @Test func addInsertsAtTop() {
        let store = HistoryStore()
        store.add(ClipboardItem(text: "first"))
        store.add(ClipboardItem(text: "second"))
        #expect(store.items.first?.text == "second")
        #expect(store.items.last?.text == "first")
    }

    /// 先頭と同一テキストは重複追加されない
    @Test func duplicateTextIsIgnored() {
        let store = HistoryStore()
        store.add(ClipboardItem(text: "dup"))
        store.add(ClipboardItem(text: "dup"))
        #expect(store.items.count == 1)
    }

    /// 先頭と異なるテキストは重複扱いにならない
    @Test func nonDuplicateTextIsAdded() {
        let store = HistoryStore()
        store.add(ClipboardItem(text: "a"))
        store.add(ClipboardItem(text: "b"))
        store.add(ClipboardItem(text: "a"))  // 先頭は "b" なので重複でない
        #expect(store.items.count == 3)
    }

    // MARK: - 最大件数

    /// 最大件数（30件）を超えたら最古のアイテムが削除される
    @Test func maxHistoryCountEnforced() {
        let store = HistoryStore()
        for i in 0..<35 {
            store.add(ClipboardItem(text: "item\(i)"))
        }
        #expect(store.items.count == Constants.maxHistoryCount)
    }

    /// 最大件数ちょうどでは削除されない
    @Test func exactMaxCountIsKept() {
        let store = HistoryStore()
        for i in 0..<30 {
            store.add(ClipboardItem(text: "item\(i)"))
        }
        #expect(store.items.count == 30)
    }

    /// 超過時は最古（末尾）が削除され、最新（先頭）は保持される
    @Test func oldestItemRemovedWhenOverMax() {
        let store = HistoryStore()
        store.add(ClipboardItem(text: "oldest"))
        for i in 1..<30 {
            store.add(ClipboardItem(text: "item\(i)"))
        }
        store.add(ClipboardItem(text: "newest"))
        #expect(store.items.first?.text == "newest")
        #expect(store.items.contains(where: { $0.text == "oldest" }) == false)
    }

    // MARK: - moveToTop

    /// 指定IDのアイテムを先頭に移動できる
    @Test func moveToTopWorks() {
        let store = HistoryStore()
        store.add(ClipboardItem(text: "a"))
        store.add(ClipboardItem(text: "b"))
        store.add(ClipboardItem(text: "c"))
        // 現在の順: c, b, a
        let targetId = store.items.last!.id  // "a"
        store.moveToTop(id: targetId)
        #expect(store.items.first?.text == "a")
        #expect(store.items.count == 3)
    }

    /// 存在しないIDを指定しても何も起きない
    @Test func moveToTopWithInvalidIdDoesNothing() {
        let store = HistoryStore()
        store.add(ClipboardItem(text: "a"))
        let beforeCount = store.items.count
        store.moveToTop(id: UUID())
        #expect(store.items.count == beforeCount)
    }

    // MARK: - clear

    /// clear() で全件削除される
    @Test func clearRemovesAllItems() {
        let store = HistoryStore()
        store.add(ClipboardItem(text: "a"))
        store.add(ClipboardItem(text: "b"))
        store.clear()
        #expect(store.items.isEmpty)
    }
}
