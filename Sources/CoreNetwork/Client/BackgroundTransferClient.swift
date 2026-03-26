//
//  BackgroundTransferClient.swift
//  CoreNetwork
//
//  Created by Bruno Vinicius on 11/03/26.
//

import Foundation

// Precisa ser uma NSObject para herdar os métodos de Delegate do URLSession
public class BackgroundTransferClient: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    
    private var session: URLSession!
    private let logger: NetworkLogger
    
    /// Callback moderno para notificar conclusão de download
    public var onDownloadCompleted: ((URL) -> Void)?
    
    /// Callback moderno para notificar status de upload
    public var onUploadCompleted: ((URLSessionTask, Error?) -> Void)?

    // MARK: - Initializers
    
    private override init() {
        self.logger = DefaultNetworkLogger()
        super.init()
        // Init privado vazio para evitar configuração dupla de sessão
    }

    /// Instância compartilhada configurada com o identifier padrão
    public static let shared: BackgroundTransferClient = {
        let client = BackgroundTransferClient()
        client.setupSession(bundleIdentifier: "com.corenetwork.backgroundTransfer")
        return client
    }()

    /// Permite instâncias customizadas com logger injetável
    public init(bundleIdentifier: String = "com.corenetwork.backgroundTransfer",
                logger: NetworkLogger = DefaultNetworkLogger()) {
        self.logger = logger
        super.init()
        setupSession(bundleIdentifier: bundleIdentifier)
    }

    private func setupSession(bundleIdentifier: String) {
        let config = URLSessionConfiguration.background(withIdentifier: bundleIdentifier)
        // Otimiza para economizar bateria se não for urgente
        config.isDiscretionary = false
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Operações de Rede
    
    /// O arquivo DEVE estar salvo fisicamente no disco do iPhone (fileURL)
    public func upload(fileURL: URL, to endpoint: Endpoint) throws {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        endpoint.headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // Cria a task especial de upload baseada num arquivo no disco
        let task = session.uploadTask(with: request, fromFile: fileURL)
        task.resume()
    }
    
    /// Inicia o download de um arquivo grande mesmo com o app em background
    public func download(from endpoint: Endpoint) throws {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        endpoint.headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // Em vez de uploadTask, usamos downloadTask
        let task = session.downloadTask(with: request)
        task.resume()
    }

    // MARK: - URLSessionTaskDelegate
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        onUploadCompleted?(task, error)
    }
}

// MARK: - URLSessionDownloadDelegate
extension BackgroundTransferClient: URLSessionDownloadDelegate {
    
    // Este é o método mágico que o iOS chama quando o download termina
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        // 1. Tenta descobrir o nome original do arquivo que veio da URL
        let suggestedFilename = downloadTask.response?.suggestedFilename ?? "downloaded_file"
        
        // 2. Encontra a pasta segura de Documentos do iPhone do usuário
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        // 3. Monta o destino final (ex: /Documents/fatura.pdf)
        let destinationURL = documentsDirectory.appendingPathComponent(suggestedFilename)
        
        // 4. Move o arquivo da pasta temporária para a pasta segura ANTES que o iOS o delete
        do {
            // Se já existir um arquivo com esse nome, deletamos o velho primeiro
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.moveItem(at: location, to: destinationURL)
            logger.log("✅ Download salvo com sucesso em: \(destinationURL)")
            
            // Notifica via closure moderno e via NotificationCenter
            onDownloadCompleted?(destinationURL)
            NotificationCenter.default.post(name: NSNotification.Name("DownloadCompleted"), object: destinationURL)
            
        } catch {
            logger.log("❌ Erro ao salvar o arquivo de download: \(error)")
        }
    }
}
