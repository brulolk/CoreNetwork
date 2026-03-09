//
//  MockURLProtocol.swift
//  CoreNetwork
//
//  Created by Bruno Vinicius on 09/03/26.
//

import Foundation

// Essa classe intercepta qualquer chamada de rede que passe por ela
class MockURLProtocol: URLProtocol {
    
    nonisolated(unsafe) static var mockData: Data?
    nonisolated(unsafe) static var mockResponse: URLResponse?
    nonisolated(unsafe) static var mockError: Error?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true // Dizemos para o iOS: "Deixa que eu cuido de todas as requisições"
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            if let response = MockURLProtocol.mockResponse {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = MockURLProtocol.mockData {
                client?.urlProtocol(self, didLoad: data)
            }
        }
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}
