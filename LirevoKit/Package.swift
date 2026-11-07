// swift-tools-version: 6.0
// SPDX-License-Identifier: GPL-3.0-or-later

import PackageDescription

// Modül yapısı ve bağımlılık yönü: docs/trd.md §3.
// Alt modüller üsttekileri bilmez. Yeni üçüncü taraf bağımlılık eklenmez (izinli: GRDB, Sparkle).

let package = Package(
    name: "LirevoKit",
    defaultLocalization: "en",
    platforms: [.macOS("14.2")],
    products: [
        .library(
            name: "LirevoKit",
            targets: [
                "Core", "Persistence", "NowPlaying", "Lyrics", "Palette", "Analysis",
                "SceneEngine", "Rendering", "Presentation", "Platform", "Language", "Services",
            ]
        ),
    ],
    targets: [
        .target(name: "CAtomics"),
        .target(name: "Core"),
        .target(name: "Persistence", dependencies: ["Core"]),
        .target(name: "NowPlaying", dependencies: ["Core"]),
        .target(name: "Platform", dependencies: ["Core"]),
        .target(name: "Services", dependencies: ["Core"]),
        .target(name: "Analysis", dependencies: ["Core", "CAtomics"]),
        .target(name: "Palette", dependencies: ["Core", "Persistence"]),
        .target(name: "Lyrics", dependencies: ["Core", "Persistence"]),
        .target(name: "Language", dependencies: ["Core", "Persistence"]),
        .target(name: "SceneEngine", dependencies: ["Core", "NowPlaying", "Lyrics", "Palette", "Analysis"]),
        .target(name: "Rendering", dependencies: ["Core", "SceneEngine", "Language"]),
        .target(name: "Presentation", dependencies: ["Core", "SceneEngine", "Rendering", "Platform"]),

        .testTarget(name: "CoreTests", dependencies: ["Core"]),
        .testTarget(name: "CAtomicsTests", dependencies: ["CAtomics"]),
        .testTarget(name: "PackageStructureTests", dependencies: [
            "Core", "Persistence", "NowPlaying", "Lyrics", "Palette", "Analysis",
            "SceneEngine", "Rendering", "Presentation", "Platform", "Language", "Services",
        ]),
    ],
    swiftLanguageModes: [.v6]
)
