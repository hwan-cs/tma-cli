//
//  ModuleCreator.swift
//  tma-cli
//
//  Created by Jung Hwan Park on 11/17/25.
//

import Foundation
import ArgumentParser

enum ModuleType {
    case feature
    case core
}

struct RuntimeError: Error, CustomStringConvertible {
    var description: String
    
    init(_ description: String) {
        self.description = description
    }
}

struct ModuleCreator {
    let fm = FileManager.default
    func createModule(named name: String, type: ModuleType) throws {
        let cwd = fm.currentDirectoryPath

        // 1. Feature or Core root
        let rootFolder = type == .feature ? "Feature" : "Core"
        let rootPath = "\(cwd)/\(rootFolder)"

        if !fm.fileExists(atPath: rootPath) {
            try fm.createDirectory(atPath: rootPath, withIntermediateDirectories: true)
            print("📁 Created \(rootFolder) directory")
        }

        // 2. Module folder
        let modulePath = "\(rootPath)/\(name)"
        
        if fm.fileExists(atPath: modulePath) {
            throw RuntimeError("Module '\(name)' already exists!")
        }

        try fm.createDirectory(atPath: modulePath, withIntermediateDirectories: true)
        print("📁 Created \(modulePath)")

        // 3. Project.swift
        let projectFile = "\(modulePath)/Project.swift"
        let contents = generateProjectSwift(name: name, type: type)

        try write(contents, to: projectFile)
        print("📝 Created Project.swift")
        
        try createDirectory("\(modulePath)/Interface")
        try write(
        """
        // Interface.swift
        """,
        to: "\(modulePath)/Interface/Interface.swift"
        )
        try createDirectory("\(modulePath)/Sources")
        try write(
        """
        // Sources.swift
        """,
        to: "\(modulePath)/Sources/Sources.swift"
        )
        try createDirectory("\(modulePath)/Resources")
        try createDirectory("\(modulePath)/Tests")
        try write(
        """
        // Tests.swift
        """,
        to: "\(modulePath)/Tests/Tests.swift"
        )
        try createDirectory("\(modulePath)/Testing")
        try write(
        """
        // Testing.swift
        """,
        to: "\(modulePath)/Testing/Testing.swift"
        )
        try createDirectory("\(modulePath)/Example")
        try write(
        """
        import SwiftUI

        @main
        struct \(name)App: App {
            var body: some Scene {
                WindowGroup {
                    Text("Hello, World!")
                }
            }
        }
        """,
        to: "\(modulePath)/Example/\(name)App.swift"
        )
    }
    
    private func createDirectory(_ path: String) throws {
        try fm.createDirectory(atPath: path, withIntermediateDirectories: true)
    }
    
    private func write(_ content: String, to path: String) throws {
        try content.write(
            toFile: path,
            atomically: true,
            encoding: .utf8
        )
    }
}

extension ModuleCreator {
    private func generateProjectSwift(name: String, type: ModuleType) -> String {
        let factory = type == .feature ? "feature" : "core"

        return """
        import ProjectDescription
        import ProjectDescriptionHelpers

        let project = Project.\(factory)(
            name: "\(name)",
            bundleId: bundleId,
            dependencies: []
        )
        """
    }
}
