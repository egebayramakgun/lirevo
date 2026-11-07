// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import Testing
@testable import Core

@Suite struct AppInfoTests {
    @Test func readsAllFieldsFromInfoDictionary() {
        let info = AppInfo(infoDictionary: [
            "CFBundleName": "Example",
            "CFBundleIdentifier": "org.example.app",
            "CFBundleShortVersionString": "1.2.3",
            "CFBundleVersion": "45",
            AppInfo.websiteInfoKey: "https://example.org",
        ])
        #expect(info.name == "Example")
        #expect(info.bundleIdentifier == "org.example.app")
        #expect(info.version == "1.2.3")
        #expect(info.build == "45")
        #expect(info.website == URL(string: "https://example.org"))
        #expect(info.userAgent == "Example/1.2.3 (https://example.org)")
    }

    @Test func prefersDisplayName() {
        let info = AppInfo(infoDictionary: ["CFBundleDisplayName": "Shown", "CFBundleName": "Internal"])
        #expect(info.name == "Shown")
    }

    @Test func rejectsNonHTTPSWebsite() {
        let info = AppInfo(infoDictionary: [AppInfo.websiteInfoKey: "http://example.org"])
        #expect(info.website == nil)
        #expect(info.userAgent == "App/0.0.0")
    }

    @Test func fallsBackWhenEmpty() {
        let info = AppInfo(infoDictionary: [:])
        #expect(info.name == "App")
        #expect(info.bundleIdentifier == "unknown.bundle")
        #expect(info.website == nil)
    }
}
