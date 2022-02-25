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
    @Published public var layers: [AGSLayer] = []
    @Published public var map: AGSMap
    
    public init(map: AGSMap = AGSMap(basemap: .openStreetMap())) {
        self.map = map
    }
}

struct _MapView: UIViewRepresentable {
    let viewModel: MapViewModel
    let mapView = AGSMapView()
    
    init(viewModel: MapViewModel) {
        self.viewModel = viewModel
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.addSubview(mapView)
        
        mapView.contentMode = .scaleAspectFit
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.isAttributionTextVisible = false
        
        NSLayoutConstraint.activate([
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor),
            mapView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> MapViewCoordinator {
        MapViewCoordinator(self)
    }
}

class MapViewCoordinator {
    var subscriptions = Set<AnyCancellable>()
    let parent: _MapView
    
    init(_ parent: _MapView) {
        self.parent = parent
        
        parent.viewModel.$map
            .combineLatest(parent.viewModel.$layers)
            .sink { (map, layers) in
                parent.mapView.map = map
                print(layers.count)
                
                map.operationalLayers.removeAllObjects()
                map.operationalLayers.addObjects(from: layers)
            }
            .store(in: &subscriptions)
        
        parent.mapView.viewpointChangedHandler = {
            guard let viewPoint = parent.mapView.currentViewpoint(with: .centerAndScale) else {
                return
            }
            
            print(viewPoint)
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var layer: AGSLayer {
        AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Elevation/WorldElevations/MapServer")!)
    }
    
    static var previews: some View {
        let viewModel = MapViewModel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            viewModel.layers.append(layer)
        }
        
        return MapView(viewModel: viewModel)
    }
}
