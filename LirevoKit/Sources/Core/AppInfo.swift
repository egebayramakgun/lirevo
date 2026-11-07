// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation

/// Uygulama kimliği. Ürün adı, bundle ID ve web sitesi kodda sabit yazılmaz;
/// `Config/App.xcconfig` → Info.plist → buradan okunur (CLAUDE.md, karar 4).
public struct AppInfo: Sendable, Equatable {
    /// Info.plist'te web sitesini taşıyan anahtar (`APP_WEBSITE` build ayarından doldurulur).
    public static let websiteInfoKey = "AppWebsiteURL"

    public let name: String
    public let bundleIdentifier: String
    public let version: String
    public let build: String
    public let website: URL?

    public init(name: String, bundleIdentifier: String, version: String, build: String, website: URL?) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.build = build
        self.website = website
    }

    /// Info.plist sözlüğünden okur. Eksik alanlar boş olmayan yedek değerlerle doldurulur.
    public init(infoDictionary info: [String: Any]) {
        func string(_ key: String) -> String? {
            guard let value = info[key] as? String, !value.isEmpty else { return nil }
            return value
        }
        name = string("CFBundleDisplayName") ?? string("CFBundleName") ?? string("CFBundleExecutable") ?? "App"
        bundleIdentifier = string("CFBundleIdentifier") ?? "unknown.bundle"
        version = string("CFBundleShortVersionString") ?? "0.0.0"
        build = string("CFBundleVersion") ?? "0"
        website = string(Self.websiteInfoKey).flatMap { raw in
            guard let url = URL(string: raw), url.scheme == "https" else { return nil }
            return url
        }
    }

    public init(bundle: Bundle) {
        self.init(infoDictionary: bundle.infoDictionary ?? [:])
    }

    /// Çalışan uygulamanın kimliği.
    public static let current = AppInfo(bundle: .main)

    /// Ağ istekleri için `User-Agent` (ör. LRCLIB). Kişisel veri içermez.
    public var userAgent: String {
        if let website {
            return "\(name)/\(version) (\(website.absoluteString))"
        }
        return "\(name)/\(version)"
    }
}
