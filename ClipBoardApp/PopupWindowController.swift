import AppKit
import SwiftUI

/// ポップアップNSPanelの管理とフォーカス制御を担当する
@MainActor
final class PopupWindowController: NSObject {
    private var panel: NSPanel?
    private let historyStore: HistoryStore
    /// ポップアップ表示直前のアプリ（閉じたときにフォーカスを返す）
    private var previousApp: NSRunningApplication?
    /// 自アプリによるクリップボード変更を監視から除外するために参照
    private weak var clipboardMonitor: ClipboardMonitor?

    init(historyStore: HistoryStore, clipboardMonitor: ClipboardMonitor) {
        self.historyStore = historyStore
        self.clipboardMonitor = clipboardMonitor
    }

    /// ポップアップを表示する
    func show() {
        // 既に表示中なら閉じる
        if panel != nil {
            close()
            return
        }

        // 元アプリを保存
        previousApp = NSWorkspace.shared.frontmostApplication

        let panel = makePanel()
        // 固定サイズを使って位置を計算し、サイズと原点をまとめて設定する
        let size = NSSize(width: Constants.popupWidth, height: Constants.popupHeight)
        let origin = calculatePosition(for: size)
        panel.setFrame(NSRect(origin: origin, size: size), display: false)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    /// ポップアップを閉じて元アプリにフォーカスを返す
    func close() {
        panel?.orderOut(nil)
        panel = nil
        restoreFocus()
    }

    /// アイテムを選択してクリップボードに書き込み、閉じてから自動ペーストする
    func selectItem(_ item: ClipboardItem) {
        // 自アプリの変更として監視から除外
        clipboardMonitor?.isSelfUpdating = true
        setClipboard(item: item)
        // 選択したアイテムを履歴の先頭に移動（最新扱い）
        historyStore.moveToTop(id: item.id)

        panel?.orderOut(nil)
        panel = nil
        restoreFocus()

        // フォーカスが戻った直後にCmd+Vをシミュレート
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            Self.simulatePaste()
            // ペースト後に監視フラグをリセット
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.clipboardMonitor?.isSelfUpdating = false
            }
        }
    }

    // MARK: - Private

    /// 元アプリへフォーカスを戻す
    private func restoreFocus() {
        if #available(macOS 14.0, *) {
            previousApp?.activate()
        } else {
            previousApp?.activate(options: .activateIgnoringOtherApps)
        }
        previousApp = nil
    }

    /// クリップボードにアイテムの内容を書き込む
    private func setClipboard(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        switch item.type {
        case .text:
            if let text = item.text {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let data = item.imageData {
                pasteboard.setData(data, forType: .tiff)
            }
        }
    }

    /// NSPanelを生成してSwiftUIのPopupViewを組み込む
    private func makePanel() -> NSPanel {
        // タイトルバー分のセーフエリアを無視してコンテンツを最上部から表示する
        let popupView = PopupView(
            historyStore: historyStore,
            onClose: { [weak self] in self?.close() },
            onSelectItem: { [weak self] item in self?.selectItem(item) }
        )
        .ignoresSafeArea()
        let hosting = NSHostingController(rootView: popupView)

        let panel = NSPanel(
            contentRect: NSRect(
                x: 0, y: 0,
                width: Constants.popupWidth,
                height: Constants.popupHeight
            ),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        // 全スペース・全画面に表示可能にし、macOSによる画面移動を防ぐ
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentViewController = hosting
        // フォーカスを失ったら閉じるためにデリゲートを設定
        panel.delegate = self
        return panel
    }

    /// マウスカーソルと同じ画面内に収まる表示位置を計算する（テスト用にinternal）
    func calculatePosition(for size: NSSize) -> NSPoint {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main!
        let visible = screen.visibleFrame

        // デフォルト: マウスの右下
        var x = mouse.x + 10
        var y = mouse.y - size.height - 10

        // 右端補正 → マウスの左側に表示
        if x + size.width > visible.maxX {
            x = mouse.x - size.width - 10
        }
        // 下端補正 → マウスの上側に表示
        if y < visible.minY {
            y = mouse.y + 10
        }
        // 上端補正
        if y + size.height > visible.maxY {
            y = visible.maxY - size.height
        }

        // 最終的に同一画面内に必ず収まるようにクランプ
        x = max(visible.minX, min(x, visible.maxX - size.width))
        y = max(visible.minY, min(y, visible.maxY - size.height))

        return NSPoint(x: x, y: y)
    }

    /// Cmd+V をシミュレートして貼り付けを実行する
    private static func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)
        // V キーのバーチャルキーコード: 0x09
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags   = .maskCommand
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
}

// MARK: - NSWindowDelegate

extension PopupWindowController: NSWindowDelegate {
    /// パネルがキーウィンドウでなくなったら（外クリック時）自動で閉じる
    nonisolated func windowDidResignKey(_ notification: Notification) {
        Task { @MainActor in
            self.close()
        }
    }
}
