import Foundation
import AppKit
import Carbon.HIToolbox

/// CGEventTapでCommandキーの2回押しをシステム全体で検知する
final class HotkeyDetector {
    /// 2回押し検知時のコールバック
    var onDoubleTap: (() -> Void)?

    private var eventTap: CFMachPort?
    /// 前回Commandキーを押した時刻（-1 = 未押下を示すセンチネル値）
    private var lastCommandPressTime: TimeInterval = -1

    /// キー監視を開始する
    func start() {
        guard checkAccessibilityPermission() else { return }

        let mask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)

        // selfをunretainedで渡す（AppDelegateがdetectorを保持しているため安全）
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, _, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon else { return Unmanaged.passRetained(event) }
                let detector = Unmanaged<HotkeyDetector>.fromOpaque(refcon).takeUnretainedValue()
                detector.handleEvent(event)
                return Unmanaged.passRetained(event)
            },
            userInfo: selfPtr
        )

        guard let tap = eventTap else { return }
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    /// キー監視を停止する
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        eventTap = nil
    }

    /// テスト用: 指定時刻にCommandキーが押されたとしてロジックを実行する
    func simulateCommandPress(at time: TimeInterval) {
        if time - lastCommandPressTime <= Constants.commandDoublePressInterval {
            onDoubleTap?()
            lastCommandPressTime = -1  // 連続検知を防ぐためリセット
        } else {
            lastCommandPressTime = time
        }
    }

    /// イベントを処理してCommandキー2回押しを判定する
    private func handleEvent(_ event: CGEvent) {
        // Commandフラグが立っているときのみ処理
        guard event.flags.contains(.maskCommand) else { return }

        // 左右のCommandキーのキーコードを確認
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard keyCode == kVK_Command || keyCode == kVK_RightCommand else { return }

        let now = Date().timeIntervalSinceReferenceDate
        if now - lastCommandPressTime <= Constants.commandDoublePressInterval {
            // 2回押し検知 → メインスレッドでコールバックを呼ぶ
            DispatchQueue.main.async { [weak self] in
                self?.onDoubleTap?()
            }
            lastCommandPressTime = -1  // 連続検知を防ぐためリセット
        } else {
            lastCommandPressTime = now
        }
    }

    /// Accessibility権限を確認し、なければシステム設定の権限ダイアログを表示する
    private func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]
        return AXIsProcessTrustedWithOptions(options)
    }
}
