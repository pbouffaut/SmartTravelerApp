import SwiftUI

struct SafetyView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var locationService: LocationService

    private var countryInfo: CountryInfo {
        CountryDatabase.info(for: locationService.currentCountryCode.isEmpty ? "US" : locationService.currentCountryCode)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ST.Spacing.l) {
                    // Emergency numbers
                    emergencyCard

                    // Driving info
                    drivingCard

                    // Transport apps
                    transportSection

                    // Travel tips
                    tipsSection
                }
                .padding(.horizontal, ST.Spacing.m)
                .padding(.top, ST.Spacing.s)
                .padding(.bottom, ST.Spacing.xl)
            }
            .screenBackground()
            .navigationTitle("Safety")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                        Text(countryInfo.name)
                            .font(ST.Font.label())
                    }
                    .foregroundColor(ST.Colors.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(ST.Colors.accentTint)
                    .cornerRadius(ST.Radius.pill)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .foregroundColor(ST.Colors.accent)
                    }
                }
            }
        }
    }

    // MARK: - Emergency Numbers

    private var emergencyCard: some View {
        VStack(alignment: .leading, spacing: ST.Spacing.s) {
            SectionHeader("Emergency Numbers", icon: "phone.fill")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: ST.Spacing.s) {
                emergencyTile("Emergency", number: countryInfo.emergencyNumber, icon: "sos", color: ST.Colors.danger)
                emergencyTile("Police", number: countryInfo.policeNumber, icon: "shield.fill", color: Color(hex: "#3478F6"))
                emergencyTile("Ambulance", number: countryInfo.ambulanceNumber, icon: "cross.fill", color: ST.Colors.success)
                emergencyTile("Fire", number: countryInfo.fireNumber, icon: "flame.fill", color: Color(hex: "#FF9500"))
            }
        }
    }

    private func emergencyTile(_ label: String, number: String, icon: String, color: Color) -> some View {
        Button(action: {
            callNumber(number)
        }) {
            VStack(spacing: ST.Spacing.s) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.14))
                    .cornerRadius(12)

                VStack(spacing: 2) {
                    Text(label)
                        .font(ST.Font.label())
                        .foregroundColor(ST.Colors.textSecondary)

                    Text(number)
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                        .foregroundColor(ST.Colors.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(ST.Colors.card)
            .cornerRadius(ST.Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: ST.Radius.card)
                    .stroke(ST.Colors.border, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Driving

    private var drivingCard: some View {
        CardView {
            HStack(spacing: 14) {
                Image(systemName: "car.fill")
                    .font(.system(size: 16))
                    .foregroundColor(ST.Colors.accent)
                    .frame(width: 36, height: 36)
                    .background(ST.Colors.accentTint)
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Driving Side")
                        .font(ST.Font.caption())
                        .foregroundColor(ST.Colors.textSecondary)
                    Text(countryInfo.drivingSide.capitalized)
                        .font(ST.Font.heading())
                        .foregroundColor(ST.Colors.textPrimary)
                }

                Spacer()

                Image(systemName: countryInfo.drivingSide == "left" ? "arrow.left" : "arrow.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(ST.Colors.accent)
            }
        }
    }

    // MARK: - Transport Apps

    private var transportSection: some View {
        VStack(alignment: .leading, spacing: ST.Spacing.s) {
            SectionHeader("Transport & Taxi", icon: "car.2.fill")

            ForEach(TransportApp.Category.allCases, id: \.rawValue) { category in
                let apps = countryInfo.transportApps.filter { $0.category == category }
                if !apps.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(category.rawValue)
                            .font(ST.Font.label())
                            .foregroundColor(ST.Colors.textTertiary)
                            .padding(.leading, 4)

                        ForEach(apps) { app in
                            transportRow(app)
                        }
                    }
                }
            }
        }
    }

    private func transportRow(_ app: TransportApp) -> some View {
        Button(action: {
            openApp(app)
        }) {
            HStack(spacing: 12) {
                Image(systemName: app.icon)
                    .font(.system(size: 14))
                    .foregroundColor(ST.Colors.accent)
                    .frame(width: 32, height: 32)
                    .background(ST.Colors.accentTint)
                    .cornerRadius(8)

                Text(app.name)
                    .font(ST.Font.body())
                    .foregroundColor(ST.Colors.textPrimary)

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 13))
                    .foregroundColor(ST.Colors.textTertiary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, ST.Spacing.m)
            .background(ST.Colors.card)
            .cornerRadius(ST.Radius.input)
            .overlay(
                RoundedRectangle(cornerRadius: ST.Radius.input)
                    .stroke(ST.Colors.border, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Travel Tips

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: ST.Spacing.s) {
            SectionHeader("Travel Tips", icon: "lightbulb.fill")

            ForEach(Array(countryInfo.travelTips.enumerated()), id: \.offset) { index, tip in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(ST.Font.label())
                        .foregroundColor(ST.Colors.accent)
                        .frame(width: 22, height: 22)
                        .background(ST.Colors.accentTint)
                        .cornerRadius(11)

                    Text(tip)
                        .font(ST.Font.body())
                        .foregroundColor(ST.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, ST.Spacing.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ST.Colors.card)
                .cornerRadius(ST.Radius.input)
                .overlay(
                    RoundedRectangle(cornerRadius: ST.Radius.input)
                        .stroke(ST.Colors.border, lineWidth: 0.5)
                )
            }
        }
    }

    // MARK: - Actions

    private func callNumber(_ number: String) {
        if let url = URL(string: "tel://\(number)") {
            UIApplication.shared.open(url)
        }
    }

    private func openApp(_ app: TransportApp) {
        if let scheme = app.urlScheme, let url = URL(string: scheme),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let storeURL = app.appStoreURL, let url = URL(string: storeURL) {
            UIApplication.shared.open(url)
        }
    }
}
