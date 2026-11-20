// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "GymCore",
  defaultLocalization: "en",
  platforms: [.iOS(.v26), .macOS(.v26)],
  products: [
    .library(name: "GymCore", targets: ["GymCore"]),
    .library(name: "GymData", targets: ["GymData"]),
  ],
  dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.55.0"),
  ],
  targets: [
    // Entities, week math, load units, dashboard stats and workout building. No I/O.
    .target(name: "GymCore"),
    // Supabase repository, offline JSON cache and the one-time legacy upload.
    .target(
      name: "GymData",
      dependencies: [
        "GymCore",
        .product(name: "Supabase", package: "supabase-swift"),
      ]
    ),
    .testTarget(name: "GymCoreTests", dependencies: ["GymCore"]),
    .testTarget(name: "GymDataTests", dependencies: ["GymData"]),
  ]
)
