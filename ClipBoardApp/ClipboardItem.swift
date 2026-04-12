import Foundation
import AppKit

/// クリップボードアイテムの種別
enum ClipboardItemType {
    case text
    case image
}

/// クリップボード履歴の1件分のデータ
struct ClipboardItem: Identifiable {
    let id: UUID
    let type: ClipboardItemType
    /// テキスト内容（type == .text のとき）
    let text: String?
    /// 元画像データ（type == .image のとき、ペースト時に使用）
    let imageData: Data?
    /// 表示用極小サムネイル（type == .image のとき、UI表示専用）
    let thumbnail: NSImage?
    /// コピーされた日時
    let copiedAt: Date

    /// テキストアイテムを生成する
    init(text: String) {
        self.id = UUID()
        self.type = .text
        self.text = text
        self.imageData = nil
        self.thumbnail = nil
        self.copiedAt = Date()
    }

    /// 画像アイテムを生成する
    init(imageData: Data, thumbnail: NSImage) {
        self.id = UUID()
        self.type = .image
        self.text = nil
        self.imageData = imageData
        self.thumbnail = thumbnail
        self.copiedAt = Date()
    }
}
