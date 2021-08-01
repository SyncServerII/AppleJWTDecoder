// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppleJWTDecoder",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AppleJWTDecoder",
            targets: ["AppleJWTDecoder"]),
    ],
    dependencies: [
        // I'm using my fork so I don't have conflicting versions.
        .package(name: "SwiftJWT", url: "https://github.com/IBM-Swift/Swift-JWT.git", from: "3.5.3"),
        
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", from: "1.8.1"),
        .package(name: "SwiftJWKtoPEM", url: "https://github.com/ibm-cloud-security/Swift-JWK-to-PEM.git", from: "0.4.0"),
        .package(name: "Kitura-net", url: "https://github.com/Kitura/Kitura-net.git", from: "2.4.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AppleJWTDecoder",
            dependencies: ["SwiftJWT", "HeliumLogger", "SwiftJWKtoPEM",
                .product(name: "KituraNet", package: "Kitura-net")
            ]),
        .testTarget(
            name: "AppleJWTDecoderTests",
            dependencies: ["AppleJWTDecoder"]),
    ]
)
