// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SuperWardrobe",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SuperWardrobe",
            targets: ["SuperWardrobe"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "SuperWardrobe",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Kingfisher", package: "Kingfisher"),
            ],
            path: "SuperWardrobe"
        )
    ]
)
