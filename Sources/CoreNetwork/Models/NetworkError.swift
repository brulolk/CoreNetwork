//
//  NetworkError.swift
//  CoreNetwork
//
//  Created by Bruno Vinicius on 09/03/26.
//

import Foundation

public enum NetworkError: Error, Equatable, Sendable {
    case invalidURL
    case badResponse
    case serverError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case noInternet
    case disconnected
    case timeout
    
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL): return true
        case (.badResponse, .badResponse): return true
        case (.noInternet, .noInternet): return true
        case (.disconnected, .disconnected): return true
        case (.timeout, .timeout): return true
        case (.serverError(let a, _), .serverError(let b, _)): return a == b
        case (.decodingError(let a), .decodingError(let b)):
            // Comparamos o domínio e código do erro interno para garantir equidade
            return (a as NSError).domain == (b as NSError).domain && (a as NSError).code == (b as NSError).code
        default: return false
        }
    }
}
