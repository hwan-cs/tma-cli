//
//  Create.swift
//  tma-cli
//
//  Created by Jung Hwan Park on 11/17/25.
//

import ArgumentParser
import Foundation

struct Create: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new TMA module (feature/core)."
    )

    @Argument(help: "The name of the module to create.")
    var moduleName: String

    @Flag(name: [.customShort("f"), .long], help: "Create a feature module.")
    var feature: Bool = false

    @Flag(name: [.customShort("c"), .long], help: "Create a core module.")
    var core: Bool = false

    func run() throws {
        guard feature || core else {
            throw ValidationError("You must specify --feature or --core")
        }

        try ModuleCreator().createModule(
            named: moduleName,
            type: feature ? .feature : .core
        )

        print("🎉 Module \(moduleName) created!")
    }
}
