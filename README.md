# tma-cli
Swift command-line tool that generates TMA(The Modular Architecture) projects and modules using Tuist

## Pre-requisite

- Requires Xcode 15 or later (Swift 5.9)
- Tuist
  - This tool relies on Tuist for project generation.
  - Required version: Tuist 4.54.3
- Install Tuist with:
```
curl -Ls https://install.tuist.io | bash
```

Verify version:
```
tuist version
```

## How to use

Running:

```sh
swift run tma init NameOfYourProject
```
automatically bootstraps a fully-configured iOS project using Tuist and the TMA modular architecture.

Running:
```sh
swift run tma create NameOfYourFeature --feature
```
automatically generates a new Feature module inside your TMA-structured project.

Running:
```sh
swift run tma create NameOfCoreModule --core
```
automatically generates a new Core module inside your TMA-structured project.
