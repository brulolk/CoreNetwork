//
//  NetworkLogger.swift
//  CoreNetwork
//
//  Created by Bruno Vinicius on 26/03/26.
//

import Foundation

public protocol NetworkLogger: Sendable {
    func log(_ message: String)
}

public struct DefaultNetworkLogger: NetworkLogger {
    public init() {}
    public func log(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
}

public struct SilentNetworkLogger: NetworkLogger {
    public init() {}
    public func log(_ message: String) {}
}
