//
//  MapViewModel.swift
//  mapbox-navigation
//
//  Created by Eric Ampire (Admin) on 2024-10-07.
//

import SwiftUI
import MapboxMaps
import CoreLocation
import Combine


class MapViewModel: ObservableObject {
    @Published var startAddress: String = ""
    @Published var endAddress: String = ""
    @Published var errorMessage: String = ""
    @Published var routeSteps: [Step] = []

    private var cancellables = Set<AnyCancellable>()

    func calculateRoute() {
        Task {
            do {
                let (startCoordinates, endCoordinates) = try await LocationManager.shared.geocodeAddresses(
                    startAddress: startAddress,
                    endAddress: endAddress
                )
                requestRoute(from: startCoordinates, to: endCoordinates)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func requestRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) {
        let urlString = "https://api.mapbox.com/directions/v5/mapbox/walking/\(start.longitude),\(start.latitude);\(end.longitude),\(end.latitude)?geometries=geojson&steps=true&access_token=\(accessToken)"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: RouteResponse.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error fetching route: \(error)")
                }
            }, receiveValue: { [weak self] response in
                if let steps = response.routes.first?.legs.first?.steps {
                    DispatchQueue.main.async {
                        self?.routeSteps = steps
                    }
                }
            })
            .store(in: &cancellables)
    }
}
