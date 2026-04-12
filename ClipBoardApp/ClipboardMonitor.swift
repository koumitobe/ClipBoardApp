import Foundation
import AppKit

/// NSPasteboardをポーリングしてクリップボード変更を監視する
final class ClipboardMonitor {
    private let historyStore: HistoryStore
    private var timer: Timer?
    /// 前回確認時のchangeCount
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    /// アプリ自身がクリップボードを変更中かどうかのフラグ
    var isSelfUpdating = false

    init(historyStore: HistoryStore) {
        self.historyStore = historyStore
    }

    /// 監視を開始する
    func start() {
        timer = Timer.scheduledTimer(
            withTimeInterval: Constants.pollingInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkPasteboard()
            }
        }
    }

    /// 監視を停止する
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// クリップボードの変更を確認して履歴に追加する
    @MainActor
    private func checkPasteboard() {
        guard !isSelfUpdating else { return }

        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // テキストを優先して取得
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            historyStore.add(ClipboardItem(text: text))
            return
        }

        // 画像を取得（元データ保持・サムネイルは非同期生成）
        if let data = pasteboard.data(forType: .tiff) {
            Task.detached(priority: .utility) {
                guard let thumbnail = Self.generateThumbnail(from: data) else { return }
                await MainActor.run { [weak self] in
                    self?.historyStore.add(ClipboardItem(imageData: data, thumbnail: thumbnail))
                }
            }
        }
    }

    /// 元画像データから極小サムネイルを生成する（バックグラウンドで実行）
    private static func generateThumbnail(from data: Data) -> NSImage? {
        guard let source = NSImage(data: data) else { return nil }
        let size = source.size
        guard size.width > 0, size.height > 0 else { return nil }

        // 長辺をthumbnailMaxDimensionに合わせてリサイズ
        let maxDim = Constants.thumbnailMaxDimension
        let scale = min(maxDim / size.width, maxDim / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let thumbnail = NSImage(size: newSize)
        thumbnail.lockFocus()
        source.draw(in: NSRect(origin: .zero, size: newSize))
        thumbnail.unlockFocus()
        return thumbnail
    }
}
