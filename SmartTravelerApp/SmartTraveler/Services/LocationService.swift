import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    @Published var currentLocation: CLLocation?
    @Published var currentCity: String = ""
    @Published var currentCountryCode: String = ""
    @Published var currentCountryName: String = ""
    @Published var currentTimeZone: TimeZone = .current
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var localCurrency: String = ""
    @Published var isSimulated: Bool = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 1000 // Update every 1km
    }

    func startTracking() {
        let settings = AppSettings.shared
        if settings.fakeLocationEnabled {
            applyFakeLocation(countryCode: settings.fakeCountryCode)
        } else {
            manager.requestWhenInUseAuthorization()
            manager.startUpdatingLocation()
        }
    }

    func applyFakeLocation(countryCode: String) {
        let info = CountryDatabase.info(for: countryCode)
        let tz = TimeZone(identifier: info.timeZoneIdentifier) ?? .current
        let city = info.timeZoneIdentifier.split(separator: "/").last
            .map { String($0).replacingOccurrences(of: "_", with: " ") } ?? info.name
        // Single objectWillChange notification for all writes
        objectWillChange.send()
        currentCity = city
        currentCountryCode = info.id
        currentCountryName = info.name
        currentTimeZone = tz
        localCurrency = info.currency
        isSimulated = true

        let settings = AppSettings.shared
        settings.currentCountryCode = info.id
        settings.currentCity = city
    }

    func clearFakeLocation() {
        objectWillChange.send()
        isSimulated = false
        currentCity = ""
        currentCountryCode = ""
        currentCountryName = ""
        currentTimeZone = .current
        localCurrency = ""
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !AppSettings.shared.fakeLocationEnabled else { return }
        guard let location = locations.last else { return }

        // Only reverse geocode if moved significantly
        if let current = currentLocation,
           location.distance(from: current) < 500 {
            return
        }

        currentLocation = location

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self, let placemark = placemarks?.first else { return }
            // Compute values on background before touching main thread
            let city = placemark.locality ?? placemark.administrativeArea ?? ""
            let countryCode = placemark.isoCountryCode ?? ""
            let countryName = placemark.country ?? ""
            let tz = placemark.timeZone
            let currency = CountryDatabase.currencyCode(for: countryCode)

            DispatchQueue.main.async {
                // Single objectWillChange fires once; all writes happen in the same runloop pass
                self.objectWillChange.send()
                self.currentCity = city
                self.currentCountryCode = countryCode
                self.currentCountryName = countryName
                if let tz { self.currentTimeZone = tz }
                self.localCurrency = currency

                let settings = AppSettings.shared
                settings.currentCountryCode = countryCode
                settings.currentCity = city
                settings.currentCoordinate = location.coordinate
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
