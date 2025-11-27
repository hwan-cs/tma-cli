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
            throw NSError(
                domain: "com.tma.cli",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey : "Module '\(name)' already exists!"
                ]
            )
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
        try updateWorkspace(with: name, type: type)
        try updateAppProject(with: name, type: type)
        print("🔗 Added \(name) module as dependency to Workspace and App")
    }
    
    private func updateWorkspace(with name: String, type: ModuleType) throws {
        let workspacePath = "\(fm.currentDirectoryPath)/Workspace.swift"
        guard fm.fileExists(atPath: workspacePath) else {
            print("⚠️ Workspace.swift not found, skipping...")
            return
        }
        
        let moduleEntry = "\"\(type == .feature ? "Feature" : "Core")/\(name)\""

        var content = try String(contentsOfFile: workspacePath)

        // Avoid duplicates
        guard !content.contains(moduleEntry) else {
            return
        }

        // Insert inside the `projects: [`
        if let range = content.range(of: "projects: [") {
            if let endRange = content.range(of: "]", range: range.upperBound..<content.endIndex) {
                content.insert(contentsOf: "\t\(moduleEntry),", at: endRange.lowerBound)
                
                // New range of closing bracket
                if let newEnd = content.range(of: "]", range: range.upperBound..<content.endIndex) {
                    let before = content.index(before: newEnd.lowerBound)

                    // Ensure bracket is newline-separated
                    if content[before] != "\n" {
                        content.insert(contentsOf: "\n\t", at: newEnd.lowerBound)
                    }
                }
            }
        }

        try write(content, to: workspacePath)
        print("🛠️ Updated Workspace.swift")
    }
    
    private func updateAppProject(with name: String, type: ModuleType) throws {
        let appProjectPath = "\(fm.currentDirectoryPath)/App/Project.swift"
        guard fm.fileExists(atPath: appProjectPath) else {
            print("⚠️ App/Project.swift not found, skipping...")
            return
        }

        var content = try String(contentsOfFile: appProjectPath)

        let dependencyLine = ".project(target: \"\(name)\", path: \"../\(type == .feature ? "Feature" : "Core")/\(name)\")"

        // Avoid duplicates
        guard !content.contains(dependencyLine) else {
            return
        }

        guard let appTargetRange = content.range(of: "product: .app") else {
            print("⚠️ Could not find app target in Project.swift")
            return
        }

        // Find dependencies: [ ... ] of that target
        if let depsRangeStart = content.range(of: "dependencies: [", range: appTargetRange.lowerBound..<content.endIndex),
           let depsRangeEnd = content.range(of: "]", range: depsRangeStart.upperBound..<content.endIndex) {

            content.insert(contentsOf: "\t\(dependencyLine),", at: depsRangeEnd.lowerBound)
            
            // New range of closing bracket
            if let newEnd = content.range(of: "]", range: depsRangeStart.upperBound..<content.endIndex) {
                let before = content.index(before: newEnd.lowerBound)

                // Ensure bracket is newline-separated
                if content[before] != "\n" {
                    content.insert(contentsOf: "\n\t\t\t", at: newEnd.lowerBound)
                }
            }
        }

        try content.write(toFile: appProjectPath, atomically: true, encoding: .utf8)
        print("🛠️ Updated App Project.swift")
    }
}

extension ModuleCreator {
    func createDirectory(_ path: String) throws {
        try fm.createDirectory(atPath: path, withIntermediateDirectories: true)
    }
    
    func write(_ content: String, to path: String) throws {
        try content.write(
            toFile: path,
            atomically: true,
            encoding: .utf8
        )
    }
    
    func generateProjectSwift(name: String, type: ModuleType) -> String {
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
