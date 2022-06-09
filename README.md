# EsriSwiftUI
This is a simple library that allows for using esri maps in a SwiftUI way

## Example Usage

```
import ArcGIS
import Combine
import EsriSwiftUI
import SwiftUI

struct MainView: View {
    @StateObject var viewModel = SpecificMapViewModel()
    
    var body: some View {
        ZStack {
            MapView(viewModel: viewModel)
                .ignoresSafeArea(.all, edges: .all)
            VStack {
                Spacer()
                HStack {
                    if viewModel.map.operationalLayers.count != 0 {
                        layerList
                    }
                    Spacer()
                    Button(viewModel.map == viewModel.streetsMap ? "Change to Default" : "Change to Streets") {
                        viewModel.switchMap()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Map Test")
    }
    
    var layerList: some View {
        VStack {
            ForEach(viewModel.map.operationalLayers.map { $0 as! AGSLayer }, id: \.layerID) { layer in
                Button {
                    viewModel.objectWillChange.send()
                    layer.isVisible.toggle()
                } label: {
                    HStack {
                        Text(layer.name)
                            .font(.caption)
                        Spacer()
                        if layer.isVisible {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color.green)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

class SpecificMapViewModel: MapViewModel {
    var subscriptions = Set<AnyCancellable>()
    var defaultMap: AGSMap = {
        let map = AGSMap(basemap: .openStreetMap())
        map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -13154566.806155, y: 4050863.808144, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 1677358.50)

        return map
    }()
    
    var streetsMap: AGSMap = {
        let map = AGSMap(basemap: AGSBasemap.oceans())
        map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -13154566.806155, y: 4050863.808144, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 1677358.50)

        return map
    }()
    
    let graphicsOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        overlay.renderer = AGSSimpleRenderer(
            symbol: AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 10)
        )
        return overlay
    }()
    
    init() {
        let map = defaultMap
        
        super.init(map: map, graphicsOverlays: [graphicsOverlay])
        
        isAttributionTextVisible = false
    }
    
    func switchMap() {
        if map == streetsMap {
            map = defaultMap
        } else {
            map = streetsMap
        }
    }
    
    override func pointTapped(screenPoint: CGPoint, mapPoint: AGSPoint) {
        let graphic = AGSGraphic(geometry: mapPoint, symbol: nil)
        graphicsOverlay.graphics.add(graphic)
    }
}
```