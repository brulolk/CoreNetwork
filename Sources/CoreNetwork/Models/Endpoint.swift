//
//  Endpoint.swift
//  CoreNetwork
//
//  Created by Bruno Vinicius on 09/03/26.
//

import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

public protocol Endpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryParams: [String: String]? { get }
    var body: Data? { get }
    var timeout: TimeInterval? { get }
}

public extension Endpoint {
    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
    
    var queryParams: [String: String]? {
        return nil
    }
    
    var body: Data? {
        return nil
    }
    
    var timeout: TimeInterval? { // 🆕 Valor padrão opcional
        return nil
    }
}

public extension Endpoint {
    /// Converte um Dicionário em Data de forma limpa
    func encodeBody(dictionary: [String: Any]) -> Data? {
        return try? JSONSerialization.data(withJSONObject: dictionary)
    }
    
    /// Converte qualquer Struct/Model que assine Encodable em Data
    func encodeBody<T: Encodable>(_ model: T) -> Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        return try? encoder.encode(model)
    }
}
