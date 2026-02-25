// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SickMotion",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "SickMotionShared", targets: ["SickMotionShared"]),
        .executable(name: "sickmotion-menubar", targets: ["SickMotionMenuBarApp"]),
        .executable(name: "sickmotionctl", targets: ["SickMotionCLI"]),
    ],
    targets: [
        .target(
            name: "SickMotionShared"
        ),
        .executableTarget(
            name: "SickMotionMenuBarApp",
            dependencies: ["SickMotionShared"]
        ),
        .executableTarget(
            name: "SickMotionCLI",
            dependencies: ["SickMotionShared"]
        ),
    ]
)
