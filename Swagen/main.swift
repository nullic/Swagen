//
//  main.swift
//  Swagen
//
//  Created by Dmitriy Petrusevich on 9/26/19.
//  Copyright © 2019 Dmitriy Petrusevich. All rights reserved.
//

import Foundation
import ArgumentParser


let launchURL = URL(fileURLWithPath: CommandLine.arguments[0])
let homeDir = launchURL.deletingLastPathComponent()
let appName = launchURL.lastPathComponent


extension String {
    static func toURL(_ string: String) throws -> URL {
        if string.contains(":") {
            return URL(string: string)!
        } else if string.hasPrefix("./") {
            return homeDir.appendingPathComponent(String(string.dropFirst().dropFirst()))
        } else {
            return URL(fileURLWithPath: string)
        }
    }
    
    static func toAuthorizationType(_ string: String) throws -> AuthorizationType {
        if string == "basic" { return .basic }
        if string == "bearer" { return .bearer }
        if string.hasPrefix("custom") { return .custom(value: String(string.dropFirst(7))) }
        return .none
    }
    
    static func toRequestsStyle(_ string: String) throws -> RequestsStyle {
        if string.lowercased() == "async" { return .async }
        if string.lowercased() == "asyncawait" { return .asyncAwait }
        return .both
    }
}

enum RequestsStyle {
    case async
    case asyncAwait
    case both
}


struct Swagen: ParsableCommand {
    @Argument(help: "Swagger JSON (local path or URL)", transform: String.toURL)
    var inputURL: URL
    
    @Argument(help: "Output path", transform: String.toURL)
    var outputURL: URL
    
    @Option(name: .customLong("access"), parsing: .next, help: "Generate code access modifier public|open|internal")
    var accessModifier: String = "public"
    
    @Option(parsing: .next, help: "Add 'AccessTokenAuthorizable' conformance - basic|bearer|custom_{value}", transform: String.toAuthorizationType)
    var authorizationType: AuthorizationType = .none
    
    @Option(name: .customLong("server-requests-style"), parsing: .next, help: "Generated server requests style - async|asyncawait|both", transform: String.toRequestsStyle)
    var serverRequestsStyle: RequestsStyle = .async
    
    @Option(name: .customLong("async-await-avail"), parsing: .next, help: "Async / await availability modifier. For example: @available(iOS 15.0.0, *)")
    var asyncAwaitVersion: String = "@available(iOS 15.0.0, *)"
    
    @Option(name: .customLong("base-url"), parsing: .next, help: "Custom base server URL", transform: String.toURL)
    var baseURL: URL?
    
    @Flag(name: .customLong("decode-response"), help: "Add 'Response' decoding")
    var decodeResponse: Bool = false
    
    @Flag(name: .customLong("add-server"), help: "Add 'Server<Target: TargetType>: MoyaProvider<Target>' implementation")
    var generateServer: Bool = false
    
    @Flag(name: .customLong("init-default"), help: "Add default 'nil' value for generated struct init()")
    var initDefault: Bool = false
    
    @Flag(name: .customLong("var-struct"), help: "Use 'var' instead of 'let' for generated structs")
    var varStruct: Bool = false
    
    @Flag(name: .customLong("sync-on-main"), help: "Allow sync operations on .main queue/thread")
    var syncOnMain: Bool = false
    
    func run() throws {

        let processor = SwaggerProcessor(jsonURL: inputURL, customBaseURL: baseURL)
        processor.run()

        let generator = SwaggerMoyaGenerator(outputFolder: outputURL, processor: processor)
        generator.serverRequestsStyle = serverRequestsStyle
        generator.accessModifier = accessModifier
        generator.authorizationType = authorizationType
        generator.decodeResponse = decodeResponse
        generator.generateServer = generateServer
        generator.initDefault = initDefault
        generator.varStruct = varStruct
        generator.asyncAwaitVersion = asyncAwaitVersion
        generator.syncOnMain = syncOnMain
        generator.run()
        
        #if DEBUG
        print(outputURL.path)
        #endif
    }
}

Swagen.main()
