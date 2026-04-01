import SwiftUI

@main
struct SmartTravelerApp: App {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var locationService = LocationService()
    @StateObject private var exchangeRateService = ExchangeRateService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(locationService)
                .environmentObject(exchangeRateService)
                .preferredColorScheme(.dark)
                .onAppear {
                    locationService.startTracking()
                }
        }
    }
}
