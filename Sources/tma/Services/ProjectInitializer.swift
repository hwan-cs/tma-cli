//
//  ProjectInitializer.swift
//  tma-cli
//
//  Created by Jung Hwan Park on 11/17/25.
//

import Foundation

struct ProjectInitializer {
    let fm = FileManager.default

    func createProject(named name: String) throws {
        let root = fm.currentDirectoryPath + "/\(name)"
        
        try createDirectory(root)
        try createManifestsStructure(root: root, projectName: name)

        print("✔️ Created TMA project: \(name)")
    }

    private func createDirectory(_ path: String) throws {
        try fm.createDirectory(atPath: path, withIntermediateDirectories: true)
    }
}

extension ProjectInitializer {
    func createManifestsStructure(root: String, projectName: String) throws {
        let appFolder = root + "/App"
        let tuistFolder = root + "/Tuist"
        let helpersFolder = tuistFolder + "/ProjectDescriptionHelpers"

        try createDirectory(appFolder)
        try createDirectory(tuistFolder)
        try createDirectory(helpersFolder)

        try writeToml(root)
        try writeAppProject(appFolder, projectName)
        try writeProjectHelpers(helpersFolder, projectName)
        try writePackageFile(tuistFolder)
        try writeTuistFile(root)
        try writeWorkspaceFile(root, projectName: projectName)
    }
}

extension ProjectInitializer {
    func writeToml(_ root: String) throws {
        let content = """
        [tools]
        tuist = "4.54.3"
        """
        try write(content, to: root + "/mise.toml")
    }
}

extension ProjectInitializer {
    func writeAppProject(_ folder: String, _ name: String) throws {
        let content = """
        import ProjectDescription
        import ProjectDescriptionHelpers

        let project = Project(
            name: "\(name)",
            targets: [
                .target(
                    name: "\(name)",
                    destinations: .iOS,
                    product: .app,
                    bundleId: "com.\(name.lowercased()).app",
                    infoPlist: .extendingDefault(
                        with: [
                            "CFBundleDisplayName": "\(name)",
                            "CFBundleShortVersionString": "1.0.0",
                            "CFBundleVersion": "1",
                            "UILaunchStoryboardName": "LaunchScreen"
                        ]
                    ),
                    sources: ["Sources/**"],
                    resources: ["Resources/**"],
                    dependencies: [
                    ],
                    settings: .settings(
                        base: SettingsDictionary(),
                        configurations: [],
                        defaultSettings: .recommended
                    )
                ),
                .target(
                    name: "\(name)Tests",
                    destinations: .iOS,
                    product: .unitTests,
                    bundleId: "com.\(name.lowercased()).app.tests",
                    infoPlist: .default,
                    sources: ["Tests/**"],
                    resources: [],
                    dependencies: [
                        .target(name: "\(name)")
                    ]
                ),
            ]
        )

        """
        try write(content, to: folder + "/Project.swift")
        try createDirectory(folder + "/Sources")
        try createDirectory(folder + "/Resources")
        try createDirectory(folder + "/Tests")
        
        let appSwift = """
        import SwiftUI

        @main
        struct \(name)App: App {
            var body: some Scene {
                WindowGroup {
                    Text("Hello, World!")
                }
            }
        }
        """
        try write(appSwift, to: folder + "/Sources/App.swift")
        
        let testCode = """
        import Foundation
        import XCTest

        final class TuistDemoTests: XCTestCase {TuistDemoTests
            func test_twoPlusTwo_isFour() {
                XCTAssertEqual(2+2, 4)
            }
        }
        """
        try write(testCode, to: folder + "/Tests/TuistDemoTests.swift")
    }
}

extension ProjectInitializer {
    func writeProjectHelpers(_ folder: String, _ name: String) throws {
        let content = """
        @preconcurrency import ProjectDescription

        public let bundleId = "com.\(name.lowercased()).app"

        extension Project {
            
            public static let destinations: ProjectDescription.Destinations = [.iPhone]
            
            public static let minDeploymentVersion: DeploymentTargets = .iOS("18.0")
            
            public static func resolvedProductType() -> ProjectDescription.Product {
                if Environment.isDynamic.getBoolean(default: false) {
                    return .framework
                } else {
                    return .staticFramework
                }
            }
            
            // MARK: - Project Factory for TMA
            public static func feature(
                name: String,
                bundleId: String,
                dependencies: [TargetDependency] = []
            ) -> Project {
                let targets = makeFeatureTargets(
                    name: name,
                    bundleId: bundleId,
                    dependencies: dependencies
                )
                
                return Project(
                    name: name,
                    targets: targets
                )
            }
            
            public static func core(
                name: String,
                bundleId: String,
                dependencies: [TargetDependency] = []
            ) -> Project {
                let targets = makeCoreTargets(
                    name: name,
                    bundleId: bundleId,
                    dependencies: dependencies
                )
                
                return Project(
                    name: name,
                    targets: targets
                )
            }
        }

        //MARK: - Target Factory
        func makeFeatureTargets(
            name: String,
            bundleId: String,
            dependencies: [TargetDependency]
        ) -> [Target] {
            
            let commonSettings = Settings.settings(
                configurations: [],
                defaultSettings: .recommended
            )
            
            let interfaceTarget = Target.target(
                name: "\\(name)Interface",
                destinations: Project.destinations,
                product: Project.resolvedProductType(),
                bundleId: "com.\(name.lowercased()).app.\\(name)Interface",
                deploymentTargets: Project.minDeploymentVersion,
                infoPlist: .default,
                sources: ["Interface/**"],
                dependencies: [] + dependencies,
                settings: commonSettings
            )
            
            let featureTarget = Target.target(
                name: name,
                destinations: Project.destinations,
                product: Project.resolvedProductType(),
                bundleId: "com.\(name.lowercased()).app.\\(name)",
                deploymentTargets: Project.minDeploymentVersion,
                infoPlist: .default,
                sources: ["Sources/**"],
                resources: ["Resources/**"],
                dependencies: [
                    .target(name: "\\(name)Interface")
                ] + dependencies,
                settings: commonSettings
            )
            
            let testingTarget = Target.target(
                name: "\\(name)Testing",
                destinations: Project.destinations,
                product: Project.resolvedProductType(),
                bundleId: "com.\(name.lowercased()).app.\\(name)Testing",
                deploymentTargets: Project.minDeploymentVersion,
                infoPlist: .default,
                sources: ["Testing/**"],
                dependencies: [
                    .target(name: "\\(name)Interface")
                ],
                settings: commonSettings
            )
            
            let testsTarget = Target.target(
                name: "\\(name)Tests",
                destinations: Project.destinations,
                product: .unitTests,
                bundleId: "com.\(name.lowercased()).app.\\(name)Tests",
                deploymentTargets: Project.minDeploymentVersion,
                infoPlist: .default,
                sources: ["Tests/**"],
                dependencies: [
                    .target(name: name),
                    .target(name: "\\(name)Testing"),
                    .xctest
                ],
                settings: commonSettings
            )
            
            let exampleTarget = Target.target(
                name: "\\(name)Example",
                destinations: Project.destinations,
                product: .app,
                bundleId: "com.\(name.lowercased()).app.\\(name).example",
                deploymentTargets: Project.minDeploymentVersion,
                infoPlist: .extendingDefault(with: [
                    "CFBundleDisplayName": "\\(name)",
                    "CFBundleShortVersionString": "1.0.0",
                    "CFBundleVersion": "1",
                    "UILaunchStoryboardName": "LaunchScreen",
                    "NSMicrophoneUsageDescription": "Allow microphone usage for Shazam"
                ]),
                sources: ["Example/**"],
                dependencies: [
                    .target(name: name),
                    .target(name: "\\(name)Testing")
                ],
                settings: commonSettings
            )
            
            return [
                interfaceTarget,
                featureTarget,
                testingTarget,
                testsTarget,
                exampleTarget
            ]
        }

        //MARK: - Target Factory
        func makeCoreTargets(
            name: String,
            bundleId: String,
            dependencies: [TargetDependency]
        ) -> [Target] {
            
            let commonSettings = Settings.settings(
                configurations: [],
                defaultSettings: .recommended
            )
            
            let interfaceTarget = Target.target(
                name: "\\(name)Interface",
                destinations: Project.destinations,
                product: Project.resolvedProductType(),
                bundleId: "com.\(name.lowercased()).app.\\(name)Interface",
                deploymentTargets: Project.minDeploymentVersion,
                infoPlist: .default,
                sources: ["Interface/**"],
                dependencies: [] + dependencies,
                settings: commonSettings
            )
            
            let coreTarget = Target.target(
                name: name,
                destinations: Project.destinations,
                product: Project.resolvedProductType(),
                bundleId: "com.\(name.lowercased()).app.\\(name)",
                deploymentTargets: Project.minDeploymentVersion,
                infoPlist: .default,
                sources: ["Sources/**"],
                resources: ["Resources/**"],
                dependencies: [
                    .target(name: "\\(name)Interface")
                ],
                settings: commonSettings
            )
            
            let testingTarget = Target.target(
                name: "\\(name)Testing",
                destinations: Project.destinations,
                product: Project.resolvedProductType(),
                bundleId: "com.\(name.lowercased()).app.\\(name)Testing",
                deploymentTargets: Project.minDeploymentVersion,
                infoPlist: .default,
                sources: ["Testing/**"],
                dependencies: [
                    .target(name: name)
                ] + dependencies,
                settings: commonSettings
            )
            
            let testsTarget = Target.target(
                name: "\\(name)Tests",
                destinations: Project.destinations,
                product: .unitTests,
                bundleId: "com.\(name.lowercased()).app.\\(name)Tests",
                deploymentTargets: Project.minDeploymentVersion,
                infoPlist: .default,
                sources: ["Tests/**"],
                dependencies: [
                    .target(name: name),
                    .target(name: "\\(name)Testing"),
                    .xctest
                ],
                settings: commonSettings
            )
            
            let exampleTarget = Target.target(
                name: "\\(name)Example",
                destinations: Project.destinations,
                product: .app,
                bundleId: "com.\(name.lowercased()).app.\\(name).example",
                deploymentTargets: Project.minDeploymentVersion,
                infoPlist: .extendingDefault(with: [
                    "CFBundleDisplayName": "\\(name)",
                    "CFBundleShortVersionString": "1.0.0",
                    "CFBundleVersion": "1",
                    "UILaunchStoryboardName": "LaunchScreen",
                ]),
                sources: ["Example/**"],
                dependencies: [
                    .target(name: name),
                    .target(name: "\\(name)Testing")
                ],
                settings: commonSettings
            )
            
            return [
                interfaceTarget,
                coreTarget,
                testingTarget,
                testsTarget,
                exampleTarget
            ]
        }
        """
        try write(content, to: folder + "/Project+Helpers.swift")
    }
}

extension ProjectInitializer {
    func writePackageFile(_ folder: String) throws {
        let content = """
        // swift-tools-version: 6.0
        @preconcurrency import PackageDescription

        #if TUIST
            import ProjectDescription
            import ProjectDescriptionHelpers

            let packageSettings = PackageSettings(
                productTypes: []
            )
        #endif

        let package = Package(
            name: "TMAKit",
            dependencies: []
        )
        """
        try write(content, to: folder + "/Package.swift")
    }
}

extension ProjectInitializer {
    func writeTuistFile(_ manifests: String) throws {
        let content = """
        import ProjectDescription

        let tuist = Tuist(
        //    Create an account with "tuist auth" and a project with "tuist project create"
        //    then uncomment the section below and set the project full-handle.
        //    * Read more: https://docs.tuist.io/guides/quick-start/gather-insights
        //
        //    fullHandle: "{account_handle}/{project_handle}",
        )
        """
        try write(content, to: manifests + "/Tuist.swift")
    }
}

extension ProjectInitializer {
    func writeWorkspaceFile(_ manifests: String, projectName: String) throws {
        let content = """
        import ProjectDescription

        let workspace = Workspace(
            name: "\(projectName)",
            projects: [
                "App",
            ]
        )
        """
        try write(content, to: manifests + "/Workspace.swift")
    }
}

extension ProjectInitializer {
    func write(_ content: String, to path: String) throws {
        try content.write(
            toFile: path,
            atomically: true,
            encoding: .utf8
        )
    }
}
