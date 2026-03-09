//
//  NetworkError.swift
//  CoreNetwork
//
//  Created by Bruno Vinicius on 09/03/26.
//

import Foundation

public enum NetworkError: LocalizedError, Equatable {
    case invalidURL
    case serverError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case unauthorized
    case noInternet
    case unknown(String)
    
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        return lhs.localizedDescription == rhs.localizedDescription
    }
}
