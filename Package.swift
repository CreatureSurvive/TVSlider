// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TVSlider",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "TVSlider", targets: ["TVSlider"]),
    ],
    targets: [
        .target(
            name: "TVSlider",
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        ),
        .testTarget(
            name: "TVSliderTests",
            dependencies: ["TVSlider"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
