//
//  File.swift
//  
//
//  Created by Garett Breen on 4/1/22.
//

import ArcGIS
import Combine
import SwiftUI

public enum ZoomType {
    case geometry(geometry: GeometryZoom)
    case point(point: PointZoom)
    case viewpoint(viewpoint: AGSViewpoint)
    case currentLocation
}

open class MapViewModel: ObservableObject {
    var subscriptions = Set<AnyCancellable>()
    @Published public var map: AGSMap
    @Published public var graphicsOverlays: [AGSGraphicsOverlay]
    @Published public var isAttributionTextVisible: Bool
    @Published public var errorGettingLocation = false
    
    public let zoom = PassthroughSubject<ZoomType, Never>()
    public let graphicsOverlayIdentify = PassthroughSubject<GraphicsOverlayIdentifyRequest, Never>()
    public let currentScreenPolygon = CurrentValueSubject<AGSPolygon?, Never>(nil)
    
    public init(map: AGSMap = AGSMap(basemap: .openStreetMap()), graphicsOverlays: [AGSGraphicsOverlay] = [], isAttributionTextVisible: Bool = true) {
        self.map = map
        self.graphicsOverlays = graphicsOverlays
        self.isAttributionTextVisible = isAttributionTextVisible
    }
    
    open func pointTapped(screenPoint: CGPoint, mapPoint: AGSPoint) {
        
    }
    
    open func currentLocationReceived(location: AGSLocation?) {
        
    }
}
