import CoreText
import Foundation

/// Registers bundled `.ttf` files (OFL: Space Grotesk, JetBrains Mono). Xcode copies them into `Resources/`.
enum BundledFontRegistration {
    static func register() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) else {
            return
        }

        for url in urls {
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        }
    }
}
