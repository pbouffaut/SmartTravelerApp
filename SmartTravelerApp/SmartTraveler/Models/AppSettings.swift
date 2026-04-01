import Foundation
import CoreLocation

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var homeCurrency: String {
        didSet { UserDefaults.standard.set(homeCurrency, forKey: "homeCurrency") }
    }
    @Published var homeTimeZoneIdentifier: String {
        didSet { UserDefaults.standard.set(homeTimeZoneIdentifier, forKey: "homeTimeZone") }
    }
    @Published var homeLanguage: String {
        didSet { UserDefaults.standard.set(homeLanguage, forKey: "homeLanguage") }
    }
    @Published var translationAPIKey: String {
        didSet { UserDefaults.standard.set(translationAPIKey, forKey: "translationAPIKey") }
    }
    @Published var translationProvider: TranslationProvider {
        didSet { UserDefaults.standard.set(translationProvider.rawValue, forKey: "translationProvider") }
    }

    // Current location state
    @Published var currentCountryCode: String = ""
    @Published var currentCity: String = ""
    @Published var currentCoordinate: CLLocationCoordinate2D?

    var homeTimeZone: TimeZone {
        TimeZone(identifier: homeTimeZoneIdentifier) ?? .current
    }

    enum TranslationProvider: String, CaseIterable, Identifiable {
        case apple = "apple"
        case deepL = "deepl"
        case google = "google"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .apple: return "Apple Translate"
            case .deepL: return "DeepL"
            case .google: return "Google Translate"
            }
        }

        var requiresKey: Bool {
            self != .apple
        }
    }

    private init() {
        self.homeCurrency = UserDefaults.standard.string(forKey: "homeCurrency") ?? "USD"
        self.homeTimeZoneIdentifier = UserDefaults.standard.string(forKey: "homeTimeZone") ?? TimeZone.current.identifier
        self.homeLanguage = UserDefaults.standard.string(forKey: "homeLanguage") ?? Locale.current.language.languageCode?.identifier ?? "en"
        self.translationAPIKey = UserDefaults.standard.string(forKey: "translationAPIKey") ?? ""
        let providerRaw = UserDefaults.standard.string(forKey: "translationProvider") ?? "apple"
        self.translationProvider = TranslationProvider(rawValue: providerRaw) ?? .apple
    }
}
