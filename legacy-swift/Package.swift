// swift-tools-version: 5.9
// Historical prototype only. The supported product is ../tauri-app.
// Keeping this manifest isolated prevents the root scripts from producing a
// second screenshot application by accident.
import PackageDescription

let package = Package(
    name: "ShotserLegacy",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "ShotserLegacy", targets: ["ShotserLegacy"])],
    targets: [
        .executableTarget(name: "ShotserLegacy", path: "Sources/Shotser"),
    ]
)
