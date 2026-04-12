import Testing
import Foundation
@testable import ClipBoardApp

/// HotkeyDetector の2回押し判定ロジックのユニットテスト
/// ※ CGEventTap（システムイベント）は使わず、判定ロジックのみをテスト対象にする
struct HotkeyDetectorTests {

    // MARK: - 2回押し判定

    /// 判定間隔内（0.3秒以内）に2回押した場合はコールバックが呼ばれる
    @Test func doublePressWithinIntervalTriggersCallback() {
        let detector = HotkeyDetector()
        var callCount = 0
        detector.onDoubleTap = { callCount += 1 }

        detector.simulateCommandPress(at: 0.0)
        detector.simulateCommandPress(at: 0.2)  // 0.3秒以内

        #expect(callCount == 1)
    }

    /// 判定間隔外（0.3秒超）では2回押しと判定されない
    @Test func doublePressOutsideIntervalDoesNotTrigger() {
        let detector = HotkeyDetector()
        var callCount = 0
        detector.onDoubleTap = { callCount += 1 }

        detector.simulateCommandPress(at: 0.0)
        detector.simulateCommandPress(at: 0.5)  // 0.3秒超

        #expect(callCount == 0)
    }

    /// 2回押し検知後はリセットされ、続けてすぐ押しても連続検知しない
    @Test func afterDoublePressResetPreventsImmediateReTrigger() {
        let detector = HotkeyDetector()
        var callCount = 0
        detector.onDoubleTap = { callCount += 1 }

        detector.simulateCommandPress(at: 0.0)
        detector.simulateCommandPress(at: 0.1)  // 1回目のダブル検知
        detector.simulateCommandPress(at: 0.2)  // リセット後の1回目扱い → 検知されない

        #expect(callCount == 1)
    }

    /// ちょうど0.3秒（境界値）は検知される
    @Test func doublePressAtExactBoundaryIsDetected() {
        let detector = HotkeyDetector()
        var callCount = 0
        detector.onDoubleTap = { callCount += 1 }

        detector.simulateCommandPress(at: 0.0)
        detector.simulateCommandPress(at: Constants.commandDoublePressInterval)

        #expect(callCount == 1)
    }
}
