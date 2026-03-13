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
    
    /// Abre o "tubo" de comunicação
    public func connect(to urlString: String, pingInterval: TimeInterval = 25.0) throws {
        guard let url = URL(string: urlString) else { throw NetworkError.invalidURL }
        
        // Usamos a sessão padrão, mas criamos uma task específica de WebSocket
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        startPinging(interval: pingInterval)
    }
    
    /// Fecha a conexão de forma limpa
    public func disconnect() {
        pingTask?.cancel()
        // .goingAway é o código oficial do protocolo WebSocket para "estou saindo"
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }
    
    /// Envia um dado (geralmente uma String JSON ou Data puro)
    public func send(message: String) async throws {
        guard isConnected, let task = webSocketTask else {
            throw NetworkError.disconnected
        }
        let message = URLSessionWebSocketTask.Message.string(message)
        try await task.send(message)
    }
    
    /// Escuta infinitamente. Retorna um AsyncStream para você consumir no SwiftUI com um loop `for await`
    public func listen() -> AsyncStream<String> {
        AsyncStream { continuation in
            Task {
                await receiveLoop(continuation: continuation)
            }
        }
    }
    
    // Função recursiva que fica esperando a próxima mensagem
    private func receiveLoop(continuation: AsyncStream<String>.Continuation) async {
        guard isConnected, let task = webSocketTask else {
            continuation.finish()
            return
        }
        
        do {
            let message = try await task.receive()
            switch message {
            case .string(let text):
                continuation.yield(text) // Cospe o texto pro AsyncStream
            case .data(let data):
                // Se a telemetria vier em bytes puros, converte pra string (ou envia o Data direto se preferir)
                if let text = String(data: data, encoding: .utf8) {
                    continuation.yield(text)
                }
            @unknown default:
                break
            }
            // Chama ela mesma de novo para escutar a próxima mensagem (Loop)
            await receiveLoop(continuation: continuation)
            
        } catch {
            continuation.finish()
        }
    }
    
    private func startPinging(interval: TimeInterval) {
        pingTask?.cancel()
        pingTask = Task {
            while isConnected && !Task.isCancelled {
                // Converte o TimeInterval (segundos) para nanosegundos de forma segura
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
