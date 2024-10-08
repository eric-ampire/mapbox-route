//
//  ContentView.swift
//  mapbox-navigation
//
//  Created by Eric Ampire (Admin) on 2024-10-07.
//

import SwiftUI
import MapboxMaps

struct ItineraryView: View {
    
    @StateObject private var viewModel = MapViewModel()
    @FocusState private var sourceIsFocused: Bool
    @FocusState private var destinationIsFocused: Bool

    var body: some View {
        VStack {
            TextField("Start Address", text: $viewModel.startAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($sourceIsFocused)
                .padding()

            TextField("Destination Address", text: $viewModel.endAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($destinationIsFocused)
                .padding()
            searchButton()

            CustomMapView(
                routeSteps: viewModel.routeSteps
            ).edgesIgnoringSafeArea(.all)
        }.preferredColorScheme(.light)
    }
    
    func searchButton() -> some View {
        VStack(alignment: .center) {
            Button(
                action: {
                    viewModel.calculateRoute()
                    sourceIsFocused = false
                    destinationIsFocused = false
                },
                label: {
                    Text("Get direction").padding()
                }
            )
            .buttonBorderShape(.capsule)
        }.background(.white)
    }
}

#Preview {
    ItineraryView()
}
