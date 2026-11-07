// SPDX-License-Identifier: GPL-3.0-or-later

import Core
import SwiftUI

/// Menü çubuğu uygulaması. Dock ikonu yoktur (`LSUIElement = YES`, docs/prd.md F-01).
@main
struct LirevoApp: App {
    private let appInfo = AppInfo.current

    var body: some Scene {
        MenuBarExtra {
            MenuPanelView(appInfo: appInfo)
        } label: {
            // Geçici simge: nihai şablon görsel docs/ui_ux_brief.md §2 ile M7-T2'de gelir.
            Image(systemName: "music.note")
                .accessibilityLabel(Text(verbatim: appInfo.name))
        }
        .menuBarExtraStyle(.window)
    }
}
