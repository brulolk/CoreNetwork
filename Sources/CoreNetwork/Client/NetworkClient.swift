//
//  NetworkClient.swift
//  CoreNetwork
//
//  Created by Bruno Vinicius on 09/03/26.
//

import Foundation

public actor NetworkClient {
    
    public static let shared = NetworkClient()
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func request<T: Decodable>(endpoint: Endpoint, responseType: T.Type) async throws -> NetworkResponse<T> {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = await NetworkConfig.shared.defaultTimeout
        
        // 1. Injetar Headers do Endpoint
        endpoint.headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // 2. Injetar Headers Globais (Subscreve os do endpoint se houver colisão, útil para Tokens)
        let globalHeaders = await NetworkConfig.shared.globalHeaders
        globalHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // 3. Body
        request.httpBody = endpoint.body
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown("Resposta inválida do servidor.")
            }
            
            // 4. Tratamento de Status Code
            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                do {
                    let decodedData = try decoder.decode(T.self, from: data)
                    let stringHeaders = httpResponse.allHeaderFields as? [String: String] ?? [:]
                    return NetworkResponse(
                        data: decodedData,
                        statusCode: httpResponse.statusCode,
                        headers: stringHeaders
                    )
                } catch {
                    throw NetworkError.decodingError(error)
                }
            case 401:
                throw NetworkError.unauthorized
            default:
                throw NetworkError.serverError(statusCode: httpResponse.statusCode, data: data)
            }
            
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.noInternet
        }
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
