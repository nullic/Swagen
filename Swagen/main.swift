//
//  main.swift
//  Swagen
//
//  Created by Dmitriy Petrusevich on 9/26/19.
//  Copyright © 2019 Dmitriy Petrusevich. All rights reserved.
//

import Foundation


let launchURL = URL(fileURLWithPath: CommandLine.arguments[0])
let homeDir = launchURL.deletingLastPathComponent()
let appName = launchURL.lastPathComponent

if CommandLine.arguments.count != 3 {
    print("Usage example:")
    print("\(appName) ./swagger.json ./swag/gen/folder")
    print("\(appName) \"https://api-im-public-stage1.synesis-sport.com/v2/api-docs\" ./output")
} else {
    let input = CommandLine.arguments[1]
    let output = CommandLine.arguments[2]

    let inputURL: URL
    let outputURL: URL

    if input.contains(":") {
        inputURL = URL(string: input)!
    } else if input.hasPrefix("./") {
        inputURL = homeDir.appendingPathComponent(String(input.dropFirst().dropFirst()))
    } else {
        inputURL = URL(fileURLWithPath: input)
    }

    if output.hasPrefix("./") {
        outputURL = homeDir.appendingPathComponent(String(output.dropFirst().dropFirst()))
    } else {
        outputURL = URL(fileURLWithPath: output)
    }

    print("Output: \(outputURL.path)")

    let processor = SwaggerProcessor(jsonURL: inputURL)
    processor.run()

    let generator = SwaggerMoyaGenerator(outputFolder: outputURL, processor: processor)
    generator.run()
}
