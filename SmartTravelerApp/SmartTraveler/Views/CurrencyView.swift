import SwiftUI

struct CurrencyView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var exchangeRate: ExchangeRateService

    @State private var amount: String = "100"
    @State private var isReversed = false
    @FocusState private var isAmountFocused: Bool

    private var localCurrency: String {
        locationService.localCurrency.isEmpty ? "EUR" : locationService.localCurrency
    }

    private var homeCurrency: String {
        settings.homeCurrency
    }

    private var fromCurrency: String { isReversed ? homeCurrency : localCurrency }
    private var toCurrency: String { isReversed ? localCurrency : homeCurrency }

    private var convertedAmount: Double? {
        guard let amt = Double(amount) else { return nil }
        return exchangeRate.convert(amount: amt, from: fromCurrency, to: toCurrency)
    }

    private var rate: Double? {
        exchangeRate.convert(amount: 1, from: fromCurrency, to: toCurrency)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ST.Spacing.l) {
                    // Location banner
                    locationBanner

                    // Converter card
                    converterCard

                    // Rate info
                    rateInfoCard

                    // Quick amounts
                    quickAmounts
                }
                .padding(.horizontal, ST.Spacing.m)
                .padding(.top, ST.Spacing.s)
            }
            .screenBackground()
            .navigationTitle("Currency")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .foregroundColor(ST.Colors.accent)
                    }
                }
            }
            .onAppear {
                exchangeRate.startPolling()
            }
            .onTapGesture {
                isAmountFocused = false
            }
        }
    }

    // MARK: - Components

    private var locationBanner: some View {
        CardView {
            HStack(spacing: 12) {
                Image(systemName: locationService.isSimulated ? "location.slash.fill" : "location.fill")
                    .font(.system(size: 14))
                    .foregroundColor(locationService.isSimulated ? Color(hex: "#FFB340") : ST.Colors.accent)
                    .frame(width: 32, height: 32)
                    .background((locationService.isSimulated ? Color(hex: "#FFB340") : ST.Colors.accent).opacity(0.14))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    if locationService.currentCity.isEmpty {
                        Text("Detecting location...")
                            .font(ST.Font.body())
                            .foregroundColor(ST.Colors.textSecondary)
                    } else {
                        Text("\(locationService.currentCity), \(locationService.currentCountryName)")
                            .font(ST.Font.body())
                            .foregroundColor(ST.Colors.textPrimary)
                        Text("Local currency: \(localCurrency)")
                            .font(ST.Font.caption())
                            .foregroundColor(ST.Colors.textSecondary)
                    }
                }
                Spacer()
                if locationService.isSimulated {
                    Text("SIMULATED")
                        .font(ST.Font.label())
                        .tracking(0.8)
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#FFB340"))
                        .cornerRadius(ST.Radius.pill)
                }
            }
        }
    }

    private var converterCard: some View {
        CardView {
            VStack(spacing: ST.Spacing.m) {
                // From
                VStack(alignment: .leading, spacing: ST.Spacing.s) {
                    SectionHeader(fromCurrency, icon: "arrow.up.circle")

                    HStack {
                        Text(CountryDatabase.currencySymbol(for: fromCurrency))
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                            .foregroundColor(ST.Colors.textSecondary)

                        TextField("0", text: $amount)
                            .font(.system(size: 36, weight: .light, design: .monospaced))
                            .foregroundColor(ST.Colors.textPrimary)
                            .keyboardType(.decimalPad)
                            .focused($isAmountFocused)
                            .multilineTextAlignment(.leading)
                    }
                }

                // Swap button
                HStack {
                    Rectangle()
                        .fill(ST.Colors.border)
                        .frame(height: 0.5)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isReversed.toggle()
                        }
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ST.Colors.accent)
                            .frame(width: 36, height: 36)
                            .background(ST.Colors.accentTint)
                            .cornerRadius(18)
                    }
                    Rectangle()
                        .fill(ST.Colors.border)
                        .frame(height: 0.5)
                }

                // To
                VStack(alignment: .leading, spacing: ST.Spacing.s) {
                    SectionHeader(toCurrency, icon: "arrow.down.circle")

                    HStack {
                        Text(CountryDatabase.currencySymbol(for: toCurrency))
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                            .foregroundColor(ST.Colors.textSecondary)

                        Text(formattedAmount(convertedAmount))
                            .font(.system(size: 36, weight: .light, design: .monospaced))
                            .foregroundColor(ST.Colors.accent)
                    }
                }
            }
        }
    }

    private var rateInfoCard: some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exchange Rate")
                        .font(ST.Font.caption())
                        .foregroundColor(ST.Colors.textSecondary)
                    if let rate {
                        Text("1 \(fromCurrency) = \(String(format: "%.4f", rate)) \(toCurrency)")
                            .font(ST.Font.body())
                            .foregroundColor(ST.Colors.textPrimary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if exchangeRate.isOffline {
                        HStack(spacing: 4) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 10))
                            Text("Offline")
                                .font(ST.Font.label())
                        }
                        .foregroundColor(ST.Colors.danger)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(exchangeRate.lastUpdatedFormatted)
                            .font(ST.Font.caption())
                    }
                    .foregroundColor(ST.Colors.textTertiary)
                }
            }
        }
    }

    private var quickAmounts: some View {
        VStack(alignment: .leading, spacing: ST.Spacing.s) {
            SectionHeader("Quick Convert", icon: "bolt.fill")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: ST.Spacing.s) {
                ForEach([10, 20, 50, 100, 200, 500], id: \.self) { quickAmount in
                    Button(action: {
                        amount = "\(quickAmount)"
                        isAmountFocused = false
                    }) {
                        VStack(spacing: 4) {
                            Text("\(quickAmount)")
                                .font(ST.Font.heading())
                                .foregroundColor(ST.Colors.textPrimary)
                            if let converted = exchangeRate.convert(amount: Double(quickAmount), from: fromCurrency, to: toCurrency) {
                                Text("\(formattedAmount(converted)) \(toCurrency)")
                                    .font(ST.Font.label())
                                    .foregroundColor(ST.Colors.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ST.Colors.card)
                        .cornerRadius(ST.Radius.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: ST.Radius.card)
                                .stroke(amount == "\(quickAmount)" ? ST.Colors.accent.opacity(0.5) : ST.Colors.border, lineWidth: 0.5)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func formattedAmount(_ value: Double?) -> String {
        guard let value else { return "--" }
        if value >= 1000 {
            return String(format: "%.0f", value)
        } else if value >= 1 {
            return String(format: "%.2f", value)
        } else {
            return String(format: "%.4f", value)
        }
    }
}
