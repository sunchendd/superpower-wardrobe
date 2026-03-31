import Foundation
import CoreLocation

protocol LocationProviding: AnyObject {
    func fetchCurrentLocation() async throws -> CLLocation
    func resolveLocality(for location: CLLocation) async throws -> String?
}

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate, LocationProviding {
    static let shared = LocationService()

    enum LocationServiceError: LocalizedError {
        case permissionDenied
        case permissionRestricted
        case authorizationFailed
        case unavailableLocation

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Location permission denied"
            case .permissionRestricted:
                return "Location permission restricted"
            case .authorizationFailed:
                return "Location authorization failed"
            case .unavailableLocation:
                return "Unable to fetch current location"
            }
        }
    }

    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var locationError: Error?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Error>?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func fetchCurrentLocation() async throws -> CLLocation {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        case .notDetermined:
            let status = try await requestAuthorizationIfNeeded()
            guard status == .authorizedWhenInUse || status == .authorizedAlways else {
                throw LocationServiceError.authorizationFailed
            }
        case .denied:
            throw LocationServiceError.permissionDenied
        case .restricted:
            throw LocationServiceError.permissionRestricted
        @unknown default:
            throw LocationServiceError.authorizationFailed
        }

        if let currentLocation {
            return currentLocation
        }

        return try await withThrowingTaskGroup(of: CLLocation.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    self.locationContinuation = continuation
                    self.manager.requestLocation()
                }
            }
            group.addTask {
                try await Task.sleep(for: .seconds(10))
                throw LocationServiceError.unavailableLocation
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    func resolveLocality(for location: CLLocation) async throws -> String? {
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        let placemark = placemarks.first
        return placemark?.locality ?? placemark?.subLocality ?? placemark?.administrativeArea
    }

    private func requestAuthorizationIfNeeded() async throws -> CLAuthorizationStatus {
        if manager.authorizationStatus != .notDetermined {
            return manager.authorizationStatus
        }

        return try await withCheckedThrowingContinuation { continuation in
            authorizationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        if let location = locations.last {
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus != .notDetermined {
            authorizationContinuation?.resume(returning: manager.authorizationStatus)
            authorizationContinuation = nil
        }
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}
