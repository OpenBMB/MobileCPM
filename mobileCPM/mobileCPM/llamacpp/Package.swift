// swift-tools-version:5.5

import PackageDescription

var sources = [
    "ggml.c",
    "sgemm.cpp",
    "llama.cpp",
    "unicode.cpp",
    "unicode-data.cpp",
    "ggml-alloc.c",
    "ggml-backend.c",
    "ggml-quants.c",
]

var resources: [Resource] = []
var linkerSettings: [LinkerSetting] = []
var cSettings: [CSetting] =  [
    .unsafeFlags(["-Wno-shorten-64-to-32", "-O3", "-DNDEBUG"]),
    .unsafeFlags(["-fno-objc-arc"]),
    // NOTE: NEW_LAPACK will required iOS version 16.4+
    // We should consider add this in the future when we drop support for iOS 14
    // (ref: ref: https://developer.apple.com/documentation/accelerate/1513264-cblas_sgemm?language=objc)
    // .define("ACCELERATE_NEW_LAPACK"),
    // .define("ACCELERATE_LAPACK_ILP64")
]

#if canImport(Darwin)
sources.append("ggml-metal.m")
resources.append(.process("ggml-metal.metal"))
linkerSettings.append(.linkedFramework("Accelerate"))

// @salex added
linkerSettings.append(.linkedFramework("Metal"))
linkerSettings.append(.linkedFramework("MetalKit"))
linkerSettings.append(.linkedFramework("MetalPerformanceShaders"))

cSettings.append(
    contentsOf: [
        .define("GGML_USE_ACCELERATE"),
        .define("GGML_USE_METAL"),

        // @salex added
        .define("ACCELERATE_NEW_LAPACK"),
        .define("ACCELERATE_LAPACK_ILP64"),
        .define("NDEBUG"),
        .unsafeFlags(["-pthread"]),
        .unsafeFlags(["-fno-objc-arc"]),
        .unsafeFlags(["-Wno-shorten-64-to-32"]),
        .unsafeFlags(["-w"]),
    ]
)
#endif

#if os(Linux)
    cSettings.append(.define("_GNU_SOURCE"))
#endif

let package = Package(
    name: "llama_package",
    platforms: [
        .macOS(.v12),
        .iOS(.v14),
        .watchOS(.v4),
        .tvOS(.v14)
    ],
    products: [
        .library(name: "llamalib", targets: ["llama"]),
        .library(name: "commonlib", targets: ["common"]),
        .library(name: "testlib", targets: ["xcodetest"]),
        .library(name: "minicpmlib", targets: ["minicpmv"]),
        .library(name: "minicpmv_wrapper_lib", targets: ["minicpmv_wrapper"])
    ],
    targets: [
        .target(
            name: "llama",
            path: ".",
            exclude: [
               "cmake",
               "examples",
               "scripts",
               "tests",
               "CMakeLists.txt",
               "ggml-cuda.cu",
               "ggml-cuda.h",
               "Makefile"
            ],
            sources: sources,
            resources: resources,
            publicHeadersPath: "spm-headers",
            cSettings: cSettings,
            linkerSettings: linkerSettings
        ),
        .target(
            name: "xcodetest",
            path: "testxcode",
            sources: ["testxcode.mm"],
            resources: [],
            publicHeadersPath: "spm_test",
            cSettings: cSettings,
            linkerSettings: []
        ),
        .target(
            name: "common",
            dependencies: [.target(name: "llama")],
            path: "common",
            sources: ["common.cpp",
                      "build-info.cpp",
                      "sampling.cpp",
                      "base64.hpp",
                      "console.cpp",
                      "grammar-parser.cpp",
                      "json-schema-to-grammar.cpp",
                      "train.cpp",
                      "ngram-cache.cpp"],
            resources: [],
            publicHeadersPath: "spm",
            cSettings: cSettings,
            linkerSettings: linkerSettings
        ),
        .target(name: "minicpmv",
                dependencies: [.target(name: "llama"), .target(name: "common")],
                path: "examples/minicpmv",
                exclude: ["minicpmv_wrapper.cpp", "minicpmv_wrapper.h"],
                sources: ["minicpmv.cpp",
                          "clip.cpp"],
                resources: [],
                publicHeadersPath: "spm",
                cSettings: cSettings,
                linkerSettings: linkerSettings
               ),
        .target(name: "minicpmv_wrapper",
                dependencies: [.target(name: "llama"), .target(name: "common"), .target(name: "minicpmv")],
                path: "examples/minicpmv",
                exclude: ["minicpmv.cpp",
                          "clip.cpp"],
                sources: [
                         "minicpmv_wrapper.cpp"],
                resources: [],
                publicHeadersPath: "spm_mini",
                cSettings: cSettings,
                linkerSettings: linkerSettings
               )
    ],
    cxxLanguageStandard: .cxx11
)
