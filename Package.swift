// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EsriSwiftUI",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "EsriSwiftUI",
            targets: ["EsriSwiftUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Esri/arcgis-runtime-ios.git", from: "100.10.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "EsriSwiftUI",
            dependencies: [.product(name: "ArcGIS", package: "arcgis-runtime-ios")],
            path: "Sources"),
        .testTarget(
            name: "EsriSwiftUITests",
            dependencies: ["EsriSwiftUI"]),
    ]
)
