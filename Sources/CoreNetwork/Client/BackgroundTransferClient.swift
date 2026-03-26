//
//  BackgroundTransferClient.swift
//  CoreNetwork
//
//  Created by Bruno Vinicius on 11/03/26.
//

import Foundation

// Precisa ser uma NSObject para herdar os métodos de Delegate do URLSession
public class BackgroundTransferClient: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    
    public static let shared = BackgroundTransferClient()
    private var session: URLSession!
    
    /// Callback moderno para notificar conclusão de download
    public var onDownloadCompleted: ((URL) -> Void)?
    
    /// Callback moderno para notificar status de upload
    public var onUploadCompleted: ((URLSessionTask, Error?) -> Void)?

    private override init() {
        super.init()
        setupSession(bundleIdentifier: "com.corenetwork.backgroundTransfer")
    }

    public convenience init(bundleIdentifier: String = "com.corenetwork.backgroundTransfer") {
        self.init()
        setupSession(bundleIdentifier: bundleIdentifier)
    }

    private func setupSession(bundleIdentifier: String) {
        let config = URLSessionConfiguration.background(withIdentifier: bundleIdentifier)
        config.isDiscretionary = false
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    /// O arquivo DEVE estar salvo fisicamente no disco do iPhone (fileURL)
    public func upload(fileURL: URL, to endpoint: Endpoint) throws {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        endpoint.headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
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
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        let suggestedFilename = downloadTask.response?.suggestedFilename ?? "downloaded_file"
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let destinationURL = documentsDirectory.appendingPathComponent(suggestedFilename)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) { 
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.moveItem(at: location, to: destinationURL)
            
            // Notifica via closure moderno e via NotificationCenter legado [cite: 59]
            onDownloadCompleted?(destinationURL)
            NotificationCenter.default.post(name: NSNotification.Name("DownloadCompleted"), object: destinationURL)
            
        } catch {
            print("❌ Erro ao salvar o arquivo de download: \(error)")
        }
    }
}
