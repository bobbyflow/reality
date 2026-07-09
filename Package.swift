// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "Reality",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "Reality", targets: ["Reality"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/swiftlang/swift-testing.git",
      revision: "swift-6.2.4-RELEASE"
    )
  ],
  targets: [
    .executableTarget(
      name: "Reality",
      path: "Sources/Reality"
    ),
    .testTarget(
      name: "RealityTests",
      dependencies: [
        "Reality",
        .product(name: "Testing", package: "swift-testing"),
      ],
      path: "Tests/RealityTests"
    ),
  ]
)
