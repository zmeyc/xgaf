import PackageDescription

let package = Package(
    name: "xgaf",
    dependencies: [
        .Package(url: "https://github.com/smud/Utils.git", majorVersion: 0),
    ]
)
