import SwiftUI
import AppKit

/// クリップボード履歴を表示するポップアップUI
struct PopupView: View {
    @ObservedObject var historyStore: HistoryStore
    /// ESCや外クリックで閉じるコールバック
    let onClose: () -> Void
    /// アイテム選択時のコールバック（クリップボード設定＋ペーストはController側で処理）
    let onSelectItem: (ClipboardItem) -> Void

    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            if historyStore.items.isEmpty {
                emptyView
            } else {
                itemListView
            }
        }
        .frame(width: Constants.popupWidth, height: Constants.popupHeight)
        .background(Color(NSColor.windowBackgroundColor))
        // macOS 13対応のキーボードハンドラをオーバーレイ
        .background(
            KeyHandlerView(
                onEscape: { onClose() },
                onReturn: { selectItem(at: selectedIndex) },
                onUpArrow: { selectedIndex = max(0, selectedIndex - 1) },
                onDownArrow: { selectedIndex = min(historyStore.items.count - 1, selectedIndex + 1) }
            )
        )
    }

    /// ヘッダー（タイトルと件数）
    private var headerView: some View {
        HStack {
            Text("クリップボード履歴")
                .font(.subheadline).bold()
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            Spacer()
            Text("\(historyStore.items.count)/\(Constants.maxHistoryCount)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.trailing, 10)
        }
    }

    /// 履歴が空のときの表示
    private var emptyView: some View {
        VStack {
            Spacer()
            Text("履歴がありません")
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    /// 履歴一覧（クリック選択対応）
    private var itemListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(historyStore.items.enumerated()), id: \.element.id) { pair in
                        let index = pair.offset
                        let item = pair.element
                        ItemRowView(item: item, isSelected: index == selectedIndex)
                            .id(item.id)
                            .onTapGesture { selectItem(at: index) }
                        Divider()
                    }
                }
            }
            .onChange(of: selectedIndex) { newIndex in
                guard newIndex < historyStore.items.count else { return }
                let item = historyStore.items[newIndex]
                withAnimation { proxy.scrollTo(item.id, anchor: .center) }
            }
        }
    }

    /// アイテムを選択してコントローラに通知する（クリップボード設定・ペーストはController側）
    private func selectItem(at index: Int) {
        guard index < historyStore.items.count else { return }
        onSelectItem(historyStore.items[index])
    }
}

// MARK: - KeyHandlerView

/// キーボードイベントを処理するNSViewRepresentable（macOS 13対応）
private struct KeyHandlerView: NSViewRepresentable {
    let onEscape: () -> Void
    let onReturn: () -> Void
    let onUpArrow: () -> Void
    let onDownArrow: () -> Void

    func makeNSView(context: Context) -> KeyCapturingNSView {
        let view = KeyCapturingNSView()
        view.onEscape = onEscape
        view.onReturn = onReturn
        view.onUpArrow = onUpArrow
        view.onDownArrow = onDownArrow
        return view
    }

    func updateNSView(_ nsView: KeyCapturingNSView, context: Context) {
        nsView.onEscape = onEscape
        nsView.onReturn = onReturn
        nsView.onUpArrow = onUpArrow
        nsView.onDownArrow = onDownArrow
    }
}

/// キーイベントを受け取るNSViewサブクラス
final class KeyCapturingNSView: NSView {
    var onEscape: (() -> Void)?
    var onReturn: (() -> Void)?
    var onUpArrow: (() -> Void)?
    var onDownArrow: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // ウィンドウに追加されたらファーストレスポンダーになる
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: onEscape?()    // Escape
        case 36: onReturn?()    // Return
        case 126: onUpArrow?()  // ↑ Arrow
        case 125: onDownArrow?() // ↓ Arrow
        default: super.keyDown(with: event)
        }
    }
}

// MARK: - ItemRowView

/// 履歴アイテム1件の行View
private struct ItemRowView: View {
    let item: ClipboardItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            contentPreview
            Spacer()
            Text(item.copiedAt, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
    }

    /// テキストまたは画像サムネイルのプレビュー（1行のみ）
    @ViewBuilder
    private var contentPreview: some View {
        switch item.type {
        case .text:
            Text(String(item.text?.prefix(Constants.textPreviewLength) ?? ""))
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .image:
            if let thumbnail = item.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: Constants.thumbnailMaxDimension,
                        height: Constants.thumbnailMaxDimension
                    )
            }
        }
    }
}
