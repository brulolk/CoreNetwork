//
//  NetworkClient.swift
//  CoreNetwork
//
//  Created by Bruno Vinicius on 09/03/26.
//

import Foundation

public final class NetworkClient: Sendable {
    
    public static let shared = NetworkClient()
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Camada 1: Base Bruta (Controle Total)
    public func requestData(endpoint: Endpoint, maxRetries: Int = 0) async throws -> (Data, HTTPURLResponse) {
        let request = try buildRequest(from: endpoint)
        
        print("\n🚀 [NETWORK REQUEST] \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("📦 [BODY]: \(bodyString)")
        }
        
        var currentAttempt = 0
        
        while true {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.badResponse
                }
                
                print("📥 [NETWORK RESPONSE] \(httpResponse.statusCode) \(request.url?.absoluteString ?? "")")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 [PAYLOAD]: \(jsonString)\n")
                }
                
                return (data, httpResponse)
                
            } catch {
                currentAttempt += 1
                if currentAttempt > maxRetries {
                    if let networkError = error as? NetworkError { throw networkError }
                    print("❌ [NETWORK ERROR]: \(error.localizedDescription)")
                    throw NetworkError.noInternet
                }
                print("🔄 [RETRY] Tentativa \(currentAttempt) de \(maxRetries)...")
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
    
    // MARK: - Camada 2: Conveniência (Com Tipagem Forte)
    public func request<T: Decodable>(endpoint: Endpoint, responseType: T.Type, maxRetries: Int = 0) async throws -> NetworkResponse<T> {
        
        let (data, httpResponse) = try await requestData(endpoint: endpoint, maxRetries: maxRetries)
        
        switch httpResponse.statusCode {
        case 200...299:
            // Usamos a nossa ferramenta isolada de Decode
            let decodedData = try NetworkDecoder.decode(T.self, from: data)
            let stringHeaders = httpResponse.allHeaderFields as? [String: String] ?? [:]
            return NetworkResponse(data: decodedData, statusCode: httpResponse.statusCode, headers: stringHeaders)
            
        default:
            throw NetworkError.serverError(statusCode: httpResponse.statusCode, data: data)
        }
    }
    
    // MARK: - Método Privado de Construção
    private func buildRequest(from endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(string: endpoint.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        if let queryParams = endpoint.queryParams, !queryParams.isEmpty {
            components.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        endpoint.headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = endpoint.body
        
        return request
    }
}
