import Foundation

class TranslationService: ObservableObject {
    @Published var translatedText: String = ""
    @Published var isTranslating = false
    @Published var errorMessage: String?

    func translate(text: String, from sourceLang: String, to targetLang: String, provider: AppSettings.TranslationProvider, apiKey: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        await MainActor.run {
            isTranslating = true
            errorMessage = nil
        }

        do {
            let result: String
            switch provider {
            case .apple:
                result = try await translateWithApple(text: text, from: sourceLang, to: targetLang)
            case .deepL:
                result = try await translateWithDeepL(text: text, from: sourceLang, to: targetLang, apiKey: apiKey)
            case .google:
                result = try await translateWithGoogle(text: text, from: sourceLang, to: targetLang, apiKey: apiKey)
            }

            await MainActor.run {
                translatedText = result
                isTranslating = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isTranslating = false
            }
        }
    }

    // MARK: - Apple Translation (free, on-device if available)

    private func translateWithApple(text: String, from: String, to: String) async throws -> String {
        // Uses a simple free translation endpoint as fallback
        // In production, use Apple's Translation framework (iOS 17.4+)
        // import Translation; let session = TranslationSession(from: .init(identifier: from), to: .init(identifier: to))
        throw TranslationError.providerUnavailable("Apple Translation requires iOS 17.4+. Please use DeepL or Google with an API key.")
    }

    // MARK: - DeepL

    private func translateWithDeepL(text: String, from: String, to: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw TranslationError.noAPIKey
        }

        let isFreePlan = apiKey.hasSuffix(":fx")
        let baseURL = isFreePlan
            ? "https://api-free.deepl.com/v2/translate"
            : "https://api.deepl.com/v2/translate"

        guard let url = URL(string: baseURL) else {
            throw TranslationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "text": [text],
            "source_lang": from.uppercased(),
            "target_lang": deepLLanguageCode(to)
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TranslationError.apiError("DeepL API error")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let translations = json["translations"] as? [[String: Any]],
              let translated = translations.first?["text"] as? String else {
            throw TranslationError.parseError
        }

        return translated
    }

    // MARK: - Google Translate

    private func translateWithGoogle(text: String, from: String, to: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw TranslationError.noAPIKey
        }

        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        let urlString = "https://translation.googleapis.com/language/translate/v2?key=\(apiKey)&q=\(encoded)&source=\(from)&target=\(to)"

        guard let url = URL(string: urlString) else {
            throw TranslationError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TranslationError.apiError("Google Translate API error")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any],
              let translations = dataObj["translations"] as? [[String: Any]],
              let translated = translations.first?["translatedText"] as? String else {
            throw TranslationError.parseError
        }

        return translated
    }

    // MARK: - Helpers

    private func deepLLanguageCode(_ code: String) -> String {
        let upper = code.uppercased()
        // DeepL uses specific codes for some languages
        switch upper {
        case "EN": return "EN-US"
        case "PT": return "PT-BR"
        default: return upper
        }
    }

    enum TranslationError: LocalizedError {
        case noAPIKey
        case invalidURL
        case apiError(String)
        case parseError
        case providerUnavailable(String)

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "Please add your API key in Settings"
            case .invalidURL: return "Invalid request"
            case .apiError(let msg): return msg
            case .parseError: return "Could not parse translation response"
            case .providerUnavailable(let msg): return msg
            }
        }
    }
}

// MARK: - Supported Languages

extension TranslationService {
    static let supportedLanguages: [(code: String, name: String, flag: String)] = [
        ("en", "English", "\u{1F1EC}\u{1F1E7}"),
        ("fr", "French", "\u{1F1EB}\u{1F1F7}"),
        ("es", "Spanish", "\u{1F1EA}\u{1F1F8}"),
        ("de", "German", "\u{1F1E9}\u{1F1EA}"),
        ("it", "Italian", "\u{1F1EE}\u{1F1F9}"),
        ("pt", "Portuguese", "\u{1F1F5}\u{1F1F9}"),
        ("ja", "Japanese", "\u{1F1EF}\u{1F1F5}"),
        ("zh", "Chinese", "\u{1F1E8}\u{1F1F3}"),
        ("ko", "Korean", "\u{1F1F0}\u{1F1F7}"),
        ("ar", "Arabic", "\u{1F1F8}\u{1F1E6}"),
        ("hi", "Hindi", "\u{1F1EE}\u{1F1F3}"),
        ("ru", "Russian", "\u{1F1F7}\u{1F1FA}"),
        ("nl", "Dutch", "\u{1F1F3}\u{1F1F1}"),
        ("pl", "Polish", "\u{1F1F5}\u{1F1F1}"),
        ("tr", "Turkish", "\u{1F1F9}\u{1F1F7}"),
        ("sv", "Swedish", "\u{1F1F8}\u{1F1EA}"),
        ("da", "Danish", "\u{1F1E9}\u{1F1F0}"),
        ("no", "Norwegian", "\u{1F1F3}\u{1F1F4}"),
        ("th", "Thai", "\u{1F1F9}\u{1F1ED}"),
        ("vi", "Vietnamese", "\u{1F1FB}\u{1F1F3}"),
    ]
}
