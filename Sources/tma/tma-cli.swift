import ArgumentParser

@main
struct TMA: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tma",
        abstract: "A Tuist TMA project helper.",
        subcommands: [
            Init.self,
            Create.self
        ]
    )
}
