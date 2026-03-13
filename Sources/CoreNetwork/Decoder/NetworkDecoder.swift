//
//  NetworkDecoder.swift
//  CoreNetwork
//
//  Created by Bruno Vinicius on 13/03/26.
//

import Foundation

public struct NetworkDecoder: Sendable {
    
    public static var defaultDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
    
    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try defaultDecoder.decode(T.self, from: data)
        } catch {
            print("❌ [DECODE ERROR]: Falha ao converter para \(String(describing: T.self)). Erro: \(error)")
            throw NetworkError.decodingError(error)
        }
    }
}
