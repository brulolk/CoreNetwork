//
//  NetworkError.swift
//  CoreNetwork
//
//  Created by Bruno Vinicius on 09/03/26.
//

import Foundation

public enum NetworkError: Error, Equatable {
    case invalidURL
    case badResponse
    case serverError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case noInternet
    case disconnected
    case timeout
    
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        return lhs.localizedDescription == rhs.localizedDescription
    }
}
