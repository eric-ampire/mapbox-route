//
//  LocationManager.swift
//  mapbox-navigation
//
//  Created by Eric Ampire (Admin) on 2024-10-07.
//

import CoreLocation
import Combine

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    static let shared = LocationManager()
    
    private let geocoder = CLGeocoder()
    private let locationManager = CLLocationManager()
    @Published var lastKnownLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        lastKnownLocation = newLocation
    }

    func geocodeAddresses(startAddress: String, endAddress: String) async throws -> (CLLocationCoordinate2D, CLLocationCoordinate2D) {
        let startCoordinates = try await geocodeAddress(startAddress)
        let endCoordinates = try await geocodeAddress(endAddress)
        return (startCoordinates, endCoordinates)
    }

    // Helper method to geocode a single address asynchronously
    private func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error) // Resume on error
                } else if let location = placemarks?.first?.location {
                    continuation.resume(returning: location.coordinate) // Resume on success
                } else {
                    let unknownError = NSError(domain: "GeocodingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No location found for address"])
                    continuation.resume(throwing: unknownError) // Resume if no location is found
                }
            }
        }
    }
}


