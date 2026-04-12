import Foundation
import CoreGraphics

/// アプリ全体で使用する定数
enum Constants {
    /// 履歴の最大保持件数
    static let maxHistoryCount = 30
    /// Commandキー2回押し判定の秒数
    static let commandDoublePressInterval: TimeInterval = 0.3
    /// クリップボード監視のポーリング間隔（秒）
    static let pollingInterval: TimeInterval = 0.5
    /// テキストプレビューの最大文字数（1行表示）
    static let textPreviewLength = 40
    /// 表示用サムネイルの最大辺サイズ（pt）
    static let thumbnailMaxDimension: CGFloat = 24
    /// ポップアップの幅
    static let popupWidth: CGFloat = 280
    /// ポップアップの高さ
    static let popupHeight: CGFloat = 260
}
