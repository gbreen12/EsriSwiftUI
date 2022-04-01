//
//  File.swift
//  
//
//  Created by Garett Breen on 4/1/22.
//

import ArcGIS
import Combine
import SwiftUI

open class MapViewModel: ObservableObject {
    var subscriptions = Set<AnyCancellable>()
    @Published public var map: AGSMap
    @Published public var graphicsOverlays: [AGSGraphicsOverlay]
    @Published public var isAttributionTextVisible: Bool
    @Published public var errorGettingLocation = false
    
    public let zoomToGeometry = PassthroughSubject<GeometryZoom, Never>()
    public let zoomToViewpoint = PassthroughSubject<AGSViewpoint, Never>()
    public let zoomToCurrentLocation = PassthroughSubject<Void, Never>()
    public let graphicsOverlayIdentify = PassthroughSubject<GraphicsOverlayIdentifyRequest, Never>()
    
    public init(map: AGSMap = AGSMap(basemap: .openStreetMap()), graphicsOverlays: [AGSGraphicsOverlay] = [], isAttributionTextVisible: Bool = true) {
        self.map = map
        self.graphicsOverlays = graphicsOverlays
        self.isAttributionTextVisible = isAttributionTextVisible
    }
    
    open func pointTapped(screenPoint: CGPoint, mapPoint: AGSPoint) {
        
    }
}
