// swift-tools-version:6.2
import PackageDescription

let package = Package(
  name: "FederalRegisterOfflineDemo",
  platforms: [.macOS(.v26)],
  dependencies: [
    .package(name: "swift-federal-register", path: "../.."),
    .package(url: "https://github.com/KalebCooper/swifty-networking.git", from: "1.3.1"),
  ],
  targets: [
    .executableTarget(
      name: "FederalRegisterOfflineDemo",
      dependencies: [
        .product(name: "HTTPTesting", package: "swifty-networking"),
        .product(name: "SwiftFederalRegisterDocuments", package: "swift-federal-register"),
        .product(name: "SwiftFederalRegisterDocumentsModels", package: "swift-federal-register"),
      ],
      swiftSettings: [
        .defaultIsolation(nil),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .strictMemorySafety(),
      ]
    )
  ],
  swiftLanguageModes: [.v6]
)
