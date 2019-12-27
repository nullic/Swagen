//
//  String+Generator.swift
//  Swagen
//
//  Created by Dmitriy Petrusevich on 9/27/19.
//  Copyright © 2019 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

let reserverWords = ["Type", "Self", "self", "Codable", "default"]
let indent = "    "
var genAccessLevel = "public"


extension String {
    var escaped: String {
        var result = self.filter { $0.isLetter || $0.isNumber || $0 == "_" }
        result = reserverWords.contains(result) ? "`\(result)`" : result
        return result
    }

    var capitalizedFirstLetter: String {
        guard self.isEmpty == false else { return self }
        return self.prefix(1).uppercased() + self.dropFirst()
    }

    var loweredFirstLetter: String {
        guard self.isEmpty == false else { return self }
        return self.prefix(1).lowercased() + self.dropFirst()
    }
}

let genFilePrefix =
"""
// Generated file

import Foundation
"""


let utilsFile =
"""
\(genFilePrefix)
import Moya

extension Dictionary where Value == Any? {
    func unopt() -> [Key: Any] {
        return reduce(into: [Key: Any]()) { (result, kv) in
            if let value = kv.value {
                result[kv.key] = value
            }
        }
    }

    func unoptString() -> [Key: String] {
        return reduce(into: [Key: String]()) { (result, kv) in
            if let value = kv.value {
                result[kv.key] = String(describing: value)
            }
        }
    }
}

\(genAccessLevel) enum AnyObjectValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: AnyObjectValue])
    case array([AnyObjectValue])

    \(genAccessLevel) init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: AnyObjectValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([AnyObjectValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.typeMismatch(AnyObjectValue.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Not a JSON object"))
        }
    }

    \(genAccessLevel) func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
}

\(genAccessLevel) enum FileValue {
    case data(value: Foundation.Data, fileName: String, mimeType: String)
    case url(value: Foundation.URL)

    func moyaFormData(name: String) -> MultipartFormData {
        switch self {
        case .data(let value, let fileName, let mimeType):
            return MultipartFormData(provider: .data(value), name: name, fileName: fileName, mimeType: mimeType)
        case .url(let value):
            return MultipartFormData(provider: .file(value), name: name)
        }
    }
}

"""


let targetTypeResponseCode =
"""
\(genAccessLevel) enum ResponseDecodeError {
    case unknowCode
}

\(genAccessLevel) protocol TargetTypeResponse: TargetType {
    func decodeResponse(_ response: Moya.Response) throws -> Any
}

"""


let serverFile =
"""
import Foundation
import Moya

fileprivate let callbackQueue = DispatchQueue(label: "network.callback.queue")

fileprivate extension JSONDecoder {
    func decodeSafe<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        do {
            return try self.decode(type, from: data)
        } catch DecodingError.dataCorrupted(let context) {
            let value = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            if let result = value as? T {
                return result
            } else {
                throw DecodingError.dataCorrupted(context)
            }
        }
    }
}

\(genAccessLevel) enum ServerError: Error {
    case invalidResponseCode(_: Int)
    case connection(_: Error)
    case decoding(_: Error)
    case unknown(_: Error)
}

final \(genAccessLevel) class Server<Target: TargetType>: MoyaProvider<Target> {
    let baseURL: URL

    \(genAccessLevel) init(baseURL: URL, accessToken: String? = nil) {
        self.baseURL = baseURL
        var plugins: [PluginType] = []

        if ProcessInfo.processInfo.environment["NETWORK_LOGS"] != nil {
            plugins.append(NetworkLoggerPlugin(verbose: true))
        }

        if let accessToken = accessToken {
            plugins.append(AccessTokenPlugin(tokenClosure: { accessToken }))
        }

        super.init(endpointClosure: { target -> Endpoint in
            let url: URL
            if target.path.hasPrefix("/") {
                url = baseURL.appendingPathComponent(String(target.path.dropFirst()))
            } else {
                url = baseURL.appendingPathComponent(target.path)
            }

            return Endpoint(
                url: url.absoluteString,
                sampleResponseClosure: { .networkResponse(200, target.sampleData) },
                method: target.method,
                task: target.task,
                httpHeaderFields: target.headers
            )
        }, callbackQueue: callbackQueue, plugins: plugins)
    }

    // MARK: - Async requests

    @discardableResult
    \(genAccessLevel) func request(_ target: Target, callbackQueue: DispatchQueue? = .none, progress: ProgressBlock? = .none, completion: @escaping (Result<Void, ServerError>) -> Void) -> Moya.Cancellable {

        return super.request(target, callbackQueue: callbackQueue, progress: progress) { responseResult in
            let result = Result<Void, Error> {
                let response = try responseResult.get()
                guard response.statusCode >= 200, response.statusCode < 300 else {
                    throw ServerError.invalidResponseCode(response.statusCode)
                }
                return Void()
            }

            completion(result.mapError { (error: Error) -> ServerError in
                if let error = error as? MoyaError, case .underlying(let underlying, _) = error {
                    if (underlying as NSError).domain == NSURLErrorDomain {
                        return ServerError.connection(underlying)
                    } else {
                        return ServerError.unknown(underlying)
                    }
                } else if let error = error as? ServerError {
                    return error
                } else {
                    return ServerError.unknown(error)
                }
            })
        }
    }

    @discardableResult
    \(genAccessLevel) func request<DataType: Decodable>(_ target: Target, callbackQueue: DispatchQueue? = .none, progress: ProgressBlock? = .none, completion: @escaping (Result<DataType, ServerError>) -> Void) -> Moya.Cancellable {

        return super.request(target, callbackQueue: callbackQueue, progress: progress) { responseResult in
            let result = Result<DataType, Error> {
                let response = try responseResult.get()
                guard response.statusCode >= 200, response.statusCode < 300 else {
                    throw ServerError.invalidResponseCode(response.statusCode)
                }
                do {
                    return try JSONDecoder().decodeSafe(DataType.self, from: response.data)
                } catch {
                    throw ServerError.decoding(error)
                }
            }

            completion(result.mapError { (error: Error) -> ServerError in
                if let error = error as? MoyaError, case .underlying(let underlying, _) = error {
                    if (underlying as NSError).domain == NSURLErrorDomain {
                        return ServerError.connection(underlying)
                    } else {
                        return ServerError.unknown(underlying)
                    }
                } else if let error = error as? ServerError {
                    return error
                } else {
                    return ServerError.unknown(error)
                }
            })
        }
    }

    // MARK: - Sync requests

    \(genAccessLevel) func response(_ target: Target, callbackQueue: DispatchQueue? = .none, progress: ProgressBlock? = .none) throws {
        assert(Thread.isMainThread == false)

        var result: Result<Void, ServerError>!
        let semaphore = DispatchSemaphore(value: 0)
        self.request(target, callbackQueue: callbackQueue, progress: progress) { (response: Result<Void, ServerError>) in
            result = response
            semaphore.signal()
        }
        semaphore.wait()
        return try result.get()
    }

    \(genAccessLevel) func response<DataType: Decodable>(_ target: Target, callbackQueue: DispatchQueue? = .none, progress: ProgressBlock? = .none) throws -> DataType {
        assert(Thread.isMainThread == false)

        var result: Result<DataType, ServerError>!
        let semaphore = DispatchSemaphore(value: 0)
        self.request(target, callbackQueue: callbackQueue, progress: progress) { (response: Result<DataType, ServerError>) in
            result = response
            semaphore.signal()
        }
        semaphore.wait()
        return try result.get()
    }
}

"""
