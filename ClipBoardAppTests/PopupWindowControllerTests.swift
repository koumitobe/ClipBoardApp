import Testing
import AppKit
@testable import ClipBoardApp

/// PopupWindowController の位置計算ロジックのユニットテスト
@MainActor
struct PopupWindowControllerTests {

    /// テスト用のコントローラを生成するヘルパー
    private func makeController() -> PopupWindowController {
        let store = HistoryStore()
        let monitor = ClipboardMonitor(historyStore: store)
        return PopupWindowController(historyStore: store, clipboardMonitor: monitor)
    }

    // MARK: - 位置計算

    /// 計算結果は常にメイン画面の表示可能領域内に収まる
    @Test func positionIsWithinVisibleFrame() {
        let controller = makeController()
        let size = NSSize(width: Constants.popupWidth, height: Constants.popupHeight)
        let origin = controller.calculatePosition(for: size)

        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame

        #expect(origin.x >= visible.minX)
        #expect(origin.y >= visible.minY)
        #expect(origin.x + size.width <= visible.maxX + 1)   // 浮動小数点誤差を許容
        #expect(origin.y + size.height <= visible.maxY + 1)
    }

    /// ポップアップサイズが0でも計算がクラッシュしない
    @Test func positionWithZeroSizeDoesNotCrash() {
        let controller = makeController()
        let size = NSSize(width: 0, height: 0)
        let origin = controller.calculatePosition(for: size)

        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame

        #expect(origin.x >= visible.minX)
        #expect(origin.y >= visible.minY)
    }
}
