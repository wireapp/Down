// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Down",
    platforms: [
        .iOS("15.0"),
        .macOS("15.0"),
    ],
    products: [
        .library(
            name: "Down",
            targets: ["Down"]
        )
    ],
    targets: [
        .target(
            name: "libcmark",
            dependencies: [],
            path: "libcmark",
            exclude: [
              "include",
            ],
            publicHeadersPath: "./"
        ),
        .target(
            name: "Down",
            dependencies: ["libcmark"],
            path: "Source",
            exclude: ["Down.h"],
          resources: [
            .copy("../Resources/DownView.bundle"),
          ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
