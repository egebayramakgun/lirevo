// SPDX-License-Identifier: GPL-3.0-or-later

import Testing
import Core
import Persistence
import NowPlaying
import Lyrics
import Palette
import Analysis
import SceneEngine
import Rendering
import Presentation
import Platform
import Language
import Services

/// M1-T1: Tüm modüller derleniyor ve birlikte bağlanabiliyor.
@Suite struct ModuleGraphTests {
    @Test func allModulesLink() {
        let names = [
            CoreModule.name, PersistenceModule.name, NowPlayingModule.name, LyricsModule.name,
            PaletteModule.name, AnalysisModule.name, SceneEngineModule.name, RenderingModule.name,
            PresentationModule.name, PlatformModule.name, LanguageModule.name, ServicesModule.name,
        ]
        #expect(Set(names).count == 12)
    }
}
