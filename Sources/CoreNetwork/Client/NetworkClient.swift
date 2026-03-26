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
    private let logger: NetworkLogger
    
    public init(session: URLSession = .shared, logger: NetworkLogger = DefaultNetworkLogger()) {
        self.session = session
        self.logger = logger
    }
    
    // MARK: - Camada 1: Base Bruta (Controle Total)
    public func requestData(endpoint: Endpoint, maxRetries: Int = 0) async throws -> (Data, HTTPURLResponse) {
        let request = try await buildRequest(from: endpoint)
 
        logger.log("\n🚀 [NETWORK REQUEST] \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            logger.log("📦 [BODY]: \(bodyString)")
        }
        
        var currentAttempt = 0
        
        while true {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.badResponse
                }
                
                logger.log("📥 [NETWORK RESPONSE] \(httpResponse.statusCode) \(request.url?.absoluteString ?? "")")
                if let jsonString = String(data: data, encoding: .utf8) {
                    logger.log("📄 [PAYLOAD]: \(jsonString)\n")
                }
                
                return (data, httpResponse)
                
            } catch {
                currentAttempt += 1
                if currentAttempt > maxRetries {
                    if let networkError = error as? NetworkError { throw networkError }
                    
                    if let urlError = error as? URLError, urlError.code == .timedOut {
                        logger.log("⏱️ [NETWORK TIMEOUT]: A requisição excedeu o limite de tempo.")
                        throw NetworkError.timeout
                    }
                  
                    logger.log("❌ [NETWORK ERROR]: \(error.localizedDescription)")
                    throw NetworkError.noInternet
                }
     
                logger.log("🔄 [RETRY] Tentativa \(currentAttempt) de \(maxRetries)...")
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
    
    // MARK: - Camada 2: Conveniência (Com Tipagem Forte)
    public func request<T: Decodable>(endpoint: Endpoint, responseType: T.Type, maxRetries: Int = 0) async throws -> NetworkResponse<T> {
        let (data, httpResponse) = try await requestData(endpoint: endpoint, maxRetries: maxRetries)
        
        switch httpResponse.statusCode {
        case 200...299:
            let decodedData = try NetworkDecoder.decode(T.self, from: data)
            let stringHeaders = httpResponse.allHeaderFields as? [String: String] ?? [:]
            return NetworkResponse(data: decodedData, statusCode: httpResponse.statusCode, headers: stringHeaders)
        default:
            throw NetworkError.serverError(statusCode: httpResponse.statusCode, data: data)
        }
    }
    
    // MARK: - Método Privado de Construção
    private func buildRequest(from endpoint: Endpoint) async throws -> URLRequest {
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
        
        // 1. Aplica headers globais primeiro (prioridade menor)
        let configHeaders = await NetworkConfig.shared.globalHeaders
        configHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // 2. Aplica headers do endpoint (sobrescrevem os globais)
        endpoint.headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = endpoint.body
        
        let defaultTimeout = await NetworkConfig.shared.defaultTimeout
        request.timeoutInterval = endpoint.timeout ?? defaultTimeout
        
        return request
    }
}
