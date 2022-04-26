//
//  MapView.swift
//  EsriTest
//
//  Created by Garett Breen on 2/24/22.
//

import ArcGIS
import Combine
import SwiftUI

public extension AGSLocationDisplay {
    func start() -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            self.start { err in
                guard err == nil else {
                    promise(.failure(err!))
                    return
                }
                
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
}

public struct GeometryZoom {
    public let geometry: AGSGeometry
    public let padding: Double
    public let completion: ((Bool) -> Void)?
    
    public init(geometry: AGSGeometry, padding: Double, completion: ((Bool) -> Void)? = nil) {
        self.geometry = geometry
        self.padding = padding
        self.completion = completion
    }
}

public struct GraphicsOverlayIdentifyRequest {
    public let graphicsOverlay: AGSGraphicsOverlay
    public let screenPoint: CGPoint
    public let tolerance: Double
    public let returnPopupsOnly: Bool
    public let maximumResults: Int?
    public let completion: (AGSIdentifyGraphicsOverlayResult) -> Void
    
    public init(graphicsOverlay: AGSGraphicsOverlay, screenPoint: CGPoint, tolerance: Double, returnsPopupsOnly: Bool, maximumResults: Int?, completion: @escaping (AGSIdentifyGraphicsOverlayResult) -> Void) {
        self.graphicsOverlay = graphicsOverlay
        self.screenPoint = screenPoint
        self.tolerance = tolerance
        self.returnPopupsOnly = returnsPopupsOnly
        self.maximumResults = maximumResults
        self.completion = completion
    }
}

public struct MapView: View {
    @ObservedObject var viewModel: MapViewModel
    
    public init(viewModel: MapViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        _MapView(viewModel: viewModel)
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
        
        parent.mapView
            .publisher(for: \.visibleArea)
            .compactMap { $0 }
            .assign(to: \.viewModel.currentScreenPolygon.value, on: parent)
            .store(in: &subscriptions)
        
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
        
        super.init()
        
        parent.viewModel.zoom
            .sink { [unowned self] type in
                switch type {
                case .currentLocation:
                    self.tryZoomToCurrentLocation()
                case .geometry(let geo):
                    self.parent.mapView.setViewpointGeometry(geo.geometry, padding: geo.padding, completion: geo.completion)
                case .viewpoint(let viewpoint):
                    self.parent.mapView.setViewpoint(viewpoint)
                }
            }
            .store(in: &subscriptions)
        
        parent.viewModel.graphicsOverlayIdentify
            .sink { [unowned self] in
                self.identify($0)
            }
            .store(in: &subscriptions)
    }
    
    open func tryZoomToCurrentLocation() {
        guard !parent.mapView.locationDisplay.started else {
            self.zoomToCurrentLocation()
            return
        }

        parent.mapView.locationDisplay.start()
            .flatMap({ [unowned self] () -> AnyPublisher<AGSLocation?, Never> in
                self.parent.mapView.locationDisplay.publisher(for: \.location).eraseToAnyPublisher()
            })
            .drop(while: {
                guard let point = $0 else {
                    return true
                }
                
                return point.lastKnown
            })
            .first()
            .sink { [unowned self] completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    self.parent.viewModel.errorGettingLocation = true
                }
            } receiveValue: { [unowned self] location in
                self.zoomToCurrentLocation()
            }
            .store(in: &self.subscriptions)
    }
    
    open func zoomToCurrentLocation() {
        self.parent.viewModel.currentLocationReceived(location: self.parent.mapView.locationDisplay.location)
    }
    
    func identify(_ request: GraphicsOverlayIdentifyRequest) {
        guard let maximumResults = request.maximumResults else {
            parent.mapView.identify(request.graphicsOverlay, screenPoint: request.screenPoint, tolerance: request.tolerance, returnPopupsOnly: request.returnPopupsOnly, completion: request.completion)
            return
        }
        
        parent.mapView.identify(request.graphicsOverlay, screenPoint: request.screenPoint, tolerance: request.tolerance, returnPopupsOnly: request.returnPopupsOnly, maximumResults: maximumResults, completion: request.completion)
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
