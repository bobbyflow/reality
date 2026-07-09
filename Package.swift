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
      url: "https://github.com/groue/GRDB.swift.git",
      exact: "7.11.1"
    ),
    .package(
      url: "https://github.com/swiftlang/swift-testing.git",
      revision: "swift-6.2.4-RELEASE"
    ),
  ],
  targets: [
    .executableTarget(
      name: "Reality",
      dependencies: [
        .product(name: "GRDB", package: "GRDB.swift")
      ],
      path: "Sources/Reality"
    ),
    .testTarget(
      name: "RealityTests",
      dependencies: [
        "Reality",
        .product(name: "GRDB", package: "GRDB.swift"),
        .product(name: "Testing", package: "swift-testing"),
      ],
      path: "Tests/RealityTests"
    ),
  ]
)
