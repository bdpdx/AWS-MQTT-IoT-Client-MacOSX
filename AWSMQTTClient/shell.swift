//
//  shell.swift
//  AWSMQTTClient
//
//  Created by Brian Doyle on 6/14/20.
//  Copyright © 2020 Balance Software. All rights reserved.
//

import Foundation

struct Shell: CustomDebugStringConvertible {
    let status: Int32
    let stderr: Data
    let stdout: Data

    var errString: String? { return String(data: stderr, encoding: .utf8) }
    var outString: String? { return String(data: stdout, encoding: .utf8) }

    var debugDescription: String {
        let result =
            "status: \(status)\n" +
            "output: \(String(describing: outString)))\n" +
            "error: \(String(describing: errString))"

        return result
    }

    @discardableResult static func run(_ commands: [String]) -> Shell? {
        let commands = [
            "set -e",
            "export PATH=$PATH:/usr/local/bin:/usr/local/sbin"
        ] + commands
        let commandsText = commands.joined(separator: "\n")

        guard let commandsData = commandsText.data(using: .utf8) else {
            print("failed to convert commands to Data:\n\(commands)")
            return nil
        }

        let error = Pipe()
        let input = Pipe()
        let output = Pipe()

        input.fileHandleForWriting.writeabilityHandler = { fileHandle in
            fileHandle.write(commandsData)
            input.fileHandleForWriting.closeFile()
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.standardError = error
        process.standardInput = input
        process.standardOutput = output

        do {
            try process.run()
        } catch {
            print(error.localizedDescription)
            return nil
        }

        process.waitUntilExit()

        let result = Shell(
            status: process.terminationStatus,
            stderr: error.fileHandleForReading.availableData,
            stdout: output.fileHandleForReading.availableData)

        return result
    }

    @discardableResult static func run(_ command: String) -> Shell? {
        return Shell.run([command])
    }
}
