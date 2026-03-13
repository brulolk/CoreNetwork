//
//  NetworkResponse.swift
//  CoreNetwork
//
//  Created by Bruno Vinicius on 09/03/26.
//

import Foundation

public struct NetworkResponse<T: Decodable> {
    public let data: T
    public let statusCode: Int
    public let headers: [String: String]
    
    public init(data: T, statusCode: Int, headers: [String: String]) {
        self.data = data
        self.statusCode = statusCode
        self.headers = headers
    }
    
    /// Helper para extrair um header específico facilmente (ex: "x-pagination-count")
    public func valueForHeader(_ key: String) -> String? {
        // Busca ignorando maiúsculas e minúsculas
        return headers.first { $0.key.caseInsensitiveCompare(key) == .orderedSame }?.value
    }
}
