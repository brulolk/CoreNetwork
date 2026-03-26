
# 📦 CoreNetwork

![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![Platform](https://img.shields.io/badge/iOS-15%2B-blue)
![Platform](https://img.shields.io/badge/macOS-12%2B-lightgrey)
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen)

Camada de networking moderna, leve e tipada para iOS/macOS baseada em **Swift Concurrency (async/await)**.

Projetada para simplificar chamadas HTTP, WebSocket e transferências em background com foco em **clareza, testabilidade e escalabilidade**.

---

## ✨ Features

* Async/Await nativo
* Tipagem forte com `Decodable`
* Retry automático configurável
* Tratamento de erros padronizado
* Headers globais configuráveis
* Timeout global configurável
* Logger configurável
* Upload/Download em background
* WebSocket (text + binary)
* Fácil de testar
* Estrutura baseada em `Endpoint`

---

## ⚙️ Requisitos

* iOS 15+
* macOS 12+
* Swift 6+

---

## 📥 Instalação

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/seu-repo/CoreNetwork.git", from: "1.0.0")
]
```

---

# 🚀 Uso rápido

## Criando um Endpoint

```swift
struct GetUsersEndpoint: Endpoint {
    var baseURL: String = "https://api.example.com"
    var path: String = "/users"
    var method: HTTPMethod = .get
}
```

---

## Fazendo uma requisição

```swift
let client = NetworkClient()

let response = try await client.request(
    endpoint: GetUsersEndpoint(),
    responseType: [User].self
)

print(response.data)
```

---

## 🔁 Retry automático

```swift
let response = try await client.request(
    endpoint: endpoint,
    responseType: Model.self,
    maxRetries: 3
)
```

---

# 🌐 Configuração Global

## Headers Globais

```swift
await NetworkConfig.shared.addGlobalHeader(
    name: "Authorization",
    value: "Bearer token"
)
```

Remover header:

```swift
await NetworkConfig.shared.removeGlobalHeader(name: "Authorization")
```

Limpar todos (ex: logout):

```swift
await NetworkConfig.shared.clearGlobalHeaders()
```

📌 Headers definidos no `Endpoint` possuem prioridade sobre os globais.

---

## Timeout Global

```swift
await NetworkConfig.shared.defaultTimeout = 60
```

Timeout definido no `Endpoint` possui prioridade sobre o global.

---

# 🧠 Tratamento de erros

```swift
do {
    let response = try await client.request(...)
} catch let error as NetworkError {
    switch error {
    case .invalidURL:
        print("Invalid URL")
    case .serverError(let statusCode, _):
        print("Server error: \(statusCode)")
    case .timeout:
        print("Timeout")
    case .noInternet:
        print("No internet")
    case .disconnected:
        print("WebSocket disconnected")
    default:
        break
    }
}
```

---

# 🪵 Logger

Por padrão logs só aparecem em DEBUG.

```swift
let client = NetworkClient(
    logger: DefaultNetworkLogger()
)
```

Desabilitar logs:

```swift
let client = NetworkClient(
    logger: SilentNetworkLogger()
)
```

Criar logger custom:

```swift
struct MyLogger: NetworkLogger {
    func log(_ message: String) {
        print("NETWORK:", message)
    }
}
```

---

# 🔄 Upload / Download em Background

### Usando instância compartilhada

```swift
let client = BackgroundTransferClient.shared
```

### Criando instância custom (recomendado para apps maiores)

```swift
let client = BackgroundTransferClient(
    bundleIdentifier: "com.myapp.background",
    logger: DefaultNetworkLogger()
)
```

### Callbacks

```swift
client.onDownloadCompleted = { url in
    print("Downloaded:", url)
}

client.onUploadCompleted = { task, error in
    print("Upload finished")
}
```

### Upload

```swift
try client.upload(fileURL: fileURL, to: endpoint)
```

### Download

```swift
try client.download(from: endpoint)
```

---

# 🔌 WebSocket

## Conectar

```swift
let socket = WebSocketClient()
try await socket.connect(to: "wss://example.com/socket")
```

---

## Enviar texto

```swift
try await socket.send(message: "hello")
```

---

## Enviar binário

```swift
try await socket.send(data: data)
```

---

## Escutar texto

```swift
for await message in socket.listen() {
    print(message)
}
```

---

## Escutar dados binários

```swift
for await data in socket.listenData() {
    print(data)
}
```

---

## Desconectar

```swift
socket.disconnect()
```

---

# 🧪 Testabilidade

A biblioteca suporta injeção de `URLSession` para mocks.

```swift
let config = URLSessionConfiguration.ephemeral
config.protocolClasses = [MockURLProtocol.self]

let session = URLSession(configuration: config)
let client = NetworkClient(session: session)
```

Exemplo completo disponível nos testes da biblioteca. 

---

# 📌 Boas práticas

* Criar um `Endpoint` por recurso
* Centralizar autenticação no `NetworkConfig`
* Usar logger custom em produção
* Evitar retry excessivo
* Tratar erros explicitamente

---

# 🔒 Contribuição

Esta biblioteca é mantida de forma centralizada.
Sugestões podem ser enviadas via issue.

---

# 📄 Licença

Uso livre para integração em projetos.

---
