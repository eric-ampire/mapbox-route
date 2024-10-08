//
//  RouteResponse.swift
//  mapbox-navigation
//
//  Created by Eric Ampire (Admin) on 2024-10-07.
//

import UIKit
import CoreLocation
import Combine


struct RouteResponse: Codable {
    let routes: [Route]
}

struct Route: Codable {
    let legs: [Leg]
}

struct Leg: Codable {
    let steps: [Step]
}

struct Step: Codable, Hashable {
    let geometry: Geometry?
    let maneuver: Maneuver
    
    static func == (lhs: Step, rhs: Step) -> Bool {
        return lhs.maneuver == rhs.maneuver && lhs.geometry == rhs.geometry
    }
}

struct Maneuver: Codable, Hashable {
    let location: [Double] // [longitude, latitude]
    let instruction: String
}

struct Geometry: Codable, Hashable {
    let coordinates: [[Double]]

    var decodedCoordinates: [CLLocationCoordinate2D] {
        return coordinates.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
    }
}
