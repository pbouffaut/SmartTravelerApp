import SwiftUI

struct ClockView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var locationService: LocationService

    private var localTimeZone: TimeZone { locationService.currentTimeZone }
    private var homeTimeZone: TimeZone { settings.homeTimeZone }

    // DateFormatters are expensive to create — reuse them
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
    private static let compactFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d, yyyy"
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                // TimelineView fires every second but only redraws its own content,
                // not the NavigationStack / ScrollView / static cards around it.
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let date = context.date
                    VStack(spacing: ST.Spacing.l) {
                        localTimeCard(date: date)
                        timeDiffBadge(date: date)
                        homeTimeCard(date: date)
                        worldZones(date: date)
                    }
                    .padding(.horizontal, ST.Spacing.m)
                    .padding(.top, ST.Spacing.s)
                }
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
        }
    }

    // MARK: - Components

    private func localTimeCard(date: Date) -> some View {
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

                Text(timeString(for: localTimeZone, date: date))
                    .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
                    .foregroundColor(ST.Colors.textPrimary)
                    .frame(maxWidth: .infinity)

                Text(dateString(for: localTimeZone, date: date))
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

    private func timeDiffBadge(date: Date) -> some View {
        let localOffset = localTimeZone.secondsFromGMT(for: date)
        let homeOffset = homeTimeZone.secondsFromGMT(for: date)
        let diff = (localOffset - homeOffset) / 3600
        let sign = diff >= 0 ? "+" : ""
        return HStack(spacing: ST.Spacing.s) {
            Rectangle().fill(ST.Colors.border).frame(height: 0.5)
            Text("\(sign)\(diff)h")
                .font(ST.Font.caption())
                .foregroundColor(ST.Colors.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ST.Colors.card)
                .cornerRadius(ST.Radius.pill)
                .overlay(RoundedRectangle(cornerRadius: ST.Radius.pill).stroke(ST.Colors.border, lineWidth: 0.5))
            Rectangle().fill(ST.Colors.border).frame(height: 0.5)
        }
    }

    private func homeTimeCard(date: Date) -> some View {
        CardView {
            VStack(spacing: ST.Spacing.s) {
                HStack {
                    SectionHeader("Home Time", icon: "house.fill")
                    Spacer()
                    Text(homeCity)
                        .font(ST.Font.caption())
                        .foregroundColor(ST.Colors.textSecondary)
                }

                Text(timeString(for: homeTimeZone, date: date))
                    .font(.system(size: 42, weight: .ultraLight, design: .monospaced))
                    .foregroundColor(ST.Colors.textSecondary)
                    .frame(maxWidth: .infinity)

                Text(dateString(for: homeTimeZone, date: date))
                    .font(ST.Font.caption())
                    .foregroundColor(ST.Colors.textTertiary)

                Text(homeTimeZone.abbreviation() ?? "")
                    .font(ST.Font.label())
                    .foregroundColor(ST.Colors.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(ST.Colors.card)
                    .cornerRadius(ST.Radius.pill)
                    .overlay(RoundedRectangle(cornerRadius: ST.Radius.pill).stroke(ST.Colors.border, lineWidth: 0.5))
            }
        }
    }

    private func worldZones(date: Date) -> some View {
        let zones: [(name: String, tz: String)] = [
            ("New York", "America/New_York"),
            ("London",   "Europe/London"),
            ("Paris",    "Europe/Paris"),
            ("Dubai",    "Asia/Dubai"),
            ("Tokyo",    "Asia/Tokyo"),
            ("Sydney",   "Australia/Sydney"),
        ].filter { $0.tz != localTimeZone.identifier && $0.tz != homeTimeZone.identifier }

        return VStack(alignment: .leading, spacing: ST.Spacing.s) {
            SectionHeader("Other Zones", icon: "globe")
            ForEach(zones.prefix(4), id: \.tz) { zone in
                if let tz = TimeZone(identifier: zone.tz) {
                    HStack {
                        Text(zone.name)
                            .font(ST.Font.body())
                            .foregroundColor(ST.Colors.textSecondary)
                        Spacer()
                        Text(timeString(for: tz, date: date, compact: true))
                            .font(.system(size: 17, weight: .light, design: .monospaced))
                            .foregroundColor(ST.Colors.textPrimary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, ST.Spacing.m)
                    .background(ST.Colors.card)
                    .cornerRadius(ST.Radius.input)
                    .overlay(RoundedRectangle(cornerRadius: ST.Radius.input).stroke(ST.Colors.border, lineWidth: 0.5))
                }
            }
        }
    }

    // MARK: - Helpers

    private func timeString(for timeZone: TimeZone, date: Date, compact: Bool = false) -> String {
        let formatter = compact ? Self.compactFormatter : Self.timeFormatter
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    private func dateString(for timeZone: TimeZone, date: Date) -> String {
        Self.dateFormatter.timeZone = timeZone
        return Self.dateFormatter.string(from: date)
    }

    private var homeCity: String {
        let id = settings.homeTimeZoneIdentifier
        return id.split(separator: "/").last.map { String($0).replacingOccurrences(of: "_", with: " ") } ?? id
    }
}
