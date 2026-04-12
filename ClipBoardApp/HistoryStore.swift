import Foundation
import AppKit

/// クリップボード履歴の状態管理（最大30件・メインスレッドで操作）
@MainActor
final class HistoryStore: ObservableObject {
    /// 履歴一覧（新しい順）
    @Published private(set) var items: [ClipboardItem] = []

    /// アイテムを追加する（重複・最大件数を管理）
    func add(_ item: ClipboardItem) {
        guard !isDuplicate(item) else { return }

        // 先頭に追加（新しい順）
        items.insert(item, at: 0)

        // 最大件数超過時は末尾（最古）を削除
        if items.count > Constants.maxHistoryCount {
            items.removeLast()
        }
    }

    /// 指定IDのアイテムを先頭に移動する（選択時の順番入れ替え）
    func moveToTop(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let item = items.remove(at: index)
        items.insert(item, at: 0)
    }

    /// 履歴を全件クリアする
    func clear() {
        items.removeAll()
    }

    /// 先頭アイテムと内容が同一かを確認する（連続コピーの重複防止）
    private func isDuplicate(_ item: ClipboardItem) -> Bool {
        switch item.type {
        case .text:
            return items.first?.text == item.text
        case .image:
            guard let newData = item.imageData else { return false }
            return items.first?.imageData == newData
        }
    }
}
