//
//  LocationResult.swift
//  mapbox-navigation
//
//  Created by Eric Ampire (Admin) on 2024-10-07.
//
import CoreLocation

extension CLPlacemark {
    func formattedAddress() -> String {
        var addressComponents: [String] = []

        if let name = self.name {
            addressComponents.append(name)
        }
        if let locality = self.locality {
            addressComponents.append(locality)
        }
        if let administrativeArea = self.administrativeArea {
            addressComponents.append(administrativeArea)
        }
        if let postalCode = self.postalCode, !postalCode.isEmpty {
            addressComponents.append(postalCode)
        }
        if let country = self.country {
            addressComponents.append(country)
        }

        return addressComponents.joined(separator: ", ")
    }
}
