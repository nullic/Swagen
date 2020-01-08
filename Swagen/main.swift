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

if CommandLine.arguments.count < 3 {
    print("Usage example:")
    print("\t\(appName) ./swagger.json ./swag/gen/folder")
    print("\t\(appName) -ip \"https://api-im-public-stage1.synesis-sport.com/v2/api-docs\" ./output")
    print("\nOptions:")
    print("\ti: access level - 'internal'")
    print("\ta: add 'AccessTokenAuthorizable' conformance (.custom(\"\"))")
    print("\tr: add 'Response' decoding")
    print("\tp: add 'Server<Target: TargetType>: MoyaProvider<Target>' implementation")

} else if CommandLine.arguments.count <= 4 {
    let input, output, options: String
    if CommandLine.arguments.count == 3 {
        options = ""
        input = CommandLine.arguments[1]
        output = CommandLine.arguments[2]
    } else {
        options = CommandLine.arguments[1]
        input = CommandLine.arguments[2]
        output = CommandLine.arguments[3]
    }

    var generatorOpts: SwaggerMoyaGenerator.Options = []
    if options.contains("i") { generatorOpts.insert(.internalLevel) }
    if options.contains("a") { generatorOpts.insert(.customAuthorization) }
    if options.contains("r") { generatorOpts.insert(.responseTypes) }
    if options.contains("p") { generatorOpts.insert(.moyaProvider) }

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

    let processor = SwaggerProcessor(jsonURL: inputURL)
    processor.run()

    let generator = SwaggerMoyaGenerator(outputFolder: outputURL, processor: processor, options: generatorOpts)
    generator.run()

    #if DEBUG
    print(outputURL.path)
    #endif
}
