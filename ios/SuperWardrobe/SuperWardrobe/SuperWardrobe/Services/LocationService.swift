import Foundation
import CoreLocation

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    enum LocationError: LocalizedError {
        case permissionDenied
        case timeout
        case underlying(Error)

        var errorDescription: String? {
            switch self {
            case .permissionDenied: return "Location permission denied"
            case .timeout: return "Location request timed out"
            case .underlying(let e): return e.localizedDescription
            }
        }
    }

    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var locationError: Error?

    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

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

    /// Fetches the current location, waiting up to `timeout` seconds.
    /// Falls back to the last known location if the fresh request times out.
    func fetchCurrentLocation(timeout: TimeInterval = 10) async throws -> CLLocation {
        // If we already have a recent location, return it immediately.
        if let cached = currentLocation {
            return cached
        }

        #if os(iOS)
        let denied = authorizationStatus == .denied || authorizationStatus == .restricted
        #else
        let denied = authorizationStatus == .denied || authorizationStatus == .restricted
        #endif
        if denied {
            throw LocationError.permissionDenied
        }

        return try await withThrowingTaskGroup(of: CLLocation.self) { group in
            // Location fetch task
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    self.locationContinuation = continuation
                    self.manager.requestLocation()
                }
            }

            // Timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw LocationError.timeout
            }

            // Return whichever finishes first; cancel the other.
            do {
                let result = try await group.next()!
                group.cancelAll()
                return result
            } catch {
                group.cancelAll()
                // If the timeout fired but we got a location via the delegate meanwhile, use it.
                if let cached = self.currentLocation {
                    return cached
                }
                throw error
            }
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
        locationContinuation?.resume(throwing: LocationError.underlying(error))
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        let isAuthorized: Bool
        #if os(iOS)
        isAuthorized = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
        #else
        isAuthorized = authorizationStatus == .authorized || authorizationStatus == .authorizedAlways
        #endif
        if isAuthorized {
            manager.requestLocation()
        }
    }
}
