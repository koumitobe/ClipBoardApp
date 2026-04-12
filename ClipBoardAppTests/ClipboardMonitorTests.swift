import Testing
import AppKit
@testable import ClipBoardApp

/// ClipboardMonitor のユニットテスト
/// ※ NSPasteboardはシステムサービスのため、フラグ制御とstart/stopの安全性を検証する
@MainActor
struct ClipboardMonitorTests {

    // MARK: - isSelfUpdating フラグ

    /// 初期状態で isSelfUpdating は false
    @Test func initialStateIsNotSelfUpdating() {
        let store = HistoryStore()
        let monitor = ClipboardMonitor(historyStore: store)
        #expect(monitor.isSelfUpdating == false)
    }

    /// isSelfUpdating を true に設定できる
    @Test func canSetSelfUpdatingFlag() {
        let store = HistoryStore()
        let monitor = ClipboardMonitor(historyStore: store)
        monitor.isSelfUpdating = true
        #expect(monitor.isSelfUpdating == true)
    }

    /// isSelfUpdating を false に戻せる
    @Test func canResetSelfUpdatingFlag() {
        let store = HistoryStore()
        let monitor = ClipboardMonitor(historyStore: store)
        monitor.isSelfUpdating = true
        monitor.isSelfUpdating = false
        #expect(monitor.isSelfUpdating == false)
    }

    // MARK: - start / stop

    /// start() → stop() がクラッシュしない
    @Test func startAndStopAreSafe() {
        let store = HistoryStore()
        let monitor = ClipboardMonitor(historyStore: store)
        monitor.start()
        monitor.stop()
    }

    /// stop() を複数回呼んでもクラッシュしない
    @Test func multipleStopCallsAreSafe() {
        let store = HistoryStore()
        let monitor = ClipboardMonitor(historyStore: store)
        monitor.start()
        monitor.stop()
        monitor.stop()
    }
}
