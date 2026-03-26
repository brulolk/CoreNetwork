//
//  WebSocketClient.swift
//  CoreNetwork
//
//  Created by Bruno Vinicius on 11/03/26.
//

import Foundation

public actor WebSocketClient {
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected = false
    private var pingTask: Task<Void, Never>?

    public init() {}
    
    /// Abre o "tubo" de comunicação e aguarda confirmação básica de atividade
    public func connect(to urlString: String, pingInterval: TimeInterval = 25.0) async throws {
        guard let url = URL(string: urlString) else { throw NetworkError.invalidURL }
        
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        
        // Timeout de 5 segundos para garantir que a task está ativa
        try await Task.sleep(nanoseconds: 5_000_000_000)
        
        startPinging(interval: pingInterval)
    }
    
    /// Fecha a conexão de forma limpa
    public func disconnect() {
        pingTask?.cancel()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }
    
    /// Envia uma mensagem de texto
    public func send(message: String) async throws {
        guard isConnected, let task = webSocketTask else {
            throw NetworkError.disconnected
        }
        let message = URLSessionWebSocketTask.Message.string(message)
        try await task.send(message)
    }

    /// Envia dados binários (necessário para telemetria ou arquivos)
    public func send(data: Data) async throws {
        guard isConnected, let task = webSocketTask else {
            throw NetworkError.disconnected
        }
        let message = URLSessionWebSocketTask.Message.data(data)
        try await task.send(message)
    }
    
    /// Escuta mensagens de texto via AsyncStream
    public func listen() -> AsyncStream<String> {
        AsyncStream { continuation in
            Task {
                await receiveLoop(continuation: continuation)
            }
        }
    }

    /// Escuta mensagens binárias via AsyncStream
    public func listenData() -> AsyncStream<Data> {
        AsyncStream { continuation in
            Task {
                while isConnected, let task = webSocketTask {
                    do {
                        let message = try await task.receive()
                        if case .data(let data) = message {
                            continuation.yield(data)
                        }
                    } catch {
                        break
                    }
                }
                continuation.finish()
            }
        }
    }
    
    private func receiveLoop(continuation: AsyncStream<String>.Continuation) async {
        guard isConnected, let task = webSocketTask else {
            continuation.finish()
            return
        }
        
        do {
            let message = try await task.receive()
            switch message {
            case .string(let text):
                continuation.yield(text)
            case .data(let data):
                if let text = String(data: data, encoding: .utf8) {
                    continuation.yield(text)
                }
            @unknown default:
                break
            }
            await receiveLoop(continuation: continuation)
        } catch {
            continuation.finish()
        }
    }
    
    private func startPinging(interval: TimeInterval) {
        pingTask?.cancel()
        pingTask = Task {
            while isConnected && !Task.isCancelled {
                let nanoseconds = UInt64(interval * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)
                
                webSocketTask?.sendPing { error in
                    if let error = error {
                        print("Falha no Ping do WebSocket: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
