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

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 1000 // Update every 1km
    }

    func startTracking() {
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
        guard let location = locations.last else { return }

        // Only reverse geocode if moved significantly
        if let current = currentLocation,
           location.distance(from: current) < 500 {
            return
        }

        currentLocation = location

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self, let placemark = placemarks?.first else { return }

            DispatchQueue.main.async {
                self.currentCity = placemark.locality ?? placemark.administrativeArea ?? ""
                self.currentCountryCode = placemark.isoCountryCode ?? ""
                self.currentCountryName = placemark.country ?? ""

                if let tz = placemark.timeZone {
                    self.currentTimeZone = tz
                }

                self.localCurrency = CountryDatabase.currencyCode(for: self.currentCountryCode)

                // Update shared settings
                let settings = AppSettings.shared
                settings.currentCountryCode = self.currentCountryCode
                settings.currentCity = self.currentCity
                settings.currentCoordinate = location.coordinate
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
