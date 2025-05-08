import SwiftUI
import Combine

// Enum to define the available theme options
enum AppearanceScheme: String, CaseIterable, Identifiable {
    case system = "System Default"
    case light = "Light Mode"
    case dark = "Dark Mode"

    var id: String { self.rawValue }

    // Helper to convert our enum to SwiftUI's ColorScheme?
    func toColorScheme() -> ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil // nil tells SwiftUI to use the system's appearance
        }
    }
}

class ThemeManager: ObservableObject {
    // @AppStorage provides the initial value for storedSchemeRawValue before init() runs.
    @AppStorage("selectedAppearance") private var storedSchemeRawValue: String = AppearanceScheme.system.rawValue

    // Initialize currentScheme directly using its underlying Published wrapper.
    // We read from AppStorage *outside* the direct assignment to currentScheme if using a temporary,
    // or we make currentScheme's initialization not depend on self.storedSchemeRawValue for its *own* line of init.
    @Published var currentScheme: AppearanceScheme

    private var cancellable: AnyCancellable?

    init() {
        // Step 1: Give currentScheme a definite initial value WITHOUT referencing any other 'self' properties on its initialization line.
        // We'll use a temporary default here and then immediately reconcile.
        self.currentScheme = .system // Or any default from AppearanceScheme

        // Step 2: Now that all properties are initialized, synchronize currentScheme with AppStorage.
        // Read from AppStorage (storedSchemeRawValue is already loaded).
        let schemeFromStorage = AppearanceScheme(rawValue: storedSchemeRawValue) ?? .system
        
        // If the value from storage is different from our temporary default for currentScheme, update currentScheme.
        // This will NOT cause a loop with the sink yet because we use .dropFirst().
        if self.currentScheme != schemeFromStorage {
            self.currentScheme = schemeFromStorage
        }
        
        // Step 3: Ensure AppStorage is consistent if it had an invalid value.
        // If schemeFromStorage defaulted (e.g., storedSchemeRawValue was garbage),
        // and it's different from what's now in storedSchemeRawValue, update storedSchemeRawValue.
        if storedSchemeRawValue != self.currentScheme.rawValue {
            storedSchemeRawValue = self.currentScheme.rawValue
        }
        
        print("ThemeManager: Initialized. Final current scheme: \(self.currentScheme.rawValue)")

        // Step 4: Subscribe to future changes of `currentScheme` to update AppStorage.
        cancellable = $currentScheme
            .dropFirst() // Ignore the initial value and reconciliation changes.
            .sink { [weak self] newScheme in
                guard let self = self else { return }
                if self.storedSchemeRawValue != newScheme.rawValue {
                    self.storedSchemeRawValue = newScheme.rawValue
                    print("ThemeManager: currentScheme changed to \(newScheme.rawValue), updated AppStorage.")
                }
            }
    }
}
