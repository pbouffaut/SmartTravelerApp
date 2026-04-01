import Foundation
import Combine
import Network

class ExchangeRateService: ObservableObject {
    @Published var rates: [String: Double] = [:]
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    @Published var isOffline = false

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var pollTimer: Timer?
    private let cacheKey = "cachedExchangeRates"
    private let cacheTimestampKey = "cachedExchangeRatesTimestamp"

    init() {
        loadCachedRates()
        startNetworkMonitoring()
    }

    deinit {
        pollTimer?.invalidate()
        monitor.cancel()
    }

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOffline = path.status != .satisfied
                if path.status == .satisfied {
                    self?.fetchRatesIfNeeded()
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    func startPolling(interval: TimeInterval = 3600) {
        fetchRatesIfNeeded()
        guard pollTimer == nil else { return } // already running
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.fetchRatesIfNeeded()
        }
    }

    private func fetchRatesIfNeeded() {
        // Don't fetch if updated within last 30 minutes
        if let lastUpdated, Date().timeIntervalSince(lastUpdated) < 1800 {
            return
        }
        fetchRates(base: "USD")
    }

    func fetchRates(base: String = "USD") {
        guard !isOffline else { return }
        isLoading = true

        let urlString = "https://open.er-api.com/v6/latest/\(base)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let ratesDict = json["rates"] as? [String: Double] else {
                    return
                }

                self?.rates = ratesDict
                self?.lastUpdated = Date()
                self?.cacheRates(ratesDict)
            }
        }.resume()
    }

    func convert(amount: Double, from: String, to: String) -> Double? {
        guard let fromRate = rates[from], let toRate = rates[to], fromRate > 0 else {
            return nil
        }
        // Convert via USD base
        let usdAmount = amount / fromRate
        return usdAmount * toRate
    }

    // MARK: - Caching

    private func cacheRates(_ rates: [String: Double]) {
        if let data = try? JSONEncoder().encode(rates) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
        }
    }

    private func loadCachedRates() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode([String: Double].self, from: data) {
            rates = cached
            let ts = UserDefaults.standard.double(forKey: cacheTimestampKey)
            if ts > 0 {
                lastUpdated = Date(timeIntervalSince1970: ts)
            }
        }
    }

    // MARK: - Helpers

    var lastUpdatedFormatted: String {
        guard let lastUpdated else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }

    static let commonCurrencies: [(code: String, name: String, flag: String)] = [
        ("USD", "US Dollar", "\u{1F1FA}\u{1F1F8}"),
        ("EUR", "Euro", "\u{1F1EA}\u{1F1FA}"),
        ("GBP", "British Pound", "\u{1F1EC}\u{1F1E7}"),
        ("JPY", "Japanese Yen", "\u{1F1EF}\u{1F1F5}"),
        ("AUD", "Australian Dollar", "\u{1F1E6}\u{1F1FA}"),
        ("CAD", "Canadian Dollar", "\u{1F1E8}\u{1F1E6}"),
        ("CHF", "Swiss Franc", "\u{1F1E8}\u{1F1ED}"),
        ("CNY", "Chinese Yuan", "\u{1F1E8}\u{1F1F3}"),
        ("SEK", "Swedish Krona", "\u{1F1F8}\u{1F1EA}"),
        ("NZD", "New Zealand Dollar", "\u{1F1F3}\u{1F1FF}"),
        ("MXN", "Mexican Peso", "\u{1F1F2}\u{1F1FD}"),
        ("SGD", "Singapore Dollar", "\u{1F1F8}\u{1F1EC}"),
        ("HKD", "Hong Kong Dollar", "\u{1F1ED}\u{1F1F0}"),
        ("NOK", "Norwegian Krone", "\u{1F1F3}\u{1F1F4}"),
        ("KRW", "South Korean Won", "\u{1F1F0}\u{1F1F7}"),
        ("TRY", "Turkish Lira", "\u{1F1F9}\u{1F1F7}"),
        ("INR", "Indian Rupee", "\u{1F1EE}\u{1F1F3}"),
        ("BRL", "Brazilian Real", "\u{1F1E7}\u{1F1F7}"),
        ("ZAR", "South African Rand", "\u{1F1FF}\u{1F1E6}"),
        ("THB", "Thai Baht", "\u{1F1F9}\u{1F1ED}"),
        ("AED", "UAE Dirham", "\u{1F1E6}\u{1F1EA}"),
        ("PLN", "Polish Zloty", "\u{1F1F5}\u{1F1F1}"),
        ("CZK", "Czech Koruna", "\u{1F1E8}\u{1F1FF}"),
        ("DKK", "Danish Krone", "\u{1F1E9}\u{1F1F0}"),
        ("COP", "Colombian Peso", "\u{1F1E8}\u{1F1F4}"),
        ("ARS", "Argentine Peso", "\u{1F1E6}\u{1F1F7}"),
        ("PEN", "Peruvian Sol", "\u{1F1F5}\u{1F1EA}"),
        ("CLP", "Chilean Peso", "\u{1F1E8}\u{1F1F1}"),
        ("PHP", "Philippine Peso", "\u{1F1F5}\u{1F1ED}"),
        ("IDR", "Indonesian Rupiah", "\u{1F1EE}\u{1F1E9}"),
        ("MYR", "Malaysian Ringgit", "\u{1F1F2}\u{1F1FE}"),
        ("VND", "Vietnamese Dong", "\u{1F1FB}\u{1F1F3}"),
        ("TWD", "Taiwan Dollar", "\u{1F1F9}\u{1F1FC}"),
        ("ILS", "Israeli Shekel", "\u{1F1EE}\u{1F1F1}"),
        ("EGP", "Egyptian Pound", "\u{1F1EA}\u{1F1EC}"),
        ("MAD", "Moroccan Dirham", "\u{1F1F2}\u{1F1E6}"),
        ("NGN", "Nigerian Naira", "\u{1F1F3}\u{1F1EC}"),
        ("KES", "Kenyan Shilling", "\u{1F1F0}\u{1F1EA}"),
    ]
}
