//
//  NetworkConfig.swift
//  CoreNetwork
//
//  Created by Bruno Vinicius on 09/03/26.
//

import Foundation

public actor NetworkConfig {
    public static let shared = NetworkConfig()
    
    /// Headers que serão anexados a TODAS as requisições (ex: Authorization, App-Version)
    public var globalHeaders: [String: String] = [:]
    
    /// O timeout padrão para as requisições
    public var defaultTimeout: TimeInterval = 30.0
    
    private init() {}
    
    public func addGlobalHeader(name: String, value: String) {
        globalHeaders[name] = value
    }
    
    public func removeGlobalHeader(name: String) {
        globalHeaders.removeValue(forKey: name)
    }
    
    /// Limpa todos os headers globais de uma só vez (útil no logout)
    public func clearGlobalHeaders() {
        globalHeaders = [:]
    }
}
 
