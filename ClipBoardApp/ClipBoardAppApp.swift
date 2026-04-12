import SwiftUI

/// アプリのエントリポイント（メニューバー常駐アプリ）
@main
struct ClipBoardAppApp: App {
    /// AppDelegateをSwiftUI Appライフサイクルに接続する
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // メニューバーアプリのためウィンドウは不要
        // Settings シーンを空で定義してメニューバー専用にする
        Settings {
            EmptyView()
        }
    }
}
