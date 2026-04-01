import SwiftUI

struct ClockView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var locationService: LocationService

    @State private var currentDate = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var localTimeZone: TimeZone {
        locationService.currentTimeZone
    }

    private var homeTimeZone: TimeZone {
        settings.homeTimeZone
    }

    private var timeDifference: Int {
        let localOffset = localTimeZone.secondsFromGMT(for: currentDate)
        let homeOffset = homeTimeZone.secondsFromGMT(for: currentDate)
        return (localOffset - homeOffset) / 3600
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ST.Spacing.l) {
                    // Local time (large)
                    localTimeCard

                    // Time difference indicator
                    timeDiffBadge

                    // Home time
                    homeTimeCard

                    // World zones
                    worldZones
                }
                .padding(.horizontal, ST.Spacing.m)
                .padding(.top, ST.Spacing.s)
            }
            .screenBackground()
            .navigationTitle("World Clock")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .foregroundColor(ST.Colors.accent)
                    }
                }
            }
            .onReceive(timer) { _ in
                currentDate = Date()
            }
        }
    }

    // MARK: - Components

    private var localTimeCard: some View {
        CardView {
            VStack(spacing: ST.Spacing.s) {
                HStack {
                    SectionHeader("Local Time", icon: locationService.isSimulated ? "location.slash.fill" : "location.fill")
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
                    } else if !locationService.currentCity.isEmpty {
                        Text(locationService.currentCity)
                            .font(ST.Font.caption())
                            .foregroundColor(ST.Colors.textSecondary)
                    }
                }

                Text(timeString(for: localTimeZone))
                    .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
                    .foregroundColor(ST.Colors.textPrimary)
                    .frame(maxWidth: .infinity)

                Text(dateString(for: localTimeZone))
                    .font(ST.Font.body())
                    .foregroundColor(ST.Colors.textSecondary)

                Text(localTimeZone.abbreviation() ?? "")
                    .font(ST.Font.label())
                    .foregroundColor(ST.Colors.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(ST.Colors.accentTint)
                    .cornerRadius(ST.Radius.pill)
            }
        }
    }

    private var timeDiffBadge: some View {
        HStack(spacing: ST.Spacing.s) {
            Rectangle()
                .fill(ST.Colors.border)
                .frame(height: 0.5)

            let diff = timeDifference
            let sign = diff >= 0 ? "+" : ""
            Text("\(sign)\(diff)h")
                .font(ST.Font.caption())
                .foregroundColor(ST.Colors.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ST.Colors.card)
                .cornerRadius(ST.Radius.pill)
                .overlay(
                    RoundedRectangle(cornerRadius: ST.Radius.pill)
                        .stroke(ST.Colors.border, lineWidth: 0.5)
                )

            Rectangle()
                .fill(ST.Colors.border)
                .frame(height: 0.5)
        }
    }

    private var homeTimeCard: some View {
        CardView {
            VStack(spacing: ST.Spacing.s) {
                HStack {
                    SectionHeader("Home Time", icon: "house.fill")
                    Spacer()
                    Text(homeCity)
                        .font(ST.Font.caption())
                        .foregroundColor(ST.Colors.textSecondary)
                }

                Text(timeString(for: homeTimeZone))
                    .font(.system(size: 42, weight: .ultraLight, design: .monospaced))
                    .foregroundColor(ST.Colors.textSecondary)
                    .frame(maxWidth: .infinity)

                Text(dateString(for: homeTimeZone))
                    .font(ST.Font.caption())
                    .foregroundColor(ST.Colors.textTertiary)

                Text(homeTimeZone.abbreviation() ?? "")
                    .font(ST.Font.label())
                    .foregroundColor(ST.Colors.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(ST.Colors.card)
                    .cornerRadius(ST.Radius.pill)
                    .overlay(
                        RoundedRectangle(cornerRadius: ST.Radius.pill)
                            .stroke(ST.Colors.border, lineWidth: 0.5)
                    )
            }
        }
    }

    private var worldZones: some View {
        VStack(alignment: .leading, spacing: ST.Spacing.s) {
            SectionHeader("Other Zones", icon: "globe")

            let zones: [(name: String, tz: String)] = [
                ("New York", "America/New_York"),
                ("London", "Europe/London"),
                ("Paris", "Europe/Paris"),
                ("Dubai", "Asia/Dubai"),
                ("Tokyo", "Asia/Tokyo"),
                ("Sydney", "Australia/Sydney"),
            ].filter { $0.tz != localTimeZone.identifier && $0.tz != homeTimeZone.identifier }

            ForEach(zones.prefix(4), id: \.tz) { zone in
                if let tz = TimeZone(identifier: zone.tz) {
                    HStack {
                        Text(zone.name)
                            .font(ST.Font.body())
                            .foregroundColor(ST.Colors.textSecondary)
                        Spacer()
                        Text(timeString(for: tz, compact: true))
                            .font(.system(size: 17, weight: .light, design: .monospaced))
                            .foregroundColor(ST.Colors.textPrimary)
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
            }
        }
    }

    // MARK: - Helpers

    private func timeString(for timeZone: TimeZone, compact: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = compact ? "HH:mm" : "HH:mm:ss"
        return formatter.string(from: currentDate)
    }

    private func dateString(for timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: currentDate)
    }

    private var homeCity: String {
        let id = settings.homeTimeZoneIdentifier
        return id.split(separator: "/").last.map { String($0).replacingOccurrences(of: "_", with: " ") } ?? id
    }
}
