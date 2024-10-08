//
//  CustomMapView.swift
//  mapbox-navigation
//
//  Created by Eric Ampire (Admin) on 2024-10-07.
//

import SwiftUI
import MapboxMaps
import CoreLocation
import Combine


struct CustomMapView: UIViewRepresentable {
    var routeSteps: [Step] = []
    
    private let locationProvider = AppleLocationProvider()
    @ObservedObject var locationManager = LocationManager.shared
    
    func makeUIView(context: Context) -> MapView {
        let mapView = MapView(frame: .zero)
        mapView.mapboxMap.loadStyle(.streets)
        mapView.location.override(provider: locationProvider)
        mapView.location.options.puckType = .puck2D()
        mapView.location.options.puckBearingEnabled = true
        return mapView
    }
    
    fileprivate func setDefaultCameraPosition(_ currentRouteStepsSet: Set<Step>, _ uiView: MapView) {
        if let latestLocation = locationManager.lastKnownLocation?.coordinate, currentRouteStepsSet.isEmpty {
            let cameraOptions = CameraOptions(center: latestLocation, zoom: 15)
            uiView.camera.ease(to: cameraOptions, duration: 1)
        }
    }
    
    func updateUIView(_ uiView: MapView, context: Context) {
        let currentRouteStepsSet = Set(routeSteps)
        let previousRouteStepsSet = Set(context.coordinator.routeSteps)
        if currentRouteStepsSet != previousRouteStepsSet {
            if routeSteps.isEmpty { return }
            addSteps(to: uiView)
            addManeuverPins(to: uiView)
            context.coordinator.routeSteps = routeSteps
        }
        setDefaultCameraPosition(currentRouteStepsSet, uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(routeSteps: routeSteps)
    }

    class Coordinator {
        var routeSteps: [Step]
        var lastCameraLocation: CLLocationCoordinate2D? = nil
        init(routeSteps: [Step]) {
            self.routeSteps = routeSteps
        }
    }
    
    private func addManeuverPins(to mapView: MapView) {
        let annotationsManager = mapView.annotations.makePointAnnotationManager(id: "maneuver-id")
        let coordinatesAndAnnotations = routeSteps.compactMap { step -> (CLLocationCoordinate2D, PointAnnotation)? in
            let maneuverLocation = step.maneuver.location
            guard maneuverLocation.count == 2 else {
                return nil
            }

            let coordinate = CLLocationCoordinate2D(latitude: maneuverLocation[1], longitude: maneuverLocation[0])
            
            // Create PointAnnotation
            var pointAnnotation = PointAnnotation(coordinate: coordinate)
            pointAnnotation.image = .init(image: UIImage.point, name: "Point")
            pointAnnotation.iconSize = 0.15
            pointAnnotation.textField = step.maneuver.instruction
            pointAnnotation.iconAnchor = .bottom
            pointAnnotation.textAnchor = .top
            pointAnnotation.textSize = 12
            pointAnnotation.textColor = StyleColor(.blue)
            pointAnnotation.textTransform = .uppercase

            return (coordinate, pointAnnotation)
        }
        
        let coordinates = coordinatesAndAnnotations.map { $0.0 }
        let annotations = coordinatesAndAnnotations.map { $0.1 }
        
        annotationsManager.annotations = annotations

        if let firstCoordinate = coordinates.first, let lastCoordinate = coordinates.last {
            adjustCamera(to: mapView, from: firstCoordinate, to: lastCoordinate)
        }
    }

    private func adjustCamera(to mapView: MapView, from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) {
        let referenceCamera = CameraOptions(zoom: 15)
        let camera = try? mapView.mapboxMap.camera(
            for: [start, end],
            camera: referenceCamera,
            coordinatesPadding: .zero,
            maxZoom: nil,
            offset: nil
        )
        if let camera = camera {
            mapView.camera.ease(to: camera, duration: 1)
        }
    }
    
    fileprivate func removeExistingData(_ mapView: MapView) {
        // Remove existing layers (if any)
        mapView.mapboxMap.allLayerIdentifiers.forEach { layer in
            if layer.id.hasPrefix("step-layer-") {
                try? mapView.mapboxMap.removeLayer(withId: layer.id)
            }
        }
        mapView.mapboxMap.allSourceIdentifiers.forEach { source in
            if source.id.hasPrefix("step-source-") {
                try? mapView.mapboxMap.removeSource(withId: source.id)
            }
        }
    }
    
    private func addSteps(to mapView: MapView) {
        removeExistingData(mapView)
        let colors: [UIColor] = [.blue, .green, .red, .yellow, .purple]
        
        for (index, step) in routeSteps.enumerated() {
            guard let stepCoords = step.geometry?.decodedCoordinates else { continue }
            
            let lineString = LineString(stepCoords)
            let feature = Feature(geometry: .lineString(lineString))
            
            let sourceId = "step-source-\(index)"
            var source = GeoJSONSource(id: sourceId)
            source.data = .feature(feature)
            try? mapView.mapboxMap.addSource(source)
            
            var layer = LineLayer(id: "step-layer-\(index)", source: sourceId)
            layer.lineColor = .constant(StyleColor(colors[index % colors.count]))
            layer.lineWidth = .constant(5.0)
            try? mapView.mapboxMap.addLayer(layer)
        }
    }
}
