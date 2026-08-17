// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ToastKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "ToastKit", targets: ["ToastKit"]),
    ],
    targets: [
        .target(name: "ToastKit"),
        .testTarget(
            name: "ToastKitTests",
            dependencies: ["ToastKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
