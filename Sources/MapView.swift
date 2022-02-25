//
//  MapView.swift
//  EsriTest
//
//  Created by Garett Breen on 2/24/22.
//

import ArcGIS
import Combine
import SwiftUI

public struct MapView: View {
    @ObservedObject var viewModel: MapViewModel
    
    public init(viewModel: MapViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        _MapView(viewModel: viewModel)
    }
}

open class MapViewModel: ObservableObject {
    var subscriptions = Set<AnyCancellable>()
    @Published public var map: AGSMap
    @Published public var graphicsOverlays: [AGSGraphicsOverlay]
    @Published public var isAttributionTextVisible = true
    
    public init(map: AGSMap = AGSMap(basemap: .openStreetMap()), graphicsOverlays: [AGSGraphicsOverlay] = []) {
        self.map = map
        self.graphicsOverlays = graphicsOverlays
    }
    
    open func pointTapped(screenPoint: CGPoint, mapPoint: AGSPoint) {
        
    }
}

struct _MapView: UIViewRepresentable {
    let viewModel: MapViewModel
    let mapView = AGSMapView()
    
    init(viewModel: MapViewModel) {
        self.viewModel = viewModel
    }
    
    func makeUIView(context: Context) -> AGSMapView {
        mapView.touchDelegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: AGSMapView, context: Context) {}
    
    func makeCoordinator() -> MapViewCoordinator {
        MapViewCoordinator(self)
    }
}

open class MapViewCoordinator: NSObject {
    var subscriptions = Set<AnyCancellable>()
    let parent: _MapView
    
    init(_ parent: _MapView) {
        self.parent = parent
        
        
        parent.viewModel.$map
            .sink { map in
                if parent.mapView.map != map {
                    parent.mapView.map = map
                }
            }
            .store(in: &subscriptions)
        
        parent.viewModel.$graphicsOverlays
            .sink { graphicsOverlays in
                let toAdd = graphicsOverlays.filter { !parent.mapView.graphicsOverlays.contains($0) }
                parent.mapView.graphicsOverlays.addObjects(from: toAdd)
                
                let toRemove = parent.mapView.graphicsOverlays.filter { !graphicsOverlays.contains($0 as! AGSGraphicsOverlay) }
                parent.mapView.graphicsOverlays.removeObjects(in: toRemove)
            }
            .store(in: &subscriptions)
        
        parent.viewModel.$isAttributionTextVisible
            .sink {
                parent.mapView.isAttributionTextVisible = $0
            }
            .store(in: &subscriptions)
    }
}

extension MapViewCoordinator: AGSGeoViewTouchDelegate {
    open func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        parent.viewModel.pointTapped(screenPoint: screenPoint, mapPoint: mapPoint)
    }
}

struct MapView_Previews: PreviewProvider {
    static var layer: AGSLayer {
        AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Elevation/WorldElevations/MapServer")!)
    }
    
    static var previews: some View {
        let viewModel = MapViewModel()
        return MapView(viewModel: viewModel)
    }
}
