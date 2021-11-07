//
//  String+Generator.swift
//  Swagen
//
//  Created by Dmitriy Petrusevich on 9/27/19.
//  Copyright © 2019 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

let reserverWords = ["Type", "Self", "self", "Codable", "default", "public", "private", "internal", "func", "let", "var", "enum"]
let indent = "    "
var genAccessLevel = "public"
var genNonClassAccessLevel = "public"


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
// swiftformat:disable all
// swiftlint:disable all
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

extension JSONDecoder {
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

\(genNonClassAccessLevel) enum AnyObjectValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: AnyObjectValue])
    case array([AnyObjectValue])

    \(genNonClassAccessLevel) init(from decoder: Decoder) throws {
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

    \(genNonClassAccessLevel) func encode(to encoder: Encoder) throws {
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

\(genNonClassAccessLevel) enum FileValue {
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

\(genNonClassAccessLevel) struct HTTPHeadersPlugin: PluginType {
    \(genNonClassAccessLevel) typealias HTTPHeadersClosure = (URLRequest) -> [String: String]
    \(genNonClassAccessLevel) let headersClosure: HTTPHeadersClosure

    \(genNonClassAccessLevel) init(headersClosure: @escaping HTTPHeadersClosure) {
        self.headersClosure = headersClosure
    }

    \(genNonClassAccessLevel) func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request

        let headers = headersClosure(request)
        for (field, value) in headers {
            request.addValue(value, forHTTPHeaderField: field)
        }

        return request
    }
}

"""


let targetTypeResponseCode =
"""

\(genNonClassAccessLevel) enum ResponseDecodeError: Error {
    case unknowCode
}

\(genNonClassAccessLevel) protocol TargetTypeResponse: TargetType {
    func decodeResponse(_ response: Moya.Response) throws -> Any
}

"""


let server14File =
"""
\(genFilePrefix)
import Moya

fileprivate let callbackQueue = DispatchQueue(label: "network.callback.queue")

\(genNonClassAccessLevel) enum ServerError: Error {
    case invalidResponseCode(_: Int, _: Data)
    case connection(_: Error)
    case decoding(_: Error)
    case unknown(_: Error)
}

extension Result {
    func mappedError() -> Result<Success, ServerError>  {
        return mapError { (error: Error) -> ServerError in
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
        }
    }
}

\(genAccessLevel) class Server<Target: TargetType>: MoyaProvider<Target> {
    let baseURL: URL
    let responseErrorMapper: (ServerError) -> Error

    convenience \(genNonClassAccessLevel) init(baseURL: URL, addHeadersClosure: HTTPHeadersPlugin.HTTPHeadersClosure? = nil, accessToken: String? = nil, logLevel: Moya.NetworkLoggerPlugin.Configuration.LogOptions? = nil, protocolClasses: [AnyClass]? = nil, responseErrorMapper: @escaping (ServerError) -> Error = { $0 }) {

        var plugins: [PluginType] = []

        if let accessToken = accessToken {
            plugins.append(AccessTokenPlugin(tokenClosure: { _ in accessToken }))
        }

        if let headersClosure = addHeadersClosure {
            plugins.append(HTTPHeadersPlugin(headersClosure: headersClosure))
        }

        self.init(baseURL: baseURL, plugins: plugins, logLevel: logLevel, protocolClasses: protocolClasses, responseErrorMapper: responseErrorMapper)
    }

    \(genNonClassAccessLevel) init(baseURL: URL, plugins: [Moya.PluginType] = [], logLevel: Moya.NetworkLoggerPlugin.Configuration.LogOptions? = nil, protocolClasses: [AnyClass]? = nil, responseErrorMapper: @escaping (ServerError) -> Error = { $0 }) {
        self.baseURL = baseURL
        self.responseErrorMapper = responseErrorMapper
        var serverPlugins: [PluginType] = []

        if ProcessInfo.processInfo.environment["NETWORK_LOGS"] != nil || logLevel != nil {
            serverPlugins.append(NetworkLoggerPlugin(configuration: .init(logOptions: logLevel ?? .verbose)))
        }

        if plugins.isEmpty == false {
            serverPlugins.append(contentsOf: plugins)
        }

        let configuration = type(of: self).alamofireSessionConfiguration(protocolClasses: protocolClasses)
        let session = Session(configuration: configuration, startRequestsImmediately: false)

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
        }, callbackQueue: callbackQueue, session: session, plugins: serverPlugins)
    }

    \(genAccessLevel) class func alamofireSessionConfiguration(protocolClasses: [AnyClass]?) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = protocolClasses
        configuration.headers = .default
        return configuration
    }

    // MARK: - Async requests

    @discardableResult
    \(genAccessLevel) func request(_ target: Target, callbackQueue: DispatchQueue? = .none, progress: ProgressBlock? = .none, completion: @escaping (Result<Void, ServerError>) -> Void) -> Moya.Cancellable {

        return super.request(target, callbackQueue: callbackQueue, progress: progress) { responseResult in
            let result = Result<Void, Error> {
                let response = try responseResult.get()
                guard response.statusCode >= 200, response.statusCode < 300 else {
                    throw ServerError.invalidResponseCode(response.statusCode, response.data)
                }
                return Void()
            }

            completion(result.mappedError())
        }
    }

    @discardableResult
    \(genAccessLevel) func request<DataType: Decodable>(_ target: Target, callbackQueue: DispatchQueue? = .none, progress: ProgressBlock? = .none, completion: @escaping (Result<DataType, ServerError>) -> Void) -> Moya.Cancellable {

        return super.request(target, callbackQueue: callbackQueue, progress: progress) { responseResult in
            let result = Result<DataType, Error> {
                let response = try responseResult.get()
                guard response.statusCode >= 200, response.statusCode < 300 else {
                    throw ServerError.invalidResponseCode(response.statusCode, response.data)
                }
                do {
                    return try JSONDecoder().decodeSafe(DataType.self, from: response.data)
                } catch {
                    throw ServerError.decoding(error)
                }
            }

            completion(result.mappedError())
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
        return try result.mapError(responseErrorMapper).get()
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
        return try result.mapError(responseErrorMapper).get()
    }

    // MARK: - Async/Await requests

    @available(iOS 15.0.0, *)
    \(genAccessLevel) func request(_ target: Target, callbackQueue: DispatchQueue? = .none, progress: ProgressBlock? = .none) async throws {
        var cancellable: Moya.Cancellable?

        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                cancellable = self.request(target, callbackQueue: callbackQueue, progress: progress) { responseResult in
                    continuation.resume(with: responseResult)
                }
            }
        } onCancel: { [cancellable] in
            cancellable?.cancel()
        }
    }
    
    @available(iOS 15.0.0, *)
    \(genAccessLevel) func request<DataType: Decodable>(_ target: Target, callbackQueue: DispatchQueue? = .none, progress: ProgressBlock? = .none) async throws -> DataType {
        var cancellable: Moya.Cancellable?

        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                cancellable = self.request(target, callbackQueue: callbackQueue, progress: progress) { responseResult in
                    continuation.resume(with: responseResult)
                }
            }
        } onCancel: { [cancellable] in
            cancellable?.cancel()
        }
    }
}

"""
