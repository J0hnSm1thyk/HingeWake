// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HingeWake",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "HingeWakeCore", targets: ["HingeWakeCore"]),
        .executable(name: "HingeWake", targets: ["HingeWake"])
    ],
    targets: [
        .target(name: "HingeWakeCore"),
        .target(
            name: "HingeWakeAuthorization",
            path: "Sources/HingeWakeAuthorization",
            publicHeadersPath: "include",
            linkerSettings: [.linkedFramework("Security")]
        ),
        .executableTarget(
            name: "HingeWake",
            dependencies: ["HingeWakeCore", "HingeWakeAuthorization"]
        )
    ]
)
