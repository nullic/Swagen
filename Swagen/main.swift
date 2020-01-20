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
    print("\t\(appName) ./swagger.json ./swag/gen/folder {optional generator kind}")
    print("\t\(appName) -ip \"https://api-im-public-stage1.synesis-sport.com/v2/api-docs\" ./output moya14")
    print("\nOptions:")
    print("\ti: access level - 'internal'")
    print("\ta: add 'AccessTokenAuthorizable' conformance (.custom(\"\"))")
    print("\tr: add 'Response' decoding")
    print("\tp: add 'Server<Target: TargetType>: MoyaProvider<Target>' implementation")
    print("\to: add default 'nil' value for generated struct init()")
    print("\tv: use 'var' instead of 'let' for generated struct")
    print("\nGenerator Kind:")
    print("\tmoya13: generate Moya up to version 13.x.x - default value")
    print("\tmoya14: generate Moya from version 14.0.0")

} else {
    var input, output: String!
    var generatorOpts: SwaggerMoyaGenerator.Options = []
    var generatorVersion: SwaggerMoyaGenerator.Version = .v13

    for (index, arg) in CommandLine.arguments.enumerated() {
        if index == 0 { continue }
        if arg.hasPrefix("-") {
            if arg.contains("i") { generatorOpts.insert(.internalLevel) }
            if arg.contains("a") { generatorOpts.insert(.customAuthorization) }
            if arg.contains("r") { generatorOpts.insert(.responseTypes) }
            if arg.contains("p") { generatorOpts.insert(.moyaProvider) }
            if arg.contains("o") { generatorOpts.insert(.optinalInit) }
            if arg.contains("v") { generatorOpts.insert(.varStruct) }
        } else if input == nil {
            input = arg
        } else if output == nil {
            output = arg
        } else {
            if arg.lowercased() == "moya13" { generatorVersion = .v13 }
            if arg.lowercased() == "moya14" { generatorVersion = .v14 }
            break
        }
    }

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

    let generator = SwaggerMoyaGenerator(outputFolder: outputURL, processor: processor, options: generatorOpts, version: generatorVersion)
    generator.run()

    #if DEBUG
    print(outputURL.path)
    #endif
}
