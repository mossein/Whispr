import Foundation

final class Settings {
    static let shared = Settings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let onboardingCompleted = "onboardingCompleted"
        static let triggerKeyCode = "triggerKeyCode"
        static let triggerKeyName = "triggerKeyName"
        static let modelName = "modelName"
    }

    var onboardingCompleted: Bool {
        get { defaults.bool(forKey: Keys.onboardingCompleted) }
        set { defaults.set(newValue, forKey: Keys.onboardingCompleted) }
    }

    var triggerKeyCode: Int {
        get {
            let val = defaults.integer(forKey: Keys.triggerKeyCode)
            return val == 0 ? 0x36 : val
        }
        set { defaults.set(newValue, forKey: Keys.triggerKeyCode) }
    }

    var triggerKeyName: String {
        get { defaults.string(forKey: Keys.triggerKeyName) ?? "Right Command" }
        set { defaults.set(newValue, forKey: Keys.triggerKeyName) }
    }

    var modelName: String {
        get { defaults.string(forKey: Keys.modelName) ?? "base.en" }
        set { defaults.set(newValue, forKey: Keys.modelName) }
    }

    struct ModelOption: Identifiable {
        let id: String
        let name: String
        let size: String
        let description: String
    }

    static let availableModels: [ModelOption] = [
        ModelOption(id: "tiny.en", name: "Tiny (English)", size: "~75 MB", description: "Fastest, lower accuracy"),
        ModelOption(id: "base.en", name: "Base (English)", size: "~145 MB", description: "Fast, decent accuracy"),
        ModelOption(id: "small.en", name: "Small (English)", size: "~470 MB", description: "Good balance"),
        ModelOption(id: "large-v3", name: "Large v3", size: "~1.5 GB", description: "Best accuracy, multilingual"),
    ]

    private init() {}
}
