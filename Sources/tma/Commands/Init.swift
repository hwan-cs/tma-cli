//
//  Init.swift
//  tma-cli
//
//  Created by Jung Hwan Park on 11/17/25.
//

import ArgumentParser

struct Init: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Initialize a new TMA + Tuist project"
    )

    @Argument(help: "The name of the new project.")
    var name: String

    func run() throws {
        try ProjectInitializer().createProject(named: name)
    }
}
