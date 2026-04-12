# タスク: ClipBoardApp 実装

> **ファイル**: `tasks/20260410_implement-clipboard-app.md`
> **作成日**: 2026-04-10
> **関連仕様**: PRD-001, DS-001
> **見積もり**: -
> **ステータス**: Todo

---

## 目的・背景

macOSのクリップボード履歴を最大30件保持し、Commandキー2回押しでマウス付近にポップアップ表示して過去のコピー内容を呼び出せるメニューバー常駐アプリを実装する。

---

## 前提条件・依存

- [ ] Xcode がインストールされていること
- [ ] macOS 13 Ventura 以降の開発環境であること
- [ ] `specs/requirements/PRD-001_clipboard-history.md` が Approved であること
- [ ] `specs/design/DS-001_clipboard-history.md` が Approved であること

---

## 作業チェックリスト

### 準備
- [ ] 仕様書確認（`specs/requirements/PRD-001_clipboard-history.md`）
- [ ] 設計書確認（`specs/design/DS-001_clipboard-history.md`）
- [ ] XcodeでmacOS Appプロジェクト新規作成（SwiftUI, AppKit統合）
- [ ] `src/` ディレクトリ構成をDS-001に合わせて作成

### フェーズ1: 基盤実装
- [ ] `Constants.swift` — 全定数を定義
- [ ] `ClipboardItem.swift` — データモデル実装（text / imageData / thumbnail）
- [ ] `HistoryStore.swift` — 履歴管理（追加・重複排除・30件上限）
- [ ] `Info.plist` — `LSUIElement = true` 設定（Dock非表示）

### フェーズ2: クリップボード監視
- [ ] `ClipboardMonitor.swift` — NSPasteboardポーリング（0.5秒）
- [ ] テキスト変更の検知・取得
- [ ] 画像変更の検知・取得（元データをDataで保持）
- [ ] サムネイル非同期生成（thumbnailMaxDimension: 40pt）
- [ ] 自アプリによる変更の除外

### フェーズ3: グローバルホットキー
- [ ] `HotkeyDetector.swift` — CGEventTapによるCommandキー監視
- [ ] 2回押し判定ロジック（0.3秒以内）
- [ ] Accessibility権限チェック・権限要求ダイアログ表示

### フェーズ4: ポップアップUI
- [ ] `PopupWindowController.swift` — NSPanel管理
- [ ] 元アプリの保存（NSWorkspace.shared.frontmostApplication）
- [ ] マウス位置取得・画面端考慮の位置計算
- [ ] 閉じる時に元アプリへフォーカスを返す（activate()）
- [ ] `PopupView.swift` — SwiftUI履歴一覧UI
- [ ] テキストアイテム表示（先頭100文字プレビュー）
- [ ] 画像アイテム表示（thumbnailを使用）
- [ ] キーボード操作（↑↓選択、Enter決定、Esc閉じる）
- [ ] アイテム選択時: クリップボード設定 → 閉じる → 元アプリにフォーカスを返す

### フェーズ5: メニューバー
- [ ] `AppDelegate.swift` — NSStatusItem実装
- [ ] メニュー: 「履歴をクリア」
- [ ] メニュー: 「終了」

### フェーズ6: DMGパッケージング
- [ ] アプリビルド（Release構成）
- [ ] DMGファイル生成
- [ ] 受け取り側向けREADME作成（初回起動手順を記載）
- [ ] 動作確認（別Macまたはクリーン環境）

### テスト
- [ ] `HistoryStoreTests` — 追加・重複排除・30件上限のユニットテスト
- [ ] `ClipboardMonitorTests` — 変更検知ロジックのユニットテスト
- [ ] `HotkeyDetectorTests` — 2回押し判定ロジックのユニットテスト
- [ ] `PopupWindowControllerTests` — 位置計算ロジックのユニットテスト
- [ ] 手動テスト: テキストコピー→ポップアップ表示→選択→貼り付け
- [ ] 手動テスト: 画像コピー→ポップアップ表示→選択→貼り付け
- [ ] 手動テスト: Esc・外クリックで元アプリにフォーカスが戻る
- [ ] 手動テスト: 24時間連続稼働でのメモリ使用量確認（Instruments）

### ドキュメント
- [ ] 各ファイルに日本語コメント付与
- [ ] 配布用README作成（初回起動手順）

---

## 実装メモ

<!-- 作業中に気づいたことや判断事項を記録 -->

---

## 完了条件

- [ ] PRD-001 FR-001〜FR-007 の受け入れ条件を全て満たす
- [ ] メモリ消費が通常使用時 < 50MB
- [ ] テストカバレッジ80%以上（ユニットテスト対象範囲）
- [ ] 手動テスト全項目通過

---

## ブロッカー・課題

<!-- 作業を止めている問題があれば記録 -->
