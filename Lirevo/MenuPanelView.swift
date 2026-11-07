// SPDX-License-Identifier: GPL-3.0-or-later

import AppKit
import Core
import SwiftUI

/// Menü çubuğu paneli iskeleti (M1-T2). Bölümler docs/ui_ux_brief.md §4'e göre
/// sonraki görevlerde eklenir: Şimdi çalıyor (M2-T8), Sistem Durumu (M1-T5),
/// sahneler ve hızlı geçişler (M7-T2).
struct MenuPanelView: View {
    let appInfo: AppInfo

    /// docs/ui_ux_brief.md §4: 340 pt genişlik.
    static let width: CGFloat = 340

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            emptyState
            Divider()
            footer
        }
        .frame(width: Self.width)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(verbatim: appInfo.name)
                .font(.headline)
            Spacer()
            Text(verbatim: appInfo.version)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note.list")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("Open a song in Spotify or Music.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("panel.emptyState")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 14)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("q")
            .accessibilityIdentifier("panel.quit")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

#Preview {
    MenuPanelView(appInfo: AppInfo(
        name: "Preview", bundleIdentifier: "preview", version: "0.0.0", build: "0", website: nil
    ))
}
