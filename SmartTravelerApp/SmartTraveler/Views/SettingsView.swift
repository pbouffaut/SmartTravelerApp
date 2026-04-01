import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var locationService: LocationService

    @State private var showCurrencyPicker = false
    @State private var showTimeZonePicker = false
    @State private var showLanguagePicker = false
    @State private var showFakeLocationPicker = false
    @State private var apiKeyInput = ""

    var body: some View {
        ScrollView {
            VStack(spacing: ST.Spacing.l) {
                // Home Settings
                homeSection

                // Translation Provider
                translationSection

                // API Key
                if settings.translationProvider.requiresKey {
                    apiKeySection
                }

                // Simulated Location
                simulatedLocationSection

                // Current Location
                locationSection

                // About
                aboutSection
            }
            .padding(.horizontal, ST.Spacing.m)
            .padding(.top, ST.Spacing.s)
            .padding(.bottom, ST.Spacing.xl)
        }
        .screenBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            apiKeyInput = settings.translationAPIKey
        }
        .sheet(isPresented: $showCurrencyPicker) {
            currencyPickerSheet
        }
        .sheet(isPresented: $showTimeZonePicker) {
            timeZonePickerSheet
        }
        .sheet(isPresented: $showLanguagePicker) {
            languagePickerSheet
        }
        .sheet(isPresented: $showFakeLocationPicker) {
            fakeLocationPickerSheet
        }
    }

    // MARK: - Sections

    private var homeSection: some View {
        VStack(alignment: .leading, spacing: ST.Spacing.s) {
            SectionHeader("Home Base", icon: "house.fill")

            CardView {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "coloncurrencysign.circle",
                        title: "Home Currency",
                        value: settings.homeCurrency
                    ) {
                        showCurrencyPicker = true
                    }

                    Divider().background(ST.Colors.border)

                    SettingsRow(
                        icon: "clock",
                        title: "Home Time Zone",
                        value: homeCity
                    ) {
                        showTimeZonePicker = true
                    }

                    Divider().background(ST.Colors.border)

                    SettingsRow(
                        icon: "globe",
                        title: "Home Language",
                        value: languageName(for: settings.homeLanguage)
                    ) {
                        showLanguagePicker = true
                    }
                }
            }
        }
    }

    private var translationSection: some View {
        VStack(alignment: .leading, spacing: ST.Spacing.s) {
            SectionHeader("Translation", icon: "bubble.left.and.text.bubble.right")

            CardView {
                VStack(spacing: ST.Spacing.s) {
                    ForEach(AppSettings.TranslationProvider.allCases) { provider in
                        Button(action: {
                            settings.translationProvider = provider
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: settings.translationProvider == provider ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(settings.translationProvider == provider ? ST.Colors.accent : ST.Colors.textTertiary)
                                    .font(.system(size: 18))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(provider.displayName)
                                        .font(ST.Font.body())
                                        .foregroundColor(ST.Colors.textPrimary)
                                    if provider.requiresKey {
                                        Text("Requires API key")
                                            .font(ST.Font.label())
                                            .foregroundColor(ST.Colors.textTertiary)
                                    } else {
                                        Text("Free, on-device (iOS 17.4+)")
                                            .font(ST.Font.label())
                                            .foregroundColor(ST.Colors.success)
                                    }
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: ST.Spacing.s) {
            SectionHeader("API Key", icon: "key.fill")

            CardView {
                VStack(spacing: ST.Spacing.s) {
                    HStack {
                        Image(systemName: "key")
                            .foregroundColor(ST.Colors.textTertiary)
                        SecureField("Enter your API key", text: $apiKeyInput)
                            .font(ST.Font.body())
                            .foregroundColor(ST.Colors.textPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding(12)
                    .background(ST.Colors.surface)
                    .cornerRadius(ST.Radius.input)

                    if apiKeyInput != settings.translationAPIKey {
                        AccentButton("Save Key", icon: "checkmark") {
                            settings.translationAPIKey = apiKeyInput
                        }
                    }

                    Text("Your key is stored locally on this device")
                        .font(ST.Font.label())
                        .foregroundColor(ST.Colors.textTertiary)
                }
            }
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: ST.Spacing.s) {
            SectionHeader("Current Location", icon: "location.fill")

            CardView {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "mappin",
                        title: "City",
                        value: locationService.currentCity.isEmpty ? "Detecting..." : locationService.currentCity
                    )

                    Divider().background(ST.Colors.border)

                    SettingsRow(
                        icon: "flag",
                        title: "Country",
                        value: locationService.currentCountryName.isEmpty ? "Detecting..." : locationService.currentCountryName
                    )

                    Divider().background(ST.Colors.border)

                    SettingsRow(
                        icon: "coloncurrencysign.circle",
                        title: "Local Currency",
                        value: locationService.localCurrency.isEmpty ? "--" : locationService.localCurrency
                    )

                    Divider().background(ST.Colors.border)

                    SettingsRow(
                        icon: "clock",
                        title: "Local Time Zone",
                        value: locationService.currentTimeZone.abbreviation() ?? "--"
                    )
                }
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: ST.Spacing.s) {
            SectionHeader("About", icon: "info.circle")

            CardView {
                VStack(spacing: ST.Spacing.s) {
                    HStack {
                        Text("Smart Traveler")
                            .font(ST.Font.heading())
                            .foregroundColor(ST.Colors.textPrimary)
                        Spacer()
                        Text("v1.0")
                            .font(ST.Font.caption())
                            .foregroundColor(ST.Colors.textTertiary)
                    }

                    Text("Your AI-powered travel companion. Uses your device location to provide smart, contextual travel information wherever you go.")
                        .font(ST.Font.caption())
                        .foregroundColor(ST.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Simulated Location

    private var simulatedLocationSection: some View {
        VStack(alignment: .leading, spacing: ST.Spacing.s) {
            HStack(spacing: ST.Spacing.s) {
                SectionHeader("Simulated Location", icon: "location.slash.fill")
                if settings.fakeLocationEnabled {
                    Text("ACTIVE")
                        .font(ST.Font.label())
                        .tracking(1)
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "#FFB340"))
                        .cornerRadius(ST.Radius.pill)
                }
            }

            CardView {
                VStack(spacing: ST.Spacing.s) {
                    // Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Override Location")
                                .font(ST.Font.body())
                                .foregroundColor(ST.Colors.textPrimary)
                            Text("For testing or planning a trip")
                                .font(ST.Font.label())
                                .foregroundColor(ST.Colors.textSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { settings.fakeLocationEnabled },
                            set: { enabled in
                                settings.fakeLocationEnabled = enabled
                                if enabled {
                                    locationService.applyFakeLocation(countryCode: settings.fakeCountryCode)
                                } else {
                                    locationService.clearFakeLocation()
                                }
                            }
                        ))
                        .tint(Color(hex: "#FFB340"))
                    }

                    if settings.fakeLocationEnabled {
                        Divider().background(ST.Colors.border)

                        // Destination picker row
                        Button(action: { showFakeLocationPicker = true }) {
                            HStack(spacing: 12) {
                                let info = CountryDatabase.info(for: settings.fakeCountryCode)
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "#FFB340"))
                                    .frame(width: 28, height: 28)
                                    .background(Color(hex: "#FFB340").opacity(0.15))
                                    .cornerRadius(7)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(info.name)
                                        .font(ST.Font.body())
                                        .foregroundColor(ST.Colors.textPrimary)
                                    Text("\(info.currency)  •  \(TimeZone(identifier: info.timeZoneIdentifier)?.abbreviation() ?? "")")
                                        .font(ST.Font.label())
                                        .foregroundColor(ST.Colors.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(ST.Colors.textTertiary)
                            }
                        }

                        // Warning note
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "#FFB340"))
                            Text("All features use simulated location data")
                                .font(ST.Font.label())
                                .foregroundColor(ST.Colors.textSecondary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "#FFB340").opacity(0.1))
                        .cornerRadius(ST.Radius.input)
                    }
                }
            }
        }
    }

    // MARK: - Picker Sheets

    private var currencyPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(ExchangeRateService.commonCurrencies, id: \.code) { currency in
                    Button(action: {
                        settings.homeCurrency = currency.code
                        showCurrencyPicker = false
                    }) {
                        HStack(spacing: 12) {
                            Text(currency.flag)
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(currency.code)
                                    .font(ST.Font.body())
                                    .fontWeight(.semibold)
                                    .foregroundColor(ST.Colors.textPrimary)
                                Text(currency.name)
                                    .font(ST.Font.caption())
                                    .foregroundColor(ST.Colors.textSecondary)
                            }
                            Spacer()
                            if settings.homeCurrency == currency.code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(ST.Colors.accent)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .listRowBackground(ST.Colors.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ST.Colors.background)
            .navigationTitle("Home Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showCurrencyPicker = false }
                        .foregroundColor(ST.Colors.accent)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var timeZonePickerSheet: some View {
        NavigationStack {
            List {
                ForEach(commonTimeZones, id: \.identifier) { tz in
                    Button(action: {
                        settings.homeTimeZoneIdentifier = tz.identifier
                        showTimeZonePicker = false
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cityName(from: tz.identifier))
                                    .font(ST.Font.body())
                                    .foregroundColor(ST.Colors.textPrimary)
                                Text(tz.abbreviation() ?? "")
                                    .font(ST.Font.caption())
                                    .foregroundColor(ST.Colors.textSecondary)
                            }
                            Spacer()
                            if settings.homeTimeZoneIdentifier == tz.identifier {
                                Image(systemName: "checkmark")
                                    .foregroundColor(ST.Colors.accent)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .listRowBackground(ST.Colors.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ST.Colors.background)
            .navigationTitle("Home Time Zone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showTimeZonePicker = false }
                        .foregroundColor(ST.Colors.accent)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var languagePickerSheet: some View {
        NavigationStack {
            List {
                ForEach(TranslationService.supportedLanguages, id: \.code) { lang in
                    Button(action: {
                        settings.homeLanguage = lang.code
                        showLanguagePicker = false
                    }) {
                        HStack(spacing: 12) {
                            Text(lang.flag)
                                .font(.system(size: 20))
                            Text(lang.name)
                                .font(ST.Font.body())
                                .foregroundColor(ST.Colors.textPrimary)
                            Spacer()
                            if settings.homeLanguage == lang.code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(ST.Colors.accent)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .listRowBackground(ST.Colors.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ST.Colors.background)
            .navigationTitle("Home Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showLanguagePicker = false }
                        .foregroundColor(ST.Colors.accent)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers

    private var homeCity: String {
        cityName(from: settings.homeTimeZoneIdentifier)
    }

    private func cityName(from identifier: String) -> String {
        identifier.split(separator: "/").last.map { String($0).replacingOccurrences(of: "_", with: " ") } ?? identifier
    }

    private func languageName(for code: String) -> String {
        TranslationService.supportedLanguages.first { $0.code == code }?.name ?? code
    }

    private var fakeLocationPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(fakeDestinations, id: \.countryCode) { dest in
                    Button(action: {
                        settings.fakeCountryCode = dest.countryCode
                        locationService.applyFakeLocation(countryCode: dest.countryCode)
                        showFakeLocationPicker = false
                    }) {
                        HStack(spacing: 12) {
                            Text(dest.flag)
                                .font(.system(size: 22))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dest.city)
                                    .font(ST.Font.body())
                                    .foregroundColor(ST.Colors.textPrimary)
                                Text("\(dest.countryName)  •  \(dest.currency)")
                                    .font(ST.Font.caption())
                                    .foregroundColor(ST.Colors.textSecondary)
                            }
                            Spacer()
                            if settings.fakeCountryCode == dest.countryCode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "#FFB340"))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .listRowBackground(ST.Colors.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ST.Colors.background)
            .navigationTitle("Choose Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showFakeLocationPicker = false }
                        .foregroundColor(Color(hex: "#FFB340"))
                }
            }
        }
        .presentationDetents([.large])
    }

    private struct FakeDestination {
        let flag: String
        let city: String
        let countryName: String
        let countryCode: String
        let currency: String
    }

    private var fakeDestinations: [FakeDestination] {
        [
            FakeDestination(flag: "\u{1F1FA}\u{1F1F8}", city: "New York",      countryName: "United States",   countryCode: "US", currency: "USD"),
            FakeDestination(flag: "\u{1F1EC}\u{1F1E7}", city: "London",        countryName: "United Kingdom",  countryCode: "GB", currency: "GBP"),
            FakeDestination(flag: "\u{1F1EB}\u{1F1F7}", city: "Paris",         countryName: "France",          countryCode: "FR", currency: "EUR"),
            FakeDestination(flag: "\u{1F1EF}\u{1F1F5}", city: "Tokyo",         countryName: "Japan",           countryCode: "JP", currency: "JPY"),
            FakeDestination(flag: "\u{1F1E9}\u{1F1EA}", city: "Berlin",        countryName: "Germany",         countryCode: "DE", currency: "EUR"),
            FakeDestination(flag: "\u{1F1EA}\u{1F1F8}", city: "Barcelona",     countryName: "Spain",           countryCode: "ES", currency: "EUR"),
            FakeDestination(flag: "\u{1F1EE}\u{1F1F9}", city: "Rome",          countryName: "Italy",           countryCode: "IT", currency: "EUR"),
            FakeDestination(flag: "\u{1F1F9}\u{1F1ED}", city: "Bangkok",       countryName: "Thailand",        countryCode: "TH", currency: "THB"),
            FakeDestination(flag: "\u{1F1E6}\u{1F1FA}", city: "Sydney",        countryName: "Australia",       countryCode: "AU", currency: "AUD"),
            FakeDestination(flag: "\u{1F1F2}\u{1F1FD}", city: "Mexico City",   countryName: "Mexico",          countryCode: "MX", currency: "MXN"),
        ]
    }

    private var commonTimeZones: [TimeZone] {
        let ids = [
            "Pacific/Honolulu", "America/Anchorage", "America/Los_Angeles",
            "America/Denver", "America/Chicago", "America/New_York",
            "America/Sao_Paulo", "Atlantic/Reykjavik", "Europe/London",
            "Europe/Paris", "Europe/Berlin", "Europe/Helsinki",
            "Europe/Moscow", "Asia/Dubai", "Asia/Kolkata",
            "Asia/Bangkok", "Asia/Shanghai", "Asia/Tokyo",
            "Australia/Sydney", "Pacific/Auckland",
        ]
        return ids.compactMap { TimeZone(identifier: $0) }
    }
}
