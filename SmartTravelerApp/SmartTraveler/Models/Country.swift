import Foundation

struct CountryInfo: Identifiable {
    let id: String // ISO country code
    let name: String
    let currency: String
    let currencySymbol: String
    let emergencyNumber: String
    let policeNumber: String
    let ambulanceNumber: String
    let fireNumber: String
    let timeZoneIdentifier: String
    let drivingSide: String
    let languages: [String]
    let transportApps: [TransportApp]
    let travelTips: [String]
}

struct TransportApp: Identifiable {
    let id = UUID()
    let name: String
    let icon: String // SF Symbol
    let urlScheme: String?
    let appStoreURL: String?
    let category: Category

    enum Category: String, CaseIterable {
        case rideshare = "Rideshare"
        case taxi = "Taxi"
        case publicTransport = "Public Transport"
        case bikescooter = "Bike / Scooter"
    }
}

// MARK: - Country Database

struct CountryDatabase {
    static func info(for countryCode: String) -> CountryInfo {
        database[countryCode.uppercased()] ?? defaultInfo(for: countryCode)
    }

    static func currencyCode(for countryCode: String) -> String {
        let locale = Locale(identifier: "en_\(countryCode.uppercased())")
        return locale.currency?.identifier ?? "USD"
    }

    static func timeZone(for countryCode: String) -> TimeZone {
        if let tz = NSTimeZone.knownTimeZoneNames.first(where: { tz in
            let parts = tz.split(separator: "/")
            return parts.count > 1
        }).flatMap({ TimeZone(identifier: $0) }) {
            return tz
        }
        return .current
    }

    private static func defaultInfo(for code: String) -> CountryInfo {
        let locale = Locale(identifier: "en_\(code.uppercased())")
        let name = Locale.current.localizedString(forRegionCode: code.uppercased()) ?? code
        let currency = locale.currency?.identifier ?? "USD"
        let symbol = currencySymbol(for: currency)
        return CountryInfo(
            id: code.uppercased(),
            name: name,
            currency: currency,
            currencySymbol: symbol,
            emergencyNumber: "112",
            policeNumber: "112",
            ambulanceNumber: "112",
            fireNumber: "112",
            timeZoneIdentifier: TimeZone.current.identifier,
            drivingSide: "right",
            languages: [],
            transportApps: defaultTransportApps,
            travelTips: [
                "Keep a copy of your passport in a separate location",
                "Register with your embassy when traveling abroad",
                "Always have local emergency numbers saved",
                "Keep some local cash for emergencies",
                "Check travel advisories before departure"
            ]
        )
    }

    static func currencySymbol(for code: String) -> String {
        let locale = NSLocale(localeIdentifier: code)
        return locale.displayName(forKey: .currencySymbol, value: code) ?? code
    }

    private static let defaultTransportApps: [TransportApp] = [
        TransportApp(name: "Uber", icon: "car.fill", urlScheme: "uber://", appStoreURL: "https://apps.apple.com/app/uber/id368677368", category: .rideshare),
        TransportApp(name: "Apple Maps", icon: "map.fill", urlScheme: "maps://", appStoreURL: nil, category: .publicTransport),
        TransportApp(name: "Google Maps", icon: "map.fill", urlScheme: "comgooglemaps://", appStoreURL: "https://apps.apple.com/app/google-maps/id585027354", category: .publicTransport),
    ]

    // MARK: - Database

    static let database: [String: CountryInfo] = [
        "US": CountryInfo(
            id: "US", name: "United States", currency: "USD", currencySymbol: "$",
            emergencyNumber: "911", policeNumber: "911", ambulanceNumber: "911", fireNumber: "911",
            timeZoneIdentifier: "America/New_York", drivingSide: "right",
            languages: ["en"],
            transportApps: [
                TransportApp(name: "Uber", icon: "car.fill", urlScheme: "uber://", appStoreURL: "https://apps.apple.com/app/uber/id368677368", category: .rideshare),
                TransportApp(name: "Lyft", icon: "car.fill", urlScheme: "lyft://", appStoreURL: "https://apps.apple.com/app/lyft/id529379082", category: .rideshare),
                TransportApp(name: "Transit", icon: "bus.fill", urlScheme: "transit://", appStoreURL: "https://apps.apple.com/app/transit/id498151501", category: .publicTransport),
            ],
            travelTips: ["Tipping is customary (15-20%)", "Sales tax is added at checkout", "Tap water is safe to drink", "Right-hand traffic"]
        ),
        "GB": CountryInfo(
            id: "GB", name: "United Kingdom", currency: "GBP", currencySymbol: "\u{00A3}",
            emergencyNumber: "999", policeNumber: "999", ambulanceNumber: "999", fireNumber: "999",
            timeZoneIdentifier: "Europe/London", drivingSide: "left",
            languages: ["en"],
            transportApps: [
                TransportApp(name: "Uber", icon: "car.fill", urlScheme: "uber://", appStoreURL: "https://apps.apple.com/app/uber/id368677368", category: .rideshare),
                TransportApp(name: "Bolt", icon: "car.fill", urlScheme: "bolt://", appStoreURL: "https://apps.apple.com/app/bolt/id675033630", category: .rideshare),
                TransportApp(name: "Citymapper", icon: "bus.fill", urlScheme: "citymapper://", appStoreURL: "https://apps.apple.com/app/citymapper/id469463298", category: .publicTransport),
            ],
            travelTips: ["Drive on the left side", "Tipping is 10-15%", "Contactless payment is widely accepted", "The Tube runs until ~midnight"]
        ),
        "FR": CountryInfo(
            id: "FR", name: "France", currency: "EUR", currencySymbol: "\u{20AC}",
            emergencyNumber: "112", policeNumber: "17", ambulanceNumber: "15", fireNumber: "18",
            timeZoneIdentifier: "Europe/Paris", drivingSide: "right",
            languages: ["fr"],
            transportApps: [
                TransportApp(name: "Uber", icon: "car.fill", urlScheme: "uber://", appStoreURL: "https://apps.apple.com/app/uber/id368677368", category: .rideshare),
                TransportApp(name: "Bolt", icon: "car.fill", urlScheme: "bolt://", appStoreURL: "https://apps.apple.com/app/bolt/id675033630", category: .rideshare),
                TransportApp(name: "RATP", icon: "tram.fill", urlScheme: "ratp://", appStoreURL: "https://apps.apple.com/app/ratp/id507107090", category: .publicTransport),
                TransportApp(name: "Citymapper", icon: "bus.fill", urlScheme: "citymapper://", appStoreURL: "https://apps.apple.com/app/citymapper/id469463298", category: .publicTransport),
            ],
            travelTips: ["Greet with 'Bonjour' when entering shops", "Tipping is included (service compris)", "Shops may close for lunch", "Metro runs until ~1am"]
        ),
        "JP": CountryInfo(
            id: "JP", name: "Japan", currency: "JPY", currencySymbol: "\u{00A5}",
            emergencyNumber: "110", policeNumber: "110", ambulanceNumber: "119", fireNumber: "119",
            timeZoneIdentifier: "Asia/Tokyo", drivingSide: "left",
            languages: ["ja"],
            transportApps: [
                TransportApp(name: "Japan Transit", icon: "tram.fill", urlScheme: nil, appStoreURL: "https://apps.apple.com/app/japan-transit-planner/id299490481", category: .publicTransport),
                TransportApp(name: "Uber", icon: "car.fill", urlScheme: "uber://", appStoreURL: "https://apps.apple.com/app/uber/id368677368", category: .rideshare),
                TransportApp(name: "GO Taxi", icon: "car.fill", urlScheme: nil, appStoreURL: "https://apps.apple.com/app/go-taxi/id1476498167", category: .taxi),
            ],
            travelTips: ["Tipping is not customary", "Remove shoes when entering homes", "Trains run on exact schedule", "Cash is still widely used", "Drive on the left side"]
        ),
        "DE": CountryInfo(
            id: "DE", name: "Germany", currency: "EUR", currencySymbol: "\u{20AC}",
            emergencyNumber: "112", policeNumber: "110", ambulanceNumber: "112", fireNumber: "112",
            timeZoneIdentifier: "Europe/Berlin", drivingSide: "right",
            languages: ["de"],
            transportApps: [
                TransportApp(name: "Uber", icon: "car.fill", urlScheme: "uber://", appStoreURL: "https://apps.apple.com/app/uber/id368677368", category: .rideshare),
                TransportApp(name: "FREE NOW", icon: "car.fill", urlScheme: "freenow://", appStoreURL: "https://apps.apple.com/app/free-now/id357852748", category: .taxi),
                TransportApp(name: "DB Navigator", icon: "tram.fill", urlScheme: nil, appStoreURL: "https://apps.apple.com/app/db-navigator/id343555245", category: .publicTransport),
            ],
            travelTips: ["Many shops are cash-only", "Shops closed on Sundays", "Recycling system (Pfand) for bottles", "Autobahn has suggested speed limits"]
        ),
        "ES": CountryInfo(
            id: "ES", name: "Spain", currency: "EUR", currencySymbol: "\u{20AC}",
            emergencyNumber: "112", policeNumber: "091", ambulanceNumber: "061", fireNumber: "080",
            timeZoneIdentifier: "Europe/Madrid", drivingSide: "right",
            languages: ["es"],
            transportApps: [
                TransportApp(name: "Uber", icon: "car.fill", urlScheme: "uber://", appStoreURL: "https://apps.apple.com/app/uber/id368677368", category: .rideshare),
                TransportApp(name: "Cabify", icon: "car.fill", urlScheme: "cabify://", appStoreURL: "https://apps.apple.com/app/cabify/id476087442", category: .rideshare),
                TransportApp(name: "Citymapper", icon: "bus.fill", urlScheme: "citymapper://", appStoreURL: "https://apps.apple.com/app/citymapper/id469463298", category: .publicTransport),
            ],
            travelTips: ["Lunch is typically 2-4pm", "Dinner starts at 9-10pm", "Siesta time is still observed in some areas", "Tipping 5-10% is appreciated"]
        ),
        "IT": CountryInfo(
            id: "IT", name: "Italy", currency: "EUR", currencySymbol: "\u{20AC}",
            emergencyNumber: "112", policeNumber: "113", ambulanceNumber: "118", fireNumber: "115",
            timeZoneIdentifier: "Europe/Rome", drivingSide: "right",
            languages: ["it"],
            transportApps: [
                TransportApp(name: "Uber", icon: "car.fill", urlScheme: "uber://", appStoreURL: "https://apps.apple.com/app/uber/id368677368", category: .rideshare),
                TransportApp(name: "FREE NOW", icon: "car.fill", urlScheme: "freenow://", appStoreURL: "https://apps.apple.com/app/free-now/id357852748", category: .taxi),
                TransportApp(name: "Moovit", icon: "bus.fill", urlScheme: "moovit://", appStoreURL: "https://apps.apple.com/app/moovit/id498477945", category: .publicTransport),
            ],
            travelTips: ["Coperto (cover charge) is normal at restaurants", "Validate train tickets before boarding", "Many museums closed on Mondays", "Tap water is safe to drink"]
        ),
        "TH": CountryInfo(
            id: "TH", name: "Thailand", currency: "THB", currencySymbol: "\u{0E3F}",
            emergencyNumber: "191", policeNumber: "191", ambulanceNumber: "1669", fireNumber: "199",
            timeZoneIdentifier: "Asia/Bangkok", drivingSide: "left",
            languages: ["th"],
            transportApps: [
                TransportApp(name: "Grab", icon: "car.fill", urlScheme: "grab://", appStoreURL: "https://apps.apple.com/app/grab/id647268330", category: .rideshare),
                TransportApp(name: "Bolt", icon: "car.fill", urlScheme: "bolt://", appStoreURL: "https://apps.apple.com/app/bolt/id675033630", category: .rideshare),
                TransportApp(name: "BTS SkyTrain", icon: "tram.fill", urlScheme: nil, appStoreURL: nil, category: .publicTransport),
            ],
            travelTips: ["Respect the monarchy at all times", "Remove shoes before entering temples", "Bargaining is expected at markets", "Drive on the left side"]
        ),
        "AU": CountryInfo(
            id: "AU", name: "Australia", currency: "AUD", currencySymbol: "A$",
            emergencyNumber: "000", policeNumber: "000", ambulanceNumber: "000", fireNumber: "000",
            timeZoneIdentifier: "Australia/Sydney", drivingSide: "left",
            languages: ["en"],
            transportApps: [
                TransportApp(name: "Uber", icon: "car.fill", urlScheme: "uber://", appStoreURL: "https://apps.apple.com/app/uber/id368677368", category: .rideshare),
                TransportApp(name: "DiDi", icon: "car.fill", urlScheme: "didi://", appStoreURL: "https://apps.apple.com/app/didi/id1449019894", category: .rideshare),
                TransportApp(name: "TripView", icon: "bus.fill", urlScheme: nil, appStoreURL: "https://apps.apple.com/app/tripview-sydney/id294730339", category: .publicTransport),
            ],
            travelTips: ["Drive on the left side", "Sun protection is essential (high UV)", "Tap water is safe", "Tipping is not expected but appreciated"]
        ),
        "MX": CountryInfo(
            id: "MX", name: "Mexico", currency: "MXN", currencySymbol: "MX$",
            emergencyNumber: "911", policeNumber: "911", ambulanceNumber: "911", fireNumber: "911",
            timeZoneIdentifier: "America/Mexico_City", drivingSide: "right",
            languages: ["es"],
            transportApps: [
                TransportApp(name: "Uber", icon: "car.fill", urlScheme: "uber://", appStoreURL: "https://apps.apple.com/app/uber/id368677368", category: .rideshare),
                TransportApp(name: "DiDi", icon: "car.fill", urlScheme: "didi://", appStoreURL: "https://apps.apple.com/app/didi/id1449019894", category: .rideshare),
                TransportApp(name: "Moovit", icon: "bus.fill", urlScheme: "moovit://", appStoreURL: "https://apps.apple.com/app/moovit/id498477945", category: .publicTransport),
            ],
            travelTips: ["Drink bottled water only", "Tipping 10-15% is customary", "Use authorized taxis or rideshare apps", "Avoid walking alone at night in unfamiliar areas"]
        ),
    ]
}
