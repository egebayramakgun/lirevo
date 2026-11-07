// SPDX-License-Identifier: GPL-3.0-or-later

import AppKit
import Core
import Foundation
import Testing
@testable import Lirevo

/// M1-T2: Menü çubuğu uygulaması iskeleti.
@MainActor
@Suite struct MenuBarAppTests {
    @Test func infoPlistHidesDockIcon() {
        let value = Bundle.main.object(forInfoDictionaryKey: "LSUIElement")
        #expect((value as? Bool) == true || (value as? String) == "1" || (value as? String) == "YES")
    }

    @Test func runsAsAccessoryApp() {
        #expect(NSApplication.shared.activationPolicy() == .accessory)
    }

    @Test func appInfoComesFromBuildSettings() {
        let info = AppInfo.current
        #expect(!info.name.isEmpty)
        #expect(info.bundleIdentifier == Bundle.main.bundleIdentifier)
        #expect(info.website?.scheme == "https")
    }

    @Test func panelWidthMatchesBrief() {
        #expect(MenuPanelView.width == 340)
    }
}

/// CLAUDE.md: Kullanıcıya görünen her metin TR + EN.
@Suite struct LocalizationTests {
    private func keys(for language: String) throws -> Set<String> {
        let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
        let table = try #require(Bundle(path: path)?.path(forResource: "Localizable", ofType: "strings"))
        let dict = try #require(NSDictionary(contentsOfFile: table) as? [String: String])
        return Set(dict.keys)
    }

    @Test func turkishAndEnglishHaveSameKeys() throws {
        let en = try keys(for: "en")
        let tr = try keys(for: "tr")
        #expect(!en.isEmpty)
        #expect(en == tr)
    }

    @Test func turkishIsActuallyTranslated() throws {
        let path = try #require(Bundle.main.path(forResource: "tr", ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))
        #expect(bundle.localizedString(forKey: "Quit", value: nil, table: nil) == "Çıkış")
    }
}
