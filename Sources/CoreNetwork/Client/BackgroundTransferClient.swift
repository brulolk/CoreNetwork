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
    
    private override init() {
        super.init()
        // O identificador único avisa ao iOS: "O app ASMR Wallet (ou outro) quer rodar isso no sistema"
        let config = URLSessionConfiguration.background(withIdentifier: "com.seusapps.backgroundTransfer")
        // Otimiza para economizar bateria se não for urgente
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
            print("✅ Download salvo com sucesso em: \(destinationURL)")
            
            // Aqui você pode disparar um NotificationCenter para avisar as Views do seu app
            // que o arquivo X terminou de baixar e já está disponível!
            NotificationCenter.default.post(name: NSNotification.Name("DownloadCompleted"), object: destinationURL)
            
        } catch {
            print("❌ Erro ao salvar o arquivo de download: \(error)")
        }
    }
}
