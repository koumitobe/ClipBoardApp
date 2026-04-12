import AppKit

/// アプリ起動・メニューバー常駐・各コンポーネントの管理
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var historyStore: HistoryStore!
    private var clipboardMonitor: ClipboardMonitor!
    private var hotkeyDetector: HotkeyDetector!
    private var popupController: PopupWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupComponents()
        setupStatusItem()
        startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stop()
        hotkeyDetector.stop()
    }

    /// 各コンポーネントを初期化して依存関係を接続する
    @MainActor
    private func setupComponents() {
        historyStore = HistoryStore()
        clipboardMonitor = ClipboardMonitor(historyStore: historyStore)
        hotkeyDetector = HotkeyDetector()
        popupController = PopupWindowController(
            historyStore: historyStore,
            clipboardMonitor: clipboardMonitor
        )

        // Commandキー2回押しでポップアップを表示
        hotkeyDetector.onDoubleTap = { [weak self] in
            self?.popupController.show()
        }
    }

    /// メニューバーアイコンとメニューを設定する
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "doc.on.clipboard",
                accessibilityDescription: "ClipBoardApp"
            )
        }

        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(
                title: "履歴をクリア",
                action: #selector(clearHistory),
                keyEquivalent: ""
            )
        )
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(
                title: "終了",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )
        statusItem?.menu = menu
    }

    /// クリップボード監視とホットキー検知を開始する
    private func startMonitoring() {
        clipboardMonitor.start()
        hotkeyDetector.start()
    }

    /// 履歴を全件クリアする
    @objc private func clearHistory() {
        Task { @MainActor in
            historyStore.clear()
        }
    }
}
