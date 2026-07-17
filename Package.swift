// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "StickyNotes",
    platforms: [
        .macOS(.v26)
    ],
    targets: [
        .executableTarget(
            name: "StickyNotes",
            path: "Sources/StickyNotes",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
